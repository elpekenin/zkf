const zkf = @import("zkf");
const hid = @import("../hid.zig");

const Hid = @This();

keycode: hid.Keycode,

pub fn from(keycode: hid.Keycode) Hid {
    return .{
        .keycode = keycode,
    };
}

pub fn process(self: *const Hid, keyboard: *zkf.Keyboard, event: *const zkf.KeyEvent) void {
    if (event.pressed) {
        keyboard.addKc(self.keycode);
    } else {
        keyboard.removeKc(self.keycode);
    }
}
