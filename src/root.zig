//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const VERSION = "0.0.1";

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

fn humanTime(seconds: u64, buf: []u8) ![]u8 {
    var rem = seconds;
    const mo = rem / 2592000;   rem %= 2592000;
    const d = rem / 86400;      rem %= 86400;
    const h = rem / 3600;       rem %= 3600;
    const m = rem / 60;         rem %= 60;
    const s = rem;

    var index: usize = 0;
    const units = .{
        .{ mo, "mo" },
        .{ d, "d" },
        .{ h, "h" },
        .{ m, "m" },
        .{ s, "s" },
    };

    inline for (units) |unit| {
        if (unit[0] > 0) {
            const p = try std.fmt.bufPrint(buf[index..], "{d}{s}", .{
                unit[0], unit[1],
            });
            index += p.len;
        }
    }

    return buf[0..index];
}

fn uptime(io: Io, buf: []u8) ![]u8 {
    const total_seconds = try uptimeSeconds(io);
    return humanTime(total_seconds, buf);
}

/// Run `zight` and generate the one line system snapshot.
pub fn run(io: Io, writer: *Io.Writer) !void {
    var uptime_buff: [64]u8 = undefined;
    try writer.print("Up:{s}", .{try uptime(io, &uptime_buff)});
}

test "humanTime" {
    var test_buff: [64]u8 = undefined;
    try std.testing.expectEqualStrings("45s", try humanTime(45, &test_buff));
    try std.testing.expectEqualStrings("3d4h", try humanTime(3 * 86400 + 4 * 3600, &test_buff));
    try std.testing.expectEqualStrings("2h15m", try humanTime(2 * 3600 + 15 * 60, &test_buff));
}
