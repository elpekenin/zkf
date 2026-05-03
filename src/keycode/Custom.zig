const zkf = @import("zkf");

const Custom = @This();

handler: *const fn (?*anyopaque, keyboard: *zkf.Keyboard, *const zkf.KeyEvent) void,
data: ?*anyopaque,

pub fn process(self: *const Custom, keyboard: *zkf.Keyboard, event: *const zkf.KeyEvent) void {
    self.handler(self.data, keyboard, event);
}
