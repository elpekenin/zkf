pub fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    const msg = std.fmt.comptimePrint(fmt, args);

    if (@inComptime()) {
        @compileError(msg);
    }

    @panic(msg);
}

const std = @import("std");
