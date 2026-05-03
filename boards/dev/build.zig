const std = @import("std");

const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const zkf = b.dependency("zkf", .{
        .max_keys = 16,
    });

    const firmware = mb.add_firmware(.{
        .name = "dev",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = .Debug,
        .root_source_file = b.path("src/keymap.zig"),
    });

    firmware.add_app_import("zkf", zkf.module("zkf"), .{
        .depend_on_microzig = true,
    });

    mb.install_firmware(firmware, .{});

    const options = b.addOptions();
    firmware.add_app_import(
        "options",
        options.createModule(),
        .{ .depend_on_microzig = false },
    );
}
