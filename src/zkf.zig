pub const hid = @import("core/hid.zig");
pub const languages = keycodes.languages;
pub const scan = @import("core/scan.zig");

pub const KeyboardConfig = @import("core/KeyboardConfig.zig");
pub const Keycode = keycodes.Keycode;
pub const Keymap = types.Keymap;
pub const Layout = types.Layout;

const keycodes = @import("core/keycodes.zig");
const types = @import("core/types.zig");

comptime {
    _ = hid;
    _ = KeyboardConfig;
}
