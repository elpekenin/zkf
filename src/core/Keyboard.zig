hid: hid_.State,
keymap: Keymap,
keys: Keys,
layers: Layers,

functions: Functions,

pub fn new(comptime options: Options) Keyboard {
    const n_layers = comptime options.keymap.len;
    if (n_layers == 0) {
        @compileError("empty keymap");
    }
    if (n_layers > Layers.MAX) {
        @compileError("number of layers exceeds current maximum");
    }

    const n_keys = comptime getNKeys(options.keymap);
    if (n_keys > Keys.MAX) {
        @compileError("number of keys exceeds current maximum");
    }

    validateKeycodes(options.keymap);

    return .{
        .hid = .initEmpty(),
        .keymap = .from(options.keymap),
        .keys = .initEmpty(),
        .layers = .withDefault(options.default_layer),
        .functions = .{
            .hid = options.send,
            .scan = options.scan,
        },
    };
}

pub fn keycodeGet(self: *const Keyboard, key: Keys.Id) Keycode {
    var layer = self.layers.highest();

    while (layer > 0) : (layer -= 1) {
        if (!self.layers.isActive(layer)) {
            continue;
        }

        const keycode = self.keymap.get(layer, key);
        if (keycode != .transparent) {
            return keycode;
        }
    }

    return .noop;
}

pub fn scan(self: *Keyboard) Keys.State {
    const reading = self.functions.scan();
    return self.keys.update(reading);
}

pub fn processChanges(self: *Keyboard, changes: Keys.State) void {
    var iterator = changes.iterator(.{});
    while (iterator.next()) |raw| {
        const id: Keys.Id = @intCast(raw);

        const keycode = self.keycodeGet(id);
        const pressed = self.keys.isPressed(id);

        self.process(keycode, pressed) catch |e| {
            std.log.err("Processing {} ({})", .{ keycode, e });
        };
    }
}

fn process(self: *Keyboard, keycode: Keycode, pressed: bool) !void {
    const initial = self.hid.report;
    defer if (!self.hid.report.eql(initial)) {
        self.functions.hid(self.hid.report);
    };

    switch (keycode) {
        .noop,
        .transparent,
        => {},
        .hid => |kc| {
            if (pressed) {
                try self.hid.report.addKeycode(kc);
            } else {
                try self.hid.report.popKeycode(kc);
            }
        },
        .with_mods => |kc| {
            if (pressed) {
                self.hid.report.addModifiers(kc.modifiers);
                try self.hid.report.addKeycode(kc.hid);
            } else {
                self.hid.report.popModifiers(kc.modifiers);
                try self.hid.report.popKeycode(kc.hid);
            }
        },
        .layer_with_mods => |kc| {
            if (pressed) {
                self.hid.report.addModifiers(kc.modifiers);
                self.layers.enable(kc.layer);
            } else {
                self.hid.report.popModifiers(kc.modifiers);
                self.layers.disable(kc.layer);
            }
        },
        .user => |kc| {
            switch (kc) {
                .basic => |function| function(pressed),
                .advanced => |config| config.function(config.data, pressed),
            }
        },
    }
}

fn getNKeys(comptime keymap: Keymap.Raw) usize {
    const n_keys = keymap[0].len;

    for (1..keymap.len) |i| {
        const len = keymap[i].len;
        if (len != n_keys) {
            const msg = comptimePrint("layer {d} has wrong size. expected {d}, got {d}", .{ i, n_keys, len });
            @compileError(msg);
        }
    }

    return n_keys;
}

fn validateKeycodes(comptime keymap: Keymap.Raw) void {
    for (keymap) |layer| {
        for (layer) |keycode| {
            switch (keycode) {
                .noop,
                .transparent,
                .hid,
                .with_mods,
                => {},

                .layer_with_mods => |kc| {
                    const index = kc.layer;
                    if (index >= Layers.MAX) {
                        const msg = comptimePrint("keycode targets layer index {d}, which is out of range", .{index});
                        @compileError(msg);
                    }
                },

                .user => {},
            }
        }
    }
}

const Options = struct {
    keymap: Keymap.Raw,
    default_layer: Layers.Id = 0,
    scan: Scan,
    send: Send,
};

const Functions = struct {
    scan: Scan,
    hid: Send,
};

const comptimePrint = std.fmt.comptimePrint;
const Keyboard = @This();
const Keycode = keycodes.Keycode;
const Scan = *const fn () Keys.State;
const Send = *const fn (hid_.Report) void;

const std = @import("std");
const hid_ = @import("hid.zig");
const keycodes = @import("keycodes.zig");
const Keymap = @import("Keymap.zig");
const Keys = @import("Keys.zig");
const Layers = @import("Layers.zig");
