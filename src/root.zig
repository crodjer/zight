//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;
const uptime = @import("uptime.zig");

pub const VERSION = "0.0.1";

/// Run `zight` and generate the one line system snapshot.
pub fn run(io: Io, writer: *Io.Writer) !void {
    var uptime_buff: [64]u8 = undefined;
    try writer.print("Up:{s}", .{try uptime.uptime(io, &uptime_buff)});
}

test {
    _ = @import("uptime.zig");
}
