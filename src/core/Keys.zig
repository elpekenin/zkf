state: State,

pub fn initEmpty() Keys {
    return .{
        .state = .initEmpty(),
    };
}

pub fn isPressed(self: *const Keys, key: Id) bool {
    return self.state.isSet(key);
}

/// returns which keys have changed
pub fn update(self: *Keys, rhs: State) State {
    const changes = self.state.xorWith(rhs);
    self.state = rhs;
    return changes;
}

const t = std.testing;
pub const Keys = @This();
pub const MAX = 256;
pub const Id = types.Index(MAX);
pub const State = std.StaticBitSet(MAX);

const std = @import("std");
const types = @import("types.zig");

test "difference" {
    const index = 0;

    var first: State = .initEmpty();
    first.set(0);
    first.set(1);

    // only index 0 changed
    var second = first;
    second.toggle(index);

    var expected: State = .initEmpty();
    expected.set(index);

    const actual = update(first, second);

    try t.expectEqual(expected, actual);
}

test "difference multiple changes" {
    const indexes: []const usize = &.{ 0, 1 };

    var first: State = .initEmpty();
    first.set(1);

    var second = first;
    for (indexes) |index| {
        second.toggle(index);
    }

    var expected: State = .initEmpty();
    for (indexes) |index| {
        expected.set(index);
    }

    const actual = update(first, second);
    try t.expectEqual(expected, actual);
}
