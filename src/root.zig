const std = @import("std");

const ULID = extern struct {
    timestamp_high: u32,
    timestamp_low: u16,
    random_high: u16,
    random_mid: u32,
    random_low: u32,

    pub const Error = error{
        InvalidLength,
        InvalidSymbol,
        ValueTooHigh,
    };

    // zig fmt: off
    const BASE32 = [_]u8{ 
        '0', '1', '2', '3', '4', '5', '6',
        '7', '8', '9', 'A', 'B', 'C', 'D',
        'E', 'F', 'G', 'H', 'J', 'K', 'M',
        'N', 'P', 'Q', 'R', 'S', 'T', 'V',
        'W', 'X', 'Y', 'Z'
    };
    // zig fmt: on
    const STR_LENGTH = 26;

    pub fn init() ULID {
        const timestamp: u48 = @intCast(std.time.milliTimestamp());
        const random = std.crypto.random.int(u80);
        return _init(timestamp, random);
    }

    fn _init(timestamp: u48, random: u80) ULID {
        return .{
            .timestamp_high = @truncate(timestamp >> 16),
            .timestamp_low = @truncate(timestamp),
            .random_high = @truncate(random >> 64),
            .random_mid = @truncate(random >> 32),
            .random_low = @truncate(random),
        };
    }

    fn parse_slice(comptime T: type, slice: []const u8) Error!T {
        var out: T = 0;
        const size = slice.len - 1;
        for (0..slice.len) |i| {
            const c = slice[size - i];
            const val: T = blk: for (BASE32, 0..) |b, j| {
                if (b == c) {
                    break :blk @intCast(j);
                }
            } else {
                return error.InvalidSymbol;
            };
            out += val * (std.math.powi(T, @intCast(BASE32.len), @intCast(size - i)) catch return error.ValueTooHigh);
        }

        return out;
    }

    pub fn parse(string: []const u8) Error!ULID {
        if (string.len != STR_LENGTH) {
            return error.InvalidLength;
        }

        const timestamp = try parse_slice(u48, string[0..10]);
        const random = try parse_slice(u80, string[10..26]);

        return _init(timestamp, random);
    }

    fn format_to_base32(n: anytype, buf: []u8) void {
        const n_type = @TypeOf(n);
        const n_type_info = @typeInfo(n_type);
        if (n_type_info != .Int or n_type_info.Int.signedness == .signed) {
            @compileError("n needs to be an unsigned integer");
        }

        var left = n;
        var char: usize = 0;

        while (char < buf.len) : (char += 1) {
            const mod = left % BASE32.len;
            buf[char] = BASE32[@intCast(mod)];
            left = (left - @as(n_type, @intCast(mod))) / @as(n_type, @intCast(BASE32.len));
        }
    }

    fn str_to_buffer(self: *const ULID, buf: []u8) void {
        const timestamp: u48 = @as(u48, @intCast(self.timestamp_high)) << 16 | @as(u48, @intCast(self.timestamp_low));
        format_to_base32(timestamp, buf[0..10]);

        const random: u80 = @as(u80, @intCast(self.random_high)) << 64 | @as(u80, @intCast(self.random_mid)) << 32 | @as(u80, @intCast(self.random_low));
        format_to_base32(random, buf[10..buf.len]);
    }

    pub fn str(self: *const ULID) [STR_LENGTH]u8 {
        var buf = [_]u8{0} ** STR_LENGTH;
        self.str_to_buffer(&buf);
        return buf;
    }
};

export fn ULID_create() ULID {
    return ULID.init();
}

export fn ULID_str(ulid: *const ULID, buf: [*]c_char, len: c_ulonglong) void {
    ULID.str_to_buffer(ulid, @ptrCast(buf[0..len]));
}

export fn ULID_parse(ulid: *ULID, str: [*]const c_char, len: c_ulonglong) c_int {
    const u = ULID.parse(@ptrCast(str[0..len])) catch |e| {
        return @intFromError(e);
    };

    ulid.* = u;
    return 0;
}

test "creating new ULID" {
    const ulid = ULID._init(1718578280463, 492354077685367681596350);
    const expected = ULID{
        .timestamp_high = 26223423,
        .timestamp_low = 30735,
        .random_high = 26690,
        .random_mid = 2439682851,
        .random_low = 2091924414,
    };

    try std.testing.expectEqualDeep(expected, ulid);
}

test "string formatting" {
    const ulid = ULID._init(1718578280463, 492354077685367681596350);
    const str = ulid.str();
    try std.testing.expectEqualStrings("F0YYKH0J10YXE0BYD4VMT2911D", &str);
}

test "parse from string" {
    const str = "F0YYKH0J10YXE0BYD4VMT2911D";
    const ulid = try ULID.parse(str);
    const expected = ULID{
        .timestamp_high = 26223423,
        .timestamp_low = 30735,
        .random_high = 26690,
        .random_mid = 2439682851,
        .random_low = 2091924414,
    };
    try std.testing.expectEqualDeep(expected, ulid);
}
