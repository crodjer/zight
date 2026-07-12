const std = @import("std");
const Io = std.Io;

const zight = @import("zight");

const Command = enum(u2) {
    help,
    version,
    run
};

fn parseArgs(args: []const []const u8) error{InvalidArguments}!Command {
    var command = Command.run;
    const eql = std.mem.eql;

    for (args, 0..) |arg, idx| {
        if (idx == 0) {
            continue;
        }
        if (eql(u8, arg, "-h") or eql(u8, arg, "--help")) {
            command = .help;
        } else if (eql(u8, arg, "-v") or eql(u8, arg, "--version")) {
            command = .version;
        } else {
            return error.InvalidArguments;
        }
    }

    return command;
}

const HELP =
    \\zight: quick system health check
    \\
    \\Options:
    \\ -h, --help        Print this help.
    \\ -v, --version     Get tool version.
    \\
;

fn printHelp(writer: *std.Io.Writer) !void {
    try writer.writeAll(HELP);
}

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    const command = try parseArgs(args);

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    switch (command) {
        .help => { try printHelp(stdout_writer); },
        .version => { try stdout_writer.writeAll(zight.VERSION ++ "\n"); },
        .run => { try zight.run(io, stdout_writer); }
    }

    try stdout_writer.flush(); // Don't forget to flush!
}


test "parseArgs" {
    try std.testing.expectEqual(.run, try parseArgs(&.{ "zight" }));
    try std.testing.expectEqual(.help, try parseArgs(&.{ "zight", "--help" }));
    try std.testing.expectEqual(.help, try parseArgs(&.{ "zight", "-h" }));
    try std.testing.expectEqual(.version, try parseArgs(&.{ "zight", "-v" }));
    try std.testing.expectEqual(
        .version,
        try parseArgs(&.{ "zight", "--version" })
    );
}

test "printHelp" {
    var buf: [512]u8 = undefined;
    var fixed_writer = std.Io.Writer.fixed(&buf);
    try printHelp(&fixed_writer);
    try std.testing.expectEqualStrings(HELP, fixed_writer.buffered());
}
