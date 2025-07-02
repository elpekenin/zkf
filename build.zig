pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zkf = b.addModule("zkf", .{
        .root_source_file = b.path("src/zkf.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_suite = b.addTest(.{
        .root_module = zkf,
        .test_runner = .{ .path = b.path("tools/test_runner.zig"), .mode = .simple },
    });
    const run_tests = b.addRunArtifact(test_suite);

    const test_step = b.step("test", "run unit tests");
    test_step.dependOn(&run_tests.step);
}

const std = @import("std");
