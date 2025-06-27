pub const events = @import("core/events.zig");
pub const languages = keycodes.languages;
pub const scan = @import("core/scan.zig");

pub const Keyboard = keyboard.Keyboard;
pub const Keycode = keycodes.Keycode;
pub const Layout = types.Layout;

const keyboard = @import("core/keyboard.zig");
const keycodes = @import("core/keycodes.zig");
const types = @import("core/types.zig");
