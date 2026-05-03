const std = @import("std");

pub fn option(
    comptime T: type,
    options: *std.Build.Step.Options,
    config: struct {
        name: []const u8,
        description: ?[]const u8 = null,
        default: T,
    },
) void {
    const b = options.step.owner;

    const value = b.option(
        T,
        config.name,
        config.description orelse config.name,
    ) orelse config.default;

    options.addOption(T, config.name, value);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zkf = b.addModule("zkf", .{
        .root_source_file = b.path("src/zkf.zig"),
        .target = target,
        .optimize = optimize,
    });

    zkf.addImport("zkf", zkf);

    const options = b.addOptions();
    zkf.addOptions("options", options);

    option(u32, options, .{
        .name = "tap_delay_ms",
        .default = 10,
    });

    const max_layers = b.option(u16, "max_layers", "maximum supported layers") orelse 8;
    options.addOption(usize, "max_layers", max_layers);
    if (!std.math.isPowerOfTwo(max_layers)) {
        @panic("max_layers must be a power of 2");
    }

    const max_keys = b.option(u16, "max_keys", "maximum supported keys") orelse 64;
    options.addOption(usize, "max_keys", max_keys);
    if (!std.math.isPowerOfTwo(max_keys)) {
        @panic("max_layers must be a power of 2");
    }

    // Test step
    const test_step = b.step("test", "run tests");
    const test_exe = b.addTest(.{
        .root_module = zkf,
    });
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}
