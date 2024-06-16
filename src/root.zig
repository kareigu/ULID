const std = @import("std");

const ULID = extern struct {
    timestamp_high: u32,
    timestamp_low: u16,
    random_high: u16,
    random_mid: u32,
    random_low: u32,

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
};

test "creating new ULID" {
    const ulid = ULID._init(5, 10);
    const expected = ULID{
        .timestamp_high = 0,
        .timestamp_low = 5,
        .random_high = 0,
        .random_mid = 0,
        .random_low = 10,
    };

    try std.testing.expectEqualDeep(expected, ulid);
}
