inner: Raw,

pub fn from(raw: Raw) Keymap {
    return .{
        .inner = raw,
    };
}

pub fn get(self: *const Keymap, layer: Layers.Id, key: keys.Id) Keycode {
    return self.inner[layer][key];
}

const Keycode = keycodes.Keycode;
const Keymap = @This();
pub const Raw = []const []const Keycode;

const keycodes = @import("keycodes.zig");
const keys = @import("keys.zig");
const Layers = @import("Layers.zig");
