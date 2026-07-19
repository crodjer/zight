//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;
const uptime = @import("uptime.zig");
const memory = @import("memory.zig");
const temp = @import("temp.zig");
const cpu = @import("cpu.zig");

pub const VERSION = "0.0.1";

/// Run `zight` and generate the one line system snapshot.
pub fn run(io: Io, writer: *Io.Writer) !void {
    var uptime_buf: [64]u8 = undefined;
    var temp_buf: [64]u8 = undefined;
    var memory_buf: [8]u8 = undefined;
    var cpu_buf: [8]u8 = undefined;

    try writer.print("C:{s} M:{s} T:{s} Up:{s}\n", .{
        try cpu.usage(io, &cpu_buf),
        try memory.memory(io, &memory_buf),
        try temp.temp(io, &temp_buf),
        try uptime.uptime(io, &uptime_buf)
    });
}

test {
    _ = @import("uptime.zig");
    _ = @import("memory.zig");
    _ = @import("temp.zig");
    _ = @import("cpu.zig");
}
