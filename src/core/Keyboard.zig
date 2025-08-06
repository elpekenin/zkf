/// platform-specific logic
///
/// to be provided by user, as the "glue" for the lib to interact with hardware
pub const Portability = struct {
    pub const GetTime = *const fn () Time;
    pub const SendHid = *const fn (HidReport) void;
    pub const ScanKeys = *const fn (*const Keyboard) keys.State;

    /// time since boot
    getTime: GetTime,
    sendHid: SendHid,
    scanKeys: ScanKeys,
};

/// user configuration of the keyboard (mostly, the keymap)
const Options = struct {
    debounce: Time,
    default_layer: Layers.Id = 0,
    keymap: Keymap.Raw,
    portability: Portability,
};

debouncer: keys.Debouncer,
hid: HidState,
keymap: Keymap,
layers: Layers,
portability: Portability,

/// create a `Keyboard` instance given its configuration
pub fn new(comptime options: Options) Keyboard {
    const n_layers = comptime options.keymap.len;
    if (n_layers == 0) {
        @compileError("empty keymap");
    }
    if (n_layers > Layers.MAX) {
        @compileError("number of layers exceeds current maximum");
    }

    const n_keys = comptime getNKeys(options.keymap);
    if (n_keys > keys.MAX) {
        @compileError("number of keys exceeds current maximum");
    }

    validateKeycodes(options.keymap);

    return .{
        .debouncer = .init(options.debounce),
        .hid = .initEmpty(),
        .keymap = .from(options.keymap),
        .layers = .withDefault(options.default_layer),
        .portability = options.portability,
    };
}

pub fn keycodeGet(self: *const Keyboard, key: keys.Id) Keycode {
    var layer = self.layers.highest();
    while (true) : (layer -= 1) {
        if (self.layers.isActive(layer)) {
            const keycode = self.keymap.get(layer, key);
            if (keycode != .transparent) {
                return keycode;
            }
        }

        // can't go further down
        if (layer == 0) {
            return .noop;
        }
    }
}

pub fn scan(self: *Keyboard) keys.State {
    const now = self.portability.getTime();
    const reading = self.portability.scanKeys(self);
    return self.debouncer.update(now, reading);
}

pub fn processChanges(self: *Keyboard, changes: keys.State) void {
    var iterator = changes.iterator(.{});
    while (iterator.next()) |raw| {
        const id: keys.Id = @intCast(raw);

        const keycode = self.keycodeGet(id);
        const pressed = self.debouncer.isPressed(id);

        self.process(keycode, pressed) catch |e| {
            std.log.warn("could not process {} ({})", .{ keycode, e });
        };
    }
}

fn process(self: *Keyboard, keycode: Keycode, pressed: bool) !void {
    // make sure the report gets sent after (potentially) modifying it
    defer self.portability.sendHid(self.hid.report);

    switch (keycode) {
        .noop,
        .transparent,
        => {},
        .hid => |kc| {
            if (pressed) {
                try self.hid.report.addKc(kc);
            } else {
                try self.hid.report.removeKc(kc);
            }
        },
        .with_mods => |kc| {
            if (pressed) {
                self.hid.report.addMods(kc.modifiers);
                try self.hid.report.addKc(kc.hid);
            } else {
                self.hid.report.removeMods(kc.modifiers);
                try self.hid.report.removeKc(kc.hid);
            }
        },
        .layer_with_mods => |kc| {
            if (pressed) {
                self.hid.report.addMods(kc.modifiers);
                self.layers.enable(kc.layer);
            } else {
                self.hid.report.removeMods(kc.modifiers);
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

/// check for erroneous configuration of a keymap
///
/// eg: a layer-related keycode that targets an id bigger than the number of layers
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

const comptimePrint = std.fmt.comptimePrint;
const Keyboard = @This();
const Keycode = keycodes.Keycode;

const std = @import("std");
const keycodes = @import("keycodes.zig");
const HidReport = @import("hid.zig").Report;
const HidState = @import("hid.zig").State;
const Keymap = @import("Keymap.zig");
const keys = @import("keys.zig");
const Layers = @import("Layers.zig");
const Time = @import("time.zig").Time;
