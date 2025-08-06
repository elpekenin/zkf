pub const hid = @import("core/hid.zig");
pub const languages = keycodes.languages;
pub const scan = @import("core/scan.zig");

pub const Keyboard = @import("core/Keyboard.zig");
pub const Keycode = keycodes.Keycode;
pub const Keymap = types.Keymap;
pub const keys = @import("core/keys.zig");
pub const Layout = types.Layout;
pub const Time = @import("core/time.zig").Time;

const keycodes = @import("core/keycodes.zig");
const types = @import("core/types.zig");

// TODO: opt-in tracing and/or debugging
