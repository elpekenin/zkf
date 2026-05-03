const microzig = @import("microzig");
const zkf = @import("zkf");

const usb = microzig.core.usb;
const Device = microzig.hal.usb.Polled(.{});

const Keyboard = usb.drivers.hid.InterruptDriver(.{
    .subclass = .Boot,
    .protocol = .Boot,
    .report_descriptor = &.{
        .{ .global_usage_page = .generic_desktop },
        .local_usage_enum(.{ .generic_desktop = .keyboard }),
        .{ .main_collection = .Application },
        // Input: modifier key bitmap
        .{ .data = .{
            .usage = .{ .global_page = .keyboard },
            .usage_range = .{ 0xE0, 0xE7 },
            .count = 8,
            .Child = bool,
            .dir = .In,
            .type = .dynamic,
        } },
        // Input: up to 6 pressed key codes
        .{ .data = .{
            .usage = .{ .global_page = .keyboard },
            .usage_range = .{ 0x00, 0xff },
            .count = 6,
            .Child = u8,
            .dir = .In,
            .type = .selector,
        } },
        // Output: indicator LEDs
        .{
            .data = .{
                .usage = .{ .global_page = .led },
                .usage_range = .{ 1, 5 },
                .count = 5,
                .Child = bool,
                .dir = .Out,
                .type = .dynamic,
            },
        },
        // Padding
        .{ .data_static = .{ .Out, u3 } },
        // End
        .main_collection_end,
    },
    .InReport = zkf.hid.KbToHost,
    .OutReport = zkf.hid.HostToKb,
});

const Controller = usb.DeviceController(.{
    .bcd_usb = .v2_00,
    .device_triple = .unspecified,
    .vendor = .{
        .id = zkf.options.vendor_id,
        .str = zkf.options.vendor,
    },
    .product = .{
        .id = zkf.options.product_id,
        .str = zkf.options.product,
    },
    .bcd_device = .v1_00,
    .serial = "00000001",
    .max_supported_packet_size = Device.max_supported_packet_size,
    .configurations = &.{.{
        .attributes = .{ .self_powered = false },
        .max_current_ma = 500,
        .Drivers = struct {
            keyboard: Keyboard,
        },
    }},
}, .{.{
    .keyboard = .{ .itf_string = "Keyboard", .poll_interval = 1 },
}});

pub var controller: Controller = .init;
pub var device: Device = undefined;

pub fn init() void {
    device = .init();
}

pub fn poll() void {
    device.poll(&controller);
}

pub fn sendHid(report: *const zkf.hid.KbToHost) void {
    if (controller.drivers()) |drivers| {
        _ = drivers.keyboard.send_report(report);
    }
}
