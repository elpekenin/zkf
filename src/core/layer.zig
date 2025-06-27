const MAX_LAYERS = 32;
pub const State = std.StaticBitSet(MAX_LAYERS);
pub const Index = types.Index(MAX_LAYERS);

const std = @import("std");
const types = @import("types.zig");
