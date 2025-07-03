pub const languages = @import("keycodes/languages.zig");

pub const Keycode = union(enum) {
    noop,
    transparent,
    hid: hid.Keycode,
    with_mods: WithModifiers,
    layer_with_mods: LayerWithModifiers,
    user: User,

    fn addMods(keycode: Keycode, mods: hid.Modifiers) Keycode {
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
            .layer_with_mods => |kc| .{
                .layer_with_mods = kc.addMods(mods),
            },
            else => {
                if (@inComptime()) {
                    @compileError("can't add modifiers to this keycode");
                }

                @panic("TODO: Decide how to handle this");
            },
        };
    }

    // basic things
    pub const XXX: Keycode = .noop;
    pub const ___: Keycode = .transparent;

    // modifiers
    pub fn LCTL(keycode: Keycode) Keycode {
        return keycode.addMods(.lc);
    }

    pub fn LSFT(keycode: Keycode) Keycode {
        return keycode.addMods(.ls);
    }

    pub fn LALT(keycode: Keycode) Keycode {
        return keycode.addMods(.la);
    }

    pub fn LGUI(keycode: Keycode) Keycode {
        return keycode.addMods(.lg);
    }

    pub fn RCTL(keycode: Keycode) Keycode {
        return keycode.addMods(.rc);
    }

    pub fn RSFT(keycode: Keycode) Keycode {
        return keycode.addMods(.rs);
    }

    pub fn RALT(keycode: Keycode) Keycode {
        return keycode.addMods(.ra);
    }

    pub fn RGUI(keycode: Keycode) Keycode {
        return keycode.addMods(.rg);
    }

    // layer mod
    pub fn LM(layer: usize, modifiers: hid.Modifiers) Keycode {
        return .{
            .layer_with_mods = .{
                .layer = layer,
                .modifiers = modifiers,
            },
        };
    }

    pub fn Custom(handler: User.BasicFn) Keycode {
        return .{
            .user = .{
                .basic = handler,
            },
        };
    }

    pub fn CustomAdvanced(handler: User.BasicFn, data: *anyopaque) Keycode {
        return .{
            .user = .{
                .advanced = .{
                    .function = handler,
                    .data = data,
                },
            },
        };
    }
};

const WithModifiers = struct {
    hid: hid.Keycode,
    modifiers: hid.Modifiers,

    pub fn addMods(lhs: WithModifiers, modifiers: hid.Modifiers) WithModifiers {
        var value = lhs;
        value.modifiers = value.modifiers.add(modifiers);
        return value;
    }
};

const LayerWithModifiers = struct {
    layer: Layers.Id,
    modifiers: hid.Modifiers,

    pub fn addMods(lhs: LayerWithModifiers, modifiers: hid.Modifiers) LayerWithModifiers {
        var value = lhs;
        value.modifiers = value.modifiers.add(modifiers);
        return value;
    }
};

const User = union(enum) {
    basic: BasicFn,
    advanced: struct {
        function: AdvancedFn,
        data: *anyopaque,
    },

    const BasicFn = *const fn (bool) void;
    const AdvancedFn = *const fn (*anyopaque, bool) void;
};

const hid = @import("hid.zig");
const Layers = @import("Layers.zig");
