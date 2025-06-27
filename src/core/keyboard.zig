pub fn Keyboard(comptime keymap: Keymap, scan_fn: anytype) type {
    const KeysState = KeyStateFromKeymap(keymap);

    const n_keys = keymap[0].len;

    const ScanFn = @TypeOf(scan_fn);
    const scan_info = @typeInfo(ScanFn);

    const valid, const ret_type = switch (scan_info) {
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

    if (KeysState != ret_type) {
        const msg = comptimePrint("Mismatch between layout and scan. Expected return value of {s}, got {s}", .{
            @typeName(KeysState),
            @typeName(ret_type),
        });
        @compileError(msg);
    }

    // can go out of bounds (eg: with 12 keys -> u4, can receive values up to 15)
    // ... but still better than an arbitrary uX type
    const KeyIndex = types.Index(n_keys);

    return struct {
        keys_state: KeysState,
        layer_state: layer.State,
        events: events.Manager,

        pub fn new() Self {
            return .{
                .keys_state = .initEmpty(),
                // layer 0 enabled by default
                .layer_state = .{ .mask = 1 },
                .events = .new(),
            };
        }

        pub fn isLayerActive(self: *const Self, layer_num: layer.Index) bool {
            const mask = @as(layer.State, 1) << layer_num;
            return (self.layer_state & mask) != 0;
        }

        pub fn getKeymap(_: *const Self) Keymap {
            return keymap;
        }

        fn keycodeAt(self: *const Self, layer_num: layer.Index, index: KeyIndex) Keycode {
            const layer_active = self.isLayerActive(layer_num);
            if (!layer_active) {
                return if (layer_num == 0)
                    .noop
                else
                    self.keycodeAt(layer_num - 1, index);
            }

            const keycode = keymap[layer_num][index];
            return if (keycode == .transparent)
                self.keycodeAt(layer_num - 1, index)
            else
                keycode;
        }

        pub fn getHighestLayer(self: *const Self) layer.Index {
            self.layer_state.findFirstSet();
        }

        pub fn getKeycode(self: *const Self, index: KeyIndex) Keycode {
            const highest_layer = self.getHighestLayer();
            return self.keycodeAt(highest_layer, index);
        }

        pub fn isPressed(self: *const Self, index: KeyIndex) bool {
            return self.keys_state.isSet(index);
        }

        pub fn scan(self: *Self) void {
            const keys_state = scan_fn();

            // dont forget to update
            defer self.keys_state = keys_state;

            const changes = self.keys_state.xorWith(keys_state);

            var iterator = changes.iterator(.{});
            while (iterator.next()) |index| {
                const event: events.Event = .keyPress(@intCast(index));
                self.events.emit(event);
            }
        }

        const Self = @This();
    };
}

const std = @import("std");

const events = @import("events.zig");
const keycodes = @import("keycodes.zig");
const layer = @import("layer.zig");
const types = @import("types.zig");

const comptimePrint = std.fmt.comptimePrint;

const Keycode = keycodes.Keycode;
const Keymap = types.Keymap;
const KeyStateFromKeymap = types.KeyStateFromKeymap;
