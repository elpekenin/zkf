default: Id,
state: State,

pub fn withDefault(layer: Id) Layers {
    return .{
        .default = layer,
        .state = .initEmpty(),
    };
}

pub fn enable(self: *Layers, layer: Id) void {
    self.state.set(layer);
}

pub fn disable(self: *Layers, layer: Id) void {
    self.state.unset(layer);
}

pub fn isActive(self: *const Layers, layer: Id) bool {
    return self.state.isSet(layer) or layer == self.default;
}

pub fn highest(self: *const Layers) Id {
    // function finds first from LSB, thus we need to `@bitReverse` before using it, we want the first from MSB
    const reversed: State = .{ .mask = @bitReverse(self.state.mask) };
    if (reversed.findFirstSet()) |index| {
        return @intCast(index);
    }

    return self.default;
}

pub const Layers = @This();
pub const MAX = 32;
pub const Id = types.Index(MAX);
pub const State = std.StaticBitSet(MAX);

const std = @import("std");
const types = @import("types.zig");
