const std = @import("std");

const microzig = @import("microzig");
const usb_if = @import("usb_if.zig");
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const usb = rp2xxx.usb;
const usb_dev = rp2xxx.usb.Usb(.{});

// Compile-time pin configuration
const leds_config: rp2xxx.pins.GlobalConfiguration = .{
    .GPIO16 = .{ .name = "red", .direction = .out },
    .GPIO17 = .{ .name = "green", .direction = .out },
    .GPIO18 = .{ .name = "blue", .direction = .out },
};
const leds = leds_config.pins();

const matrix_config: rp2xxx.pins.GlobalConfiguration = .{
    .GPIO0 = .{ .name = "row3", .direction = .out },
    .GPIO1 = .{ .name = "row2", .direction = .out },
    .GPIO2 = .{ .name = "row1", .direction = .out },
    .GPIO3 = .{ .name = "row0", .direction = .out },
    //
    .GPIO4 = .{ .name = "col0", .direction = .in },
    .GPIO5 = .{ .name = "col1", .direction = .in },
    .GPIO6 = .{ .name = "col2", .direction = .in },
    .GPIO7 = .{ .name = "col3", .direction = .in },
};
const matrix = matrix_config.pins();

//
// describe hardware
//

const Pin = @TypeOf(matrix.row0);
const rows: []const Pin = &.{ matrix.row0, matrix.row1, matrix.row2, matrix.row3 };
const cols: []const Pin = &.{ matrix.col0, matrix.col1, matrix.col2, matrix.col3 };

// zig fmt: off
const layout: zkf.Layout = &.{
    &.{  0,  1,  2,  3 },
    &.{  4,  5,  6,  7 },
    &.{  8,  9, 10, 11 },
    &.{ 12, 13, 14, 15 },
};
// zig fmt: on

const Keyboard = zkf.Keyboard(
    &.{
        // zig fmt: off
        &.{
            us.A,  us.A,  us.A,  us.A,
            us.A,  us.A,  us.A,  us.A,
            us.A,  us.A,  us.A,  us.A,
            us.A,  us.A,  us.A,  us.A,
        },
        // zig fmt: on
    },
    zkf.scan.matrix(Pin, rows, cols, layout, .row_col),
);

fn ledHandler(event: zkf.events.Event) void {
    const data = switch (event) {
        .key_input => |data| data,
        else => unreachable,
    };

    const led = switch (data.index) {
        0 => leds.red,
        1 => leds.green,
        2 => leds.blue,
        else => return,
    };

    const value: u1 = switch (data.type) {
        .pressed => 1,
        .released => 0,
    };

    led.put(value);
}

const led_subscription: zkf.events.Subscription = .{
    .event = .key_input,
    .handler = ledHandler,
};

pub fn main() !void {
    // initialize hardware
    leds_config.apply();
    matrix_config.apply();
    usb_if.init(usb_dev);

    var keyboard: Keyboard = .new();
    try keyboard.events.register(led_subscription);

    while (true) {
        // Process pending USB housekeeping
        try usb_dev.task(false);

        keyboard.scan();
    }
}

const zkf = @import("zkf");
const us = zkf.languages.english_us;
