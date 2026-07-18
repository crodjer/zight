//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;
const uptime = @import("uptime.zig");
const memory = @import("memory.zig");

pub const VERSION = "0.0.1";

/// Run `zight` and generate the one line system snapshot.
pub fn run(io: Io, writer: *Io.Writer) !void {
    var uptime_buff: [64]u8 = undefined;
    var memory_buff: [8]u8 = undefined;

    try writer.print("M:{s} Up:{s}\n", .{
        try memory.memory(io, &memory_buff),
        try uptime.uptime(io, &uptime_buff)
    });
}

test {
    _ = @import("uptime.zig");
    _ = @import("memory.zig");
}
