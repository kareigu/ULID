const std = @import("std");

const ULID = extern struct {
    timestamp_high: u32,
    timestamp_low: u16,
    random_high: u16,
    random_mid: u32,
    random_low: u32,

    // zig fmt: off
    const BASE32 = [_]u8{ 
        '0', '1', '2', '3', '4', '5', '6',
        '7', '8', '9', 'A', 'B', 'C', 'D',
        'E', 'F', 'G', 'H', 'J', 'K', 'M',
        'N', 'P', 'Q', 'R', 'S', 'T', 'V',
        'W', 'X', 'Y', 'Z'
    };
    // zig fmt: on

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

    pub fn str(self: *const ULID) [26]u8 {
        var buf = [_]u8{0} ** 26;
        const timestamp: u48 = @as(u48, @intCast(self.timestamp_high)) << 16 | @as(u48, @intCast(self.timestamp_low));
        format_to_base32(timestamp, buf[0..10]);

        const random: u80 = @as(u80, @intCast(self.random_high)) << 64 | @as(u80, @intCast(self.random_mid)) << 32 | @as(u80, @intCast(self.random_low));
        format_to_base32(random, buf[10..26]);

        return buf;
    }
};

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
