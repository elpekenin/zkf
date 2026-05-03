const std = @import("std");

const microzig = @import("microzig");
const option = @import("zkf").option;

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const firmware = mb.add_firmware(.{
        .name = "dev",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = .Debug,
        .root_source_file = b.path("src/keymap.zig"),
    });

    const zkf = b.dependency("zkf", .{
        .max_keys = 16,
    });
    firmware.app_mod.addImport("zkf", zkf.module("zkf"));

    mb.install_firmware(firmware, .{});

    const options = b.addOptions();
    firmware.add_app_import(
        "options",
        options.createModule(),
        .{ .depend_on_microzig = false },
    );

    option(bool, options, .{
        .name = "uart_logging",
        .description = "log over UART",
        .default = true,
    });

    option(u16, options, .{
        .name = "vendor_id",
        .description = "vendor ID",
        .default = 0xBEEF,
    });
    option([]const u8, options, .{
        .name = "vendor",
        .description = "vendor name",
        .default = "zkf project",
    });

    option(u16, options, .{
        .name = "product_id",
        .description = "product ID",
        .default = 0x0001,
    });
    option([]const u8, options, .{
        .name = "product",
        .description = "product name",
        .default = "zkf keyboard",
    });
}
