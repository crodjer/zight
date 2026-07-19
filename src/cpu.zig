const std = @import("std");
const Io = std.Io;

const CpuStat = struct {
    user: u64,
    nice: u64,
    system: u64,
    idle: u64,
    iowait: u64,
    irq: u64,
    softirq: u64,
    steal: u64,
    guest: u64,
    guest_nice: u64,

    fn idleTime (stat: CpuStat) u64 {
        return stat.idle + stat.iowait;
    }

    fn totalTime(stat: CpuStat) u64 {
        return stat.user + stat.nice + stat.system + stat.idle + stat.iowait +
            stat.irq + stat.softirq + stat.steal;
    }
};

fn cpuStat(io: Io) !CpuStat {
     const file = try Io.Dir.cwd().openFile(
         io, "/proc/stat", .{ .mode = .read_only }
     );
     defer file.close(io);

     var buf: [1024]u8 = undefined;
     var reader = file.reader(io, &buf);

     const line = (try reader.interface.takeDelimiter('\n'))
         orelse return error.InvalidFormat;
     var it = std.mem.tokenizeAny(u8, line, " \t");

    const field_names = @typeInfo(CpuStat).@"struct".field_names;
    const field_types = @typeInfo(CpuStat).@"struct".field_types;
    var cpu_stat: CpuStat = undefined;
    _ = it.next() orelse return error.InvalidFormat;

    inline for (field_names, field_types) |field_name, field_type| {
        const token = it.next() orelse return error.InvalidFormat;
        @field(cpu_stat, field_name) = try std.fmt.parseInt(
            field_type,
            token,
            10,
        );
    }

    return cpu_stat;
}

fn cpuUsage(io: Io) !u8 {
    const stat_1 = try cpuStat(io);
    try io.sleep(std.Io.Duration.fromMilliseconds(100), .awake);
    const stat_2 = try cpuStat(io);
    const diff_total = stat_2.totalTime() - stat_1.totalTime();
    const diff_idle = stat_2.idleTime() - stat_1.idleTime();

    return @intCast(((diff_total - diff_idle) * 100) / diff_total);
}

pub fn usage(io: Io, buf: []u8) ![]u8 {
    return try std.fmt.bufPrint(buf, "{d}%", .{ try cpuUsage(io) });
}

test "cpuStat" {
    const cpu_stat = try cpuStat(std.testing.io);
    try std.testing.expect(cpu_stat.totalTime() > 0);
    try std.testing.expect(cpu_stat.idleTime() > 0);
}

test "cpuUsage" {
    const cpu_usage = try cpuUsage(std.testing.io);
    try std.testing.expect(cpu_usage >= 0 and cpu_usage <= 100);
}
