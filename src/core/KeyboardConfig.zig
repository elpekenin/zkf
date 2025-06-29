//! Configure a keyboard using the builder pattern
//!
//! ... Or create an instance manually if you wish

keymap: ?types.Keymap,
scan_info: ?struct {
    type: type,
    ptr: *const anyopaque,
},
send_hid: ?SendHidFn,

pub fn new() KeyboardConfig {
    return .{
        .keymap = null,
        .scan_info = null,
        .send_hid = null,
    };
}

pub fn setKeymap(builder: KeyboardConfig, comptime keymap: types.Keymap) KeyboardConfig {
    var ret = builder;
    ret.keymap = keymap;
    return ret;
}

pub fn setScan(builder: KeyboardConfig, comptime scan: anytype) KeyboardConfig {
    var ret = builder;

    ret.scan_info = .{
        .type = @TypeOf(scan),
        .ptr = scan,
    };

    return ret;
}

pub fn setSendHid(builder: KeyboardConfig, comptime send: SendHidFn) KeyboardConfig {
    var ret = builder;
    ret.send_hid = send;
    return ret;
}

/// Build the final keyboard type from configuration
pub fn Keyboard(builder: KeyboardConfig) type {
    // validate we received configuration
    const keymap = if (builder.keymap) |keymap|
        keymap
    else
        @compileError("Keymap was not configured");
    const n_keys, const n_layers = .{ getNKeys(keymap), keymap.len };
    const KeyState, const LayerState = .{ std.StaticBitSet(n_keys), std.StaticBitSet(n_layers) };
    validateKeycodes(keymap, n_layers);

    const scan_info = if (builder.scan_info) |scan|
        scan
    else
        @compileError("Function to scan keys was not configured");
    const scanKeys: scan_info.type = @ptrCast(@alignCast(scan_info.ptr));
    validateScanFunction(KeyState, scan_info.type);

    const sendHid = if (builder.send_hid) |sendHid|
        sendHid
    else
        @compileError("Function to send over HID was not configured");

    // NOTE: these index types can go out of bounds. eg: len=12 -> index=u4(up to 15)
    //       but they are still better than using an arbitrary type
    const KeyIndex = types.Index(n_keys);
    const LayerIndex = types.Index(n_layers);

    return struct {
        hid: hid.State,
        keys: KeyState,
        layers: LayerState,

        pub fn initEmpty() Self {
            // 0 is default layer, enabled by default
            var layers: LayerState = .initEmpty();
            layers.set(0);

            return .{
                .hid = .init(),
                .keys = .initEmpty(),
                .layers = layers,
            };
        }

        pub fn layerEnable(self: *Self, layer: LayerIndex) void {
            self.layers.set(layer);
        }

        pub fn layerDisable(self: *Self, layer: LayerIndex) void {
            // TODO: handle different default layers
            if (layer == 0) {
                return;
            }

            self.layers.unset(layer);
        }

        pub fn layerIsActive(self: *const Self, index: LayerIndex) bool {
            return self.layers.isSet(index);
        }

        pub fn layerGetHighest(self: *const Self) LayerIndex {
            // function finds first from LSB, thus we need to `@bitReverse` before using it, we want the first from MSB
            const reversed: LayerState = .{
                .mask = @bitReverse(self.layers.mask)
            };
            const index = reversed.findFirstSet() orelse @panic("layer 0 expected to always be set");
            return @intCast(index);
        }

        fn keycodeAt(self: *const Self, layer: LayerIndex, key: KeyIndex) Keycode {
            const layer_active = self.layerIsActive(layer);
            if (!layer_active) {
                return if (layer == 0)
                    .noop
                else
                    self.keycodeAt(layer - 1, key);
            }

            const keycode = keymap[layer][key];
            if (keycode != .transparent) {
                return keycode;
            }

            while (layer > 0) : (layer -= 1) {
                if (self.layerIsActive(layer)) {
                    return self.keycodeAt(layer, key);
                }
            }

            return .noop;
        }

        pub fn keycodeGet(self: *const Self, index: KeyIndex) Keycode {
            const highest_layer = self.layerGetHighest();
            return self.keycodeAt(highest_layer, index);
        }

        pub fn keyIsPressed(self: *const Self, index: KeyIndex) bool {
            return self.keys.isSet(index);
        }

        pub fn scanAndProcess(self: *Self) void {
            const keys = scanKeys();
            defer self.keys = keys;

            const changes = self.keys.xorWith(keys);

            var iterator = changes.iterator(.{});
            while (iterator.next()) |raw| {
                const index: KeyIndex = @intCast(raw);

                const keycode = self.keycodeGet(index);
                const pressed = keys.isSet(index);

                self.process(keycode, pressed) catch |e| {
                    std.log.err("Processing {}",.{ keycode, e });
                };
            }
        }

        fn process(self: *Self, keycode: Keycode, pressed: bool) !void {
            const initial = self.hid.report;
            defer if (!self.hid.report.eql(initial)) {
                sendHid(self.hid.report);
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
                    const layer: LayerIndex = @intCast(kc.layer);

                    if (pressed) {
                        self.hid.report.addModifiers(kc.modifiers);
                        self.layerEnable(layer);
                    } else {
                        self.hid.report.popModifiers(kc.modifiers);
                        self.layerDisable(layer);
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

        const Self = @This();
    };
}

fn getNKeys(comptime keymap: types.Keymap) usize {
    if (keymap.len == 0) {
        @compileError("Keymap can't be an empty array");
    }

    const n_keys = keymap[0].len;
    for (1..keymap.len) |i| {
        const len = keymap[i].len;
        if (len != n_keys) {
            const msg = comptimePrint("Layer {d} has wrong size. Expected {d}, got {d}", .{ i, n_keys, len });
            @compileError(msg);
        }
    }

    return n_keys;
}

fn validateScanFunction(comptime Expected: type, comptime Scan: type) void {
    const scan_info = @typeInfo(Scan);

    const valid, const Found = switch (scan_info) {
        .pointer => |pointer| blk: {
            const C = pointer.child;
            const c_info = @typeInfo(C);

            switch (c_info) {
                .@"fn" => |f| {
                    break :blk .{
                        !f.is_generic and !f.is_var_args and f.params.len == 0,
                        f.return_type.?,
                    };
                },
                else => break :blk .{ false, noreturn },
            }
        },
        else => .{ false, noreturn },
    };
    if (!valid) {
        @compileError("scan_fn must be a pointer to a function");
    }

    if (Expected != Found) {
        const msg = comptimePrint("Mismatch between layout and scan. Expected return value of {}, got {}", .{
            Expected,
            Found,
        });
        @compileError(msg);
    }
}

fn validateKeycodes(comptime keymap: types.Keymap, comptime n_layers: usize) void {
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
                    if (index >= n_layers) {
                        const msg = comptimePrint("Keycode targets layer index {d}, but there are {d} available", .{ index, n_layers });
                        @compileError(msg);
                    }
                },

                // TODO: maybe some validation on the ids?
                .user => {},
            }
        }
    }
}

const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;

const KeyboardConfig = @This();
const keycodes = @import("keycodes.zig");
const hid = @import("hid.zig");
const types = @import("types.zig");

const Keycode = keycodes.Keycode;
const SendHidFn = *const fn (hid.Report) void;
