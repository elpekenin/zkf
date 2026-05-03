const std = @import("std");

const zkf = @import("zkf");
const Layers = @import("Layers.zig");

pub const Raw = []const []const zkf.Keycode;

const Keymap = @This();

keycodes: Raw,

fn getNKeys(comptime keymap: Keymap.Raw) usize {
    const n_keys = keymap[0].len;

    for (1..keymap.len) |i| {
        const len = keymap[i].len;
        if (len != n_keys) {
            std.debug.panic("layer {d} has wrong size. expected {d}, got {d}", .{
                i,
                n_keys,
                len,
            });
        }
    }

    return n_keys;
}

pub fn from(comptime keymap: Raw) Keymap {
    const n_layers = keymap.len;
    if (n_layers == 0) std.debug.panic("keymap is empty", .{});
    if (n_layers > Layers.max) {
        std.debug.panic("keymap has more layers ({}) than supported ({})", .{
            n_layers,
            Layers.max,
        });
    }

    const n_keys = getNKeys(keymap);
    if (n_keys > zkf.keys.max) {
        std.debug.panic("keymap has more keys ({}) than supported ({})", .{
            n_keys,
            zkf.keys.max,
        });
    }

    for (keymap, 0..) |layer, layer_index| {
        for (layer, 0..) |keycode, key_index| {
            switch (keycode) {
                .noop,
                .transparent,
                .hid,
                .with_mods,
                => {},

                .temporary_layer => |kc| {
                    if (kc.layer >= keymap.len) {
                        std.debug.panic("invalid target layer {}. location {}:{}", .{ kc.layer, key_index, layer_index });
                    }

                    switch (keymap[kc.layer][key_index]) {
                        .transparent => continue, // TODO?: check what we fall through into
                        .temporary_layer => |target| {
                            if (target.layer == kc.layer) {
                                continue;
                            }
                        },
                        else => {},
                    }

                    std.debug.panic("key assigned to temporary layer must have the same keycode on target layer. location {}:{}", .{ layer_index, key_index });
                },

                .custom => {},
            }
        }
    }

    return .{
        .keycodes = keymap,
    };
}

pub fn get(self: *const Keymap, layer: Layers.Id, key: zkf.keys.Id) zkf.Keycode {
    return self.keycodes[layer][key];
}
