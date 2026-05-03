const std = @import("std");

const Custom = @import("keycode/Custom.zig");
const Hid = @import("keycode/Hid.zig");
const TemporaryLayer = @import("keycode/TemporaryLayer.zig");
const WithMods = @import("keycode/WithMods.zig");

const hid = @import("hid.zig");
const Layers = @import("Layers.zig");

pub const Keycode = union(enum) {
    noop,
    transparent,
    hid: Hid,
    with_mods: WithMods,
    temporary_layer: TemporaryLayer,
    custom: Custom,

    pub const ___: Keycode = .transparent;

    pub fn addMods(keycode: Keycode, mods: hid.Modifiers) Keycode {
        return switch (keycode) {
            .hid => |kc| .{
                .with_mods = .{
                    .hid = kc,
                    .modifiers = mods,
                },
            },
            .with_mods => |kc| .{
                .with_mods = kc.addMods(mods),
            },
            else => std.debug.panic("can't add modifiers to keycode {}", .{keycode}),
        };
    }

    pub fn lctl(keycode: Keycode) Keycode {
        return keycode.addMods(.lc);
    }

    pub fn lsft(keycode: Keycode) Keycode {
        return keycode.addMods(.ls);
    }

    pub fn lalt(keycode: Keycode) Keycode {
        return keycode.addMods(.la);
    }

    pub fn lgui(keycode: Keycode) Keycode {
        return keycode.addMods(.lg);
    }

    pub fn rctl(keycode: Keycode) Keycode {
        return keycode.addMods(.rc);
    }

    pub fn rsft(keycode: Keycode) Keycode {
        return keycode.addMods(.rs);
    }

    pub fn ralt(keycode: Keycode) Keycode {
        return keycode.addMods(.ra);
    }

    pub fn rgui(keycode: Keycode) Keycode {
        return keycode.addMods(.rg);
    }

    pub fn mo(layer: Layers.Id) Keycode {
        return .{
            .temporary_layer = .{
                .layer = layer,
            },
        };
    }
};
