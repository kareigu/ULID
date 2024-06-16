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
