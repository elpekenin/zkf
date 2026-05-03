const std = @import("std");
const zkf = @import("zkf");

pub const Id = std.meta.Int(
    .unsigned,
    std.math.log2(zkf.options.max_layers),
);
pub const max = zkf.options.max_layers;
pub const State = std.StaticBitSet(max);

pub const Layers = @This();

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
    const reversed: State = .{
        .mask = @bitReverse(self.state.mask),
    };

    if (reversed.findFirstSet()) |index| {
        return @intCast(index);
    }

    return self.default;
}
