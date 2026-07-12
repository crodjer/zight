const std = @import("std");
const Io = std.Io;

fn uptimeSeconds(io: Io) !u64 {
    const file = try Io.Dir.cwd().openFile(
        io, "/proc/uptime", .{ .mode = .read_only }
    );
    defer file.close(io);

    var buf: [64]u8 = undefined;
    var stream_buf: [64]u8 = undefined;
    var reader = file.reader(io, &stream_buf);

    const bytes = try reader.interface.readSliceShort(&buf);
    const data = buf[0..bytes];

    const end = std.mem.indexOfScalar(u8, data, '.')
        orelse return error.InvalidFormat;

    return try std.fmt.parseInt(u64, data[0..end], 10);
}

const TimeUnit = struct {
    seconds: u64,
    suffix: []const u8
};

fn humanTime(seconds: u64, buf: []u8) ![]u8 {
    var rem = seconds;

    var index: usize = 0;
    var unit_count: u4 = 0;

    const units = [_]TimeUnit{
        .{ .seconds = 2592000,  .suffix = "mo" },
        .{ .seconds = 86400,    .suffix = "d" },
        .{ .seconds = 3600,     .suffix = "h" },
        .{ .seconds = 60,       .suffix = "m" },
        .{ .seconds = 1,        .suffix = "s" },
    };

    inline for (units) |unit| {
        if (unit_count >= 2) {
            break;
        }
        const count = rem / unit.seconds;
        rem %= unit.seconds;
        if (count > 0) {
            const p = try std.fmt.bufPrint(buf[index..], "{d}{s}", .{
                count, unit.suffix,
            });
            index += p.len;
            unit_count += 1;
        }
    }

    return buf[0..index];
}

pub fn uptime(io: Io, buf: []u8) ![]u8 {
    const total_seconds = try uptimeSeconds(io);
    return humanTime(total_seconds, buf);
}

test "uptime" {
    const io = std.testing.io;
    var test_buff: [64]u8 = undefined;
    const uptime_string = try uptime(io, &test_buff);

    try std.testing.expect(uptime_string.len > 2);
}

test "humanTime" {
    var test_buff: [64]u8 = undefined;
    try std.testing.expectEqualStrings("45s", try humanTime(45, &test_buff));
    try std.testing.expectEqualStrings(
        "3d4h",
        try humanTime(3 * 86400 + 4 * 3600, &test_buff)
    );
    try std.testing.expectEqualStrings(
        "2h15m",
        try humanTime(2 * 3600 + 15 * 60, &test_buff)
    );
}
