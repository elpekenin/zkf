const std = @import("std");
const microzig = @import("microzig");
const options = @import("options");

const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const uart = rp2xxx.uart.instance.num(0);

const zkf = @import("zkf");
const us = zkf.languages.english_us;

const usb = @import("usb.zig");

fn logFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (options.uart_logging) {
        rp2xxx.uart.log(level, scope, format, args);
    }
}

pub const microzig_options: microzig.Options = .{
    .log_level = .info,
    .logFn = logFn,
};

const pin_config: rp2xxx.pins.GlobalConfiguration = .{
    .GPIO0 = .{ .name = "c4", .direction = .in },
    .GPIO1 = .{ .name = "c3", .direction = .in },
    .GPIO2 = .{ .name = "c2", .direction = .in },
    .GPIO3 = .{ .name = "c1", .direction = .in },
    //
    .GPIO4 = .{ .name = "r1", .direction = .out },
    .GPIO5 = .{ .name = "r2", .direction = .out },
    .GPIO6 = .{ .name = "r3", .direction = .out },
    .GPIO7 = .{ .name = "r4", .direction = .out },
    //
    .GPIO12 = .{ .name = "tx", .function = .UART0_TX },
    //
    .GPIO25 = .{ .name = "led", .direction = .out },
};

const pins = pin_config.pins();
const Pin = @TypeOf(pins.r1);
const rows: []const Pin = &.{ pins.r1, pins.r2, pins.r3, pins.r4 };
const cols: []const Pin = &.{ pins.c1, pins.c2, pins.c3, pins.c4 };

var usb_device: usb.Device = undefined;
var usb_controller: usb.ControllerType = .init;

fn ledHandler(ctx: ?*anyopaque, keyboard: *zkf.Keyboard, event: *const zkf.KeyEvent) void {
    _ = keyboard;
    const pin: *const Pin = @ptrCast(ctx orelse @panic("unreachable nullptr"));

    if (event.pressed) {
        pin.toggle();
    }
}

const led: zkf.Keycode = .{
    .custom = .{
        .data = @ptrCast(@constCast(&pins.led)),
        .handler = ledHandler,
    },
};

pub fn main() !void {
    // configure pins
    _ = pin_config.apply();

    if (options.uart_logging) {
        uart.apply(.{
            .baud_rate = 9_600,
            .clock_config = rp2xxx.clock_config,
        });
        rp2xxx.uart.init_logger(uart);
    }

    var keyboard: zkf.Keyboard = .init(.{
        .keymap = &.{
            // zig fmt: off
            &.{
                us.A, us.B, us.C,   us.D,
                us.E, us.F, us.G,   us.H,
                us.I, us.J, us.K,   us.L,
                us.M, us.N, .mo(1), led,
            },
            &.{
                us.A, us.B, us.C, us.D,
                us.E, us.F, us.G, us.H,
                us.I, us.J, us.K, us.L,
                us.M, us.N, .___, us.O,
            }
            // zig fmt: on
        },
        .portability = .{
            .getTime = getTime,
            .sendHid = sendHid,
            .scanKeys = zkf.scan.matrix(
                Pin,
                rows,
                cols,
                &.{
                    &.{ 0, 1, 2, 3 },
                    &.{ 4, 5, 6, 7 },
                    &.{ 8, 9, 10, 11 },
                    &.{ 12, 13, 14, 15 },
                },
                .{
                    .diode_direction = .row_col,
                    .output_delay = .us(200),
                },
            ),
        },
    });

    usb_device = .init();
    while (true) {
        usb_device.poll(&usb_controller);

        const changes = keyboard.scan();
        if (changes.findFirstSet() == null) {
            continue;
        }

        var iterator = changes.iterator(.{});
        while (iterator.next()) |raw| {
            const key_id: zkf.keys.Id = @intCast(raw);

            const keycode = keyboard.getKeycodeAt(key_id);
            const pressed = keyboard.isKeyPressed(key_id);

            keyboard.processKeycode(keycode, pressed);
        }
    }
}

fn getTime() zkf.Time {
    return .us(time.get_time_since_boot().to_us());
}

fn sendHid(report: *const zkf.hid.KbToHost) void {
    if (usb_controller.drivers()) |drivers| {
        _ = drivers.keyboard.send_report(report);
    } else {
        std.log.err("no drivers found", .{});
    }
}
