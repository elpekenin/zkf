pub fn function(
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

const comptimePrint = std.fmt.comptimePrint;

const std = @import("std");
const microzig = @import("microzig");
const uart = microzig.hal.uart.instance.num(0);
