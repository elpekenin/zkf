const microzig = @import("microzig");
const usb_if = @import("usb_if.zig");
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const usb_dev = rp2xxx.usb.Usb(.{});

//
// pin config
//
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
    .GPIO25 = .{ .name = "LED", .direction = .out },
};
const pins = pins_config.pins();

//
// custom code
//
fn ledHandler(pressed: bool) void {
    const value = @intFromBool(pressed);
    pins.LED.put(value);
}
const LED: zkf.Keycode = .Custom(ledHandler);

//
// describe keyboard
//
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

const Keyboard = zkf.KeyboardConfig.new()
    .setKeymap(&.{
        // zig fmt: off
        &.{
            us.A, us.B, us.C, us.D,
            us.E, us.F, us.G, us.H,
            us.I, us.J, us.K, us.L,
            us.M, us.N, us.O, LED,
        },
        // zig fmt: on
    })
    .setScan(zkf.scan.matrix(Pin, rows, cols, layout, .row_col, delay))
    .setSendHid(sendHid)
    // TODO: .addCombos() and whatnot
    .Keyboard();

pub fn main() !void {
    // initialize hardware
    pins_config.apply();
    usb_if.init(usb_dev);

    var keyboard: Keyboard = .new();

    while (true) {
        // Process pending USB housekeeping
        try usb_dev.task(false);

        keyboard.scanAndProcess();
    }
}

const zkf = @import("zkf");
const us = zkf.languages.english_us;
