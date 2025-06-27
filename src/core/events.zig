pub const Manager = struct {
    n: usize,
    subscriptions: [N]Subscription,

    pub fn new() Manager {
        return .{
            .n = 0,
            .subscriptions = undefined,
        };
    }

    pub fn register(self: *Manager, subscription: Subscription) !void {
        defer self.n += 1;

        if (self.n == N) {
            return error.OutOfMemory;
        }

        self.subscriptions[self.n] = subscription;
    }

    pub fn emit(self: *const Manager, event: Event) void {
        for (self.subscriptions[0..self.n]) |subscription| {
            if (subscription.event == event) {
                subscription.handler(event);
            }
        }
    }

    const N = 100; // TODO: configurable size
};

pub const Subscription = struct {
    event: EventType,
    handler: EventHandler,
};

pub const EventType = enum {
    key_input,
    layer_change,
};

pub const Event = union(EventType) {
    key_input: KeyInput,
    layer_change: LayerChange,

    pub fn keyPress(index: KeyIndex) Event {
        return .{
            .key_input = .{
                .type = .pressed,
                .index = index,
            },
        };
    }

    pub fn keyRelease(index: KeyIndex) Event {
        return .{
            .key_input = .{
                .type = .released,
                .index = index,
            },
        };
    }

    pub fn layerEnabled(index: layer.Index) Event {
        return .{
            .layer_change = .{
                .type = .enabled,
                .index = index,
            },
        };
    }

    pub fn layerDisabled(index: layer.Index) Event {
        return .{
            .layer_change = .{
                .type = .disabled,
                .index = index,
            },
        };
    }
};

const KeyInput = struct {
    type: enum {
        pressed,
        released,
    },
    index: KeyIndex,
};

const LayerChange = struct {
    type: enum {
        enabled,
        disabled,
    },
    index: layer.Index,
};

// NOTE: stub type, real one on the struct returned by `Keyboard(...)`
// is dynamic (smallest uX that can handle the number of keys)
const KeyIndex = u16;

const layer = @import("layer.zig");

const EventHandler = *const fn (Event) void;
