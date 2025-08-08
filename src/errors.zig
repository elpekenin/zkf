pub inline fn fatal(comptime msg: []const u8) noreturn {
    if (@inComptime()) {
        @compileError(msg);
    }

    @panic(msg);
}
