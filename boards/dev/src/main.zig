const pins_config: rp2xxx.pins.GlobalConfiguration = .{
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
const pins = pins_config.pins();

const LED: zkf.Keycode = .Custom(struct {
    fn handler(pressed: bool) void {
        const value = @intFromBool(pressed);
        pins.LED.put(value);
    }
}.handler);

const Pin = @TypeOf(pins.R1);
const rows: []const Pin = &.{ pins.R1, pins.R2, pins.R3, pins.R4 };
const cols: []const Pin = &.{ pins.C1, pins.C2, pins.C3, pins.C4 };

// zig fmt: off
const layout: zkf.Layout = &.{
    &.{  0,  1,  2,  3 },
    &.{  4,  5,  6,  7 },
    &.{  8,  9, 10, 11 },
    &.{ 12, 13, 14, 15 },
};
// zig fmt: on

fn getTime() zkf.Time {
    return .fromMillis(
        time.get_time_since_boot().to_us() / 1000,
    );
}

fn delay() void {
    time.sleep_us(50);
}

fn sendHid(report: zkf.hid.Report) void {
    const array: [7]u8 = @bitCast(report);
    usb_if.sendKeyboardReport(usb_dev, &array);
}

pub fn main() !void {
    // has to be very first to prevent crash if we try and log over UART before it is setup
    uart.apply(.{
        .baud_rate = 115_200,
        .clock_config = rp2xxx.clock_config,
    });
    pins_config.apply();
    usb_if.init(usb_dev);

    var keyboard = zkf.Keyboard.new(.{
        .debounce = .fromMillis(5),
        .keymap = &.{
            // zig fmt: off
            &.{
                us.A, us.B, us.C, us.D,
                us.E, us.F, us.G, us.H,
                us.I, us.J, us.K, us.L,
                us.M, us.N, us.O, LED,
            },
            // zig fmt: on
        },
        .portability = .{
            .getTime = getTime,
            .sendHid = sendHid,
            .scanKeys = zkf.scan.matrix(Pin, rows, cols, layout, .{
                .diode_direction = .row_col,
                .outputDelay = .fromMillis(2),
            }),
        },
    });

    logger.info("started", .{});

    while (true) {
        // process pending USB housekeeping
        try usb_dev.task(false);

        const changes = keyboard.scan();
        keyboard.processChanges(changes);
    }
}

const logger = std.log.scoped(.dev_board);
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const uart = rp2xxx.uart.instance.num(0);
const us = zkf.languages.english_us;
const usb_dev = rp2xxx.usb.Usb(.{});

const std = @import("std");
const microzig = @import("microzig");
const usb_if = @import("usb_if.zig");
const zkf = @import("zkf");
pub const microzig_options = @import("options.zig").microzig_options;
