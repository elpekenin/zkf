const zkf = @import("zkf");
const hid = @import("../hid.zig");

const WithMods = @This();

base: *const zkf.Keycode,
modifiers: hid.Modifiers,

pub fn addMods(lhs: WithMods, modifiers: hid.Modifiers) WithMods {
    var value = lhs;
    value.modifiers = value.modifiers.add(modifiers);
    return value;
}

pub fn process(self: *const WithMods, keyboard: *zkf.Keyboard, event: *const zkf.KeyEvent) void {
    if (event.pressed) {
        keyboard.hid_state.report.addMods(self.modifiers);
        keyboard.processKeycode(self.base.*, event.pressed);
    } else {
        keyboard.hid_state.report.removeMods(self.modifiers);
        keyboard.processKeycode(self.base.*, event.pressed);
    }
}
