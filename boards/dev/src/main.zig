const microzig = @import("microzig");
const usb_if = @import("usb_if.zig");
const rp2xxx = microzig.hal;
const uart = rp2xxx.uart.instance.num(0);
const time = rp2xxx.time;
const usb_dev = rp2xxx.usb.Usb(.{});

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

fn ledHandler(pressed: bool) void {
    const value = @intFromBool(pressed);
    pins.LED.put(value);
}
const LED: zkf.Keycode = .Custom(ledHandler);

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

fn delay() void {
    time.sleep_us(50);
}

fn sendHid(report: zkf.hid.Report) void {
    const array: [7]u8 = @bitCast(report);
    usb_if.send_keyboard_report(usb_dev, &array);
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
        .scan = zkf.scan.matrix(Pin, rows, cols, layout, .row_col, delay),
        .send = sendHid,
    });

    logger.info("started", .{});
    pins.LED.toggle();

    while (true) {
        // process pending USB housekeeping
        try usb_dev.task(false);

        const changes = keyboard.scan();
        if (changes.count() == 0) {
            continue;
        }

        var iterator = changes.iterator(.{});

        logger.debug("changes", .{});
        while (iterator.next()) |index| {
            logger.debug("  {}", .{index});
        }

        keyboard.processChanges(changes);
    }
}

fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = comptime comptimePrint("{s} ({s}): ", .{
        level.asText(),
        switch (scope) {
            .default => "<unknown>",
            else => @tagName(scope),
        },
    });

    const writer = uart.writer();
    writer.print(prefix ++ format ++ "\r\n", args) catch {};
}

pub const microzig_options: microzig.Options = .{
    .log_level = .debug,
    .logFn = logFn,
};

const comptimePrint = std.fmt.comptimePrint;
const logger = std.log.scoped(.dev_board);

const std = @import("std");

const zkf = @import("zkf");
const us = zkf.languages.english_us;
