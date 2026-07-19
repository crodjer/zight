# zight
A tiny linux system snapshot.

zight is a Zig learning project, which gives you some basic system stats i.e.
CPU / Memory usage, thermals and uptime in 1 line.

```shell
$ zight
C:2% M:13% T:50 Up:12d14h
```

## Building
Just run: `zig build` and run `./zig-out/bin/zight`

Build for other architectures:
- ARM 64: `zig build -Dtarget=aarch64-linux`
- X86 64: `zig build -Dtarget=x86_64-linux`

## Testing
There are some simple sanity tests sprinkled through the modules. Run them with:
`zig build test`

## Why?
I am learning [zig](https://ziglang.org/) and this is a project I took on as an
exercise in building something real.
