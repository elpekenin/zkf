const std = @import("std");

const zkf = @import("zkf");
const hid = @import("hid.zig");
const Keymap = @import("Keymap.zig");
const keys = @import("keys.zig");
const Layers = @import("Layers.zig");

const Keyboard = @This();

const Options = struct {
    portability: zkf.Portability,
    keymap: Keymap.Raw,
    debounce: zkf.Time = .ms(5),
    default_layer: Layers.Id = 0,
    combos: []const zkf.Combo = &.{},
};

// TODO: implement combo handling
combos: []const zkf.Combo,
debouncer: keys.Debouncer,
hid_state: hid.State,
keymap: Keymap,
layers: Layers,
portability: zkf.Portability,

pub fn init(comptime options: Options) Keyboard {
    return .{
        .combos = options.combos,
        .debouncer = .init(options.debounce),
        .hid_state = .empty,
        .keymap = .from(options.keymap),
        .layers = .withDefault(options.default_layer),
        .portability = options.portability,
    };
}

pub fn getKeycodeAt(self: *const Keyboard, key: keys.Id) zkf.Keycode {
    const highest_layer = self.layers.highest();

    var layer: Layers.Id = highest_layer;
    while (layer >= 0) : (layer -= 1) {
        if (self.layers.isActive(layer)) {
            const keycode = self.keymap.get(layer, key);
            if (keycode != .transparent) {
                return keycode;
            }
        }
    }

    std.log.debug("no keycode found for key {}, returning noop", .{key});
    return .noop;
}

pub fn sleep(self: *const Keyboard, duration: zkf.Time) void {
    const start = self.portability.getTime();
    const deadline = start.add(duration);

    while (true) {
        const now = self.portability.getTime();
        if (deadline.lt(now)) return;
    }
}

pub fn scan(self: *Keyboard) keys.State {
    const now = self.portability.getTime();
    const key_state = self.portability.scanKeys(self);

    return self.debouncer.update(now, key_state);
}

pub fn isKeyPressed(self: *const Keyboard, key_id: keys.Id) bool {
    return self.debouncer.isPressed(key_id);
}

pub fn sendReport(self: *const Keyboard) void {
    return self.portability.sendHid(&self.hid_state.report);
}

pub fn processKeycode(self: *Keyboard, keycode: zkf.Keycode, pressed: bool) void {
    // make sure the report gets sent after (potentially) modifying it
    defer self.sendReport();

    const event: zkf.KeyEvent = .{
        .keycode = keycode,
        .pressed = pressed,
    };

    switch (keycode) {
        .noop => {},
        .transparent => std.log.err("getKeycode should never return transparent", .{}),
        inline else => |kc| kc.process(self, &event),
    }
}

pub fn addKc(self: *Keyboard, keycode: hid.Keycode) void {
    self.hid_state.report.addKc(keycode);
}

pub fn removeKc(self: *Keyboard, keycode: hid.Keycode) void {
    self.hid_state.report.removeKc(keycode);
}

pub fn tapKc(
    self: *Keyboard,
    keycode: hid.Keycode,
    options: struct {
        delay: zkf.Time = .ms(zkf.options.tap_delay_ms),
    },
) void {
    self.addKc(keycode);
    self.sleep(options.delay);
    self.removeKc(keycode);
}

pub fn addMods(self: *Keyboard, modifiers: hid.Modifiers) void {
    self.hid_state.report.addMods(modifiers);
}

pub fn removeMods(self: *Keyboard, modifiers: hid.Keycode) void {
    self.hid_state.report.removeMods(modifiers);
}
