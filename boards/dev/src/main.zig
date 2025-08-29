const LED: zkf.Keycode = .Custom(struct {
    fn handler(pressed: bool) void {
        const value = @intFromBool(pressed);
        pins.LED.put(value);
    }
}.handler);

// zig fmt: off
const layout: zkf.Layout = &.{
    &.{  0,  1,  2,  3 },
    &.{  4,  5,  6,  7 },
    &.{  8,  9, 10, 11 },
    &.{ 12, 13, 14, 15 },
};
// zig fmt: on

pub fn main() !void {
    // has to be very first to prevent crash if we try and log over UART before it's been setup
    uart.apply(.{
        .baud_rate = 115_200,
        .clock_config = rp2xxx.clock_config,
    });

    pin.config.apply();

    // configure USB
    var keyboard_driver: usb.hid.HidClassDriver = .{
        .ep_in = usb_cfg.endpoint_address,
        .report_descriptor = &usb_cfg.report_descriptor,
    };
    var drivers: [1]usb.types.UsbClassDriver = .{
        keyboard_driver.driver(),
    };
    var keyboard_config: usb.DeviceConfiguration = .{
        .device_descriptor = &.{
            .descriptor_type = .Device,
            .bcd_usb = 0x0200,
            .device_class = 0,
            .device_subclass = 0,
            .device_protocol = 0,
            .max_packet_size0 = 64,
            .vendor = 0xFAFA,
            .product = 0x00F0,
            .bcd_device = 0x0100,
            // Those are indices to the descriptor strings
            .manufacturer_s = 0,
            .product_s = 1,
            .serial_s = 2,
            .num_configurations = 1,
        },
        .config_descriptor = &usb_cfg.descriptor,
        // length || string descriptor (0x03) || Engl (0x0409)
        .lang_descriptor = "\x04\x03\x09\x04",
        .descriptor_strings = &.{
            &usb.utils.utf8_to_utf16_le("elpekenin"),
            &usb.utils.utf8_to_utf16_le("dev"),
            &usb.utils.utf8_to_utf16_le("deadbeef"),
        },
        .drivers = &drivers,
    };

    usb_dev.init_clk();
    usb_dev.init_device(&keyboard_config) catch @panic("couldn't init USB");
    usb_dev.callbacks.endpoint_open(usb_cfg.endpoint_address, 512, .Interrupt);

    // mainloop
    logger.info("configured everything", .{});

    var keyboard = zkf.Keyboard.new(.{
        .debounce = .fromMillis(5),
        .keymap = &.{
            // zig fmt: off
            &.{
                us.A, us.B, us.C, us.D,
                us.E, us.F, us.G, us.H,
                us.I, us.J, us.K, us.L,
                us.M, us.N, .MO(1), LED,
            },
            &.{
                us.A, us.B, us.C, us.D,
                us.E, us.F, us.G, us.H,
                us.I, us.J, us.K, us.L,
                us.M, us.N, .___, LED,
            }
            // zig fmt: on
        },
        .portability = .{
            .getTime = portability.getTime,
            .sendHid = portability.sendHid,
            .scanKeys = zkf.scan.matrix(pin.T, rows, cols, layout, .{
                .diode_direction = .row_col,
                .output_delay = .fromMillis(2),
            }),
        },
    });

    while (true) {
        try usb_dev.task(false); // pending USB housekeeping

        const changes = keyboard.scan();
        keyboard.processChanges(changes);
    }
}

const portability = struct {
    fn getTime() zkf.Time {
        return .fromMillis(
            time.get_time_since_boot().to_us() / 1000,
        );
    }

    fn sendHid(report: zkf.hid.Report) void {
        const array: [7]u8 = @bitCast(report);
        usb_dev.callbacks.usb_start_tx(usb_cfg.endpoint_address, &array);
    }
};

const pin = struct {
    const T = @TypeOf(pins.R1);

    const config: rp2xxx.pins.GlobalConfiguration = .{
        .GPIO0 = .{ .name = "C4", .direction = .in },
        .GPIO1 = .{ .name = "C3", .direction = .in },
        .GPIO2 = .{ .name = "C2", .direction = .in },
        .GPIO3 = .{ .name = "C1", .direction = .in },
        //
        .GPIO4 = .{ .name = "R1", .direction = .out },
        .GPIO5 = .{ .name = "R2", .direction = .out },
        .GPIO6 = .{ .name = "R3", .direction = .out },
        .GPIO7 = .{ .name = "R4", .direction = .out },
        //
        .GPIO12 = .{ .name = "TX", .function = .UART0_TX },
        //
        .GPIO25 = .{ .name = "LED", .direction = .out },
    };
};
const pins = pin.config.pins();
const rows: []const pin.T = &.{ pins.R1, pins.R2, pins.R3, pins.R4 };
const cols: []const pin.T = &.{ pins.C1, pins.C2, pins.C3, pins.C4 };

//
// globals
//
const logger = std.log.scoped(.dev_board);
const usb_dev = usb.Usb(.{});

//
// imports
//
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const uart = rp2xxx.uart.instance.num(0);
const usb = rp2xxx.usb;

const zkf = @import("zkf");
const us = zkf.languages.english_us;

const std = @import("std");
const microzig = @import("microzig");
const usb_cfg = @import("usb_cfg.zig");

const logging = @import("logging.zig");
pub const microzig_options: microzig.Options = .{
    .log_level = .debug,
    .logFn = logging.function,
};
