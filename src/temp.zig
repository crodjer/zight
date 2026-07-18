const std = @import("std");
const Io = std.Io;

fn maxTemp(io: Io) !?u32 {
    const thermalDir = try Io.Dir.cwd().openDir(
        io, "/sys/class/thermal", .{.iterate = true}
    );
    defer thermalDir.close(io);

    var iter = thermalDir.iterate();
    var path_buf: [64]u8 = undefined;
    var max_temp: ?u32 = null;

    while (try iter.next(io)) |entry| {
        if (std.mem.startsWith(u8, entry.name, "thermal_zone")) {
            const path = try std.fmt.bufPrint(
                &path_buf, "{s}/temp", .{entry.name}
            );
            const file = try thermalDir.openFile(io, path, .{});
            defer file.close(io);
            var stream_buf: [64]u8 = undefined;
            var reader = file.reader(io, &stream_buf);

            var buf: [64]u8 = undefined;
            const bytes = try reader.interface.readSliceShort(&buf);
            const temp_str = std.mem.trim(u8, buf[0..bytes], " \t\r\n");
            const t = try std.fmt.parseInt(u32, temp_str, 10) / 1000;

            if (t > max_temp orelse 0) {
                max_temp = t;
            }
        }
    }

    return max_temp;
}

pub fn temp(io: Io, buf:[]u8) ![]u8 {
    if (try maxTemp(io)) |t| {
        return try std.fmt.bufPrint(buf, "{d}", .{ t });
    } else {
        return try std.fmt.bufPrint(buf, "N/A", .{});
    }
}

test "temp" {
    const max_temp = try maxTemp(std.testing.io);
    var temp_buf: [8]u8 = undefined;
    const temp_str: []u8 = try temp(std.testing.io, &temp_buf);
    if (max_temp) |t| {
        try std.testing.expect(t > 0);
    } else {
        try std.testing.expectEqualStrings("N/A", temp_str);
    }
}
