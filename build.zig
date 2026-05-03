const std = @import("std");

fn option(
    comptime T: type,
    options: *std.Build.Step.Options,
    config: struct {
        name: []const u8,
        description: ?[]const u8 = null,
        default: T,
    },
) T {
    const b = options.step.owner;

    const value = b.option(
        T,
        config.name,
        config.description orelse config.name,
    ) orelse config.default;

    options.addOption(T, config.name, value);

    return value;
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

    //tests
    const test_step = b.step("test", "run tests");
    const test_exe = b.addTest(.{
        .root_module = zkf,
    });
    test_step.dependOn(&b.addRunArtifact(test_exe).step);

    // custom options
    const options = b.addOptions();
    zkf.addOptions("options", options);

    _ = option(u32, options, .{
        .name = "tap_delay_ms",
        .default = 10,
    });

    const max_layers = option(u16, options, .{
        .name = "max_layers",
        .default = 8,
    });
    if (!std.math.isPowerOfTwo(max_layers)) {
        @panic("max_layers must be a power of 2");
    }

    const max_keys = option(u16, options, .{
        .name = "max_keys",
        .default = 64,
    });
    if (!std.math.isPowerOfTwo(max_keys)) {
        @panic("max_layers must be a power of 2");
    }

    _ = option(u16, options, .{
        .name = "vendor_id",
        .description = "vendor ID",
        .default = 0xBEEF,
    });
    _ = option([]const u8, options, .{
        .name = "vendor",
        .description = "vendor name",
        .default = "zkf project",
    });

    _ = option(u16, options, .{
        .name = "product_id",
        .description = "product ID",
        .default = 0x0001,
    });
    _ = option([]const u8, options, .{
        .name = "product",
        .description = "product name",
        .default = "zkf keyboard",
    });
}
