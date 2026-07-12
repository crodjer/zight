const std = @import("std");
const Io = std.Io;

const MemoryInfo = struct {
    total: u64,
    available: u64,

    fn usage(mem_info: MemoryInfo) f32 {
        const used: f32 = @floatFromInt(mem_info.total - mem_info.available);
        return 100 * used / @as(f32, @floatFromInt(mem_info.total));
    }
};

fn memoryInfo(io: Io) !MemoryInfo {
    const file = try Io.Dir.cwd().openFile(
        io, "/proc/meminfo", .{ .mode = .read_only }
    );
    defer file.close(io);

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &file_buffer);

    var mem_info = MemoryInfo{.total = 0, .available = 0};

    while(try reader.interface.takeDelimiter('\n')) |line| {
        var it = std.mem.tokenizeAny(u8, line, " \t:");
        const label = it.next() orelse continue;

        if (std.mem.eql(u8, label, "MemTotal")) {
            const val = it.next() orelse continue;
            mem_info.total = try std.fmt.parseInt(u64, val, 10);
        } else if (std.mem.eql(u8, label, "MemAvailable")) {
            const val = it.next() orelse continue;
            mem_info.available = try std.fmt.parseInt(u64, val, 10);
        }
    }

    return mem_info;
}


pub fn memory(io: Io, buf: []u8) ![]u8 {
    const info = try memoryInfo(io);
    return try std.fmt.bufPrint(buf, "{d:0.2}%", .{ info.usage(), });
}

test "memoryUsage" {
    const mem_info = try memoryInfo(std.testing.io);
    const usage = mem_info.usage();

    try std.testing.expect(usage > 0);
}
