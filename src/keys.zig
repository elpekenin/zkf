const std = @import("std");
const zkf = @import("zkf");

pub const Id = std.meta.Int(
    .unsigned,
    std.math.log2(zkf.options.max_keys),
);

pub const max = zkf.options.max_keys;
pub const State = std.bit_set.ArrayBitSet(usize, max);

pub const Debouncer = struct {
    debounce: zkf.Time,
    state: State,
    timers: [max]zkf.Time,

    pub fn isPressed(self: *const Debouncer, key: Id) bool {
        return self.state.isSet(key);
    }

    pub fn init(debounce: zkf.Time) Debouncer {
        return .{
            .debounce = debounce,
            .state = .initEmpty(),
            .timers = @splat(.us(0)),
        };
    }

    pub fn update(self: *Debouncer, time: zkf.Time, state: State) State {
        const previous = self.state;

        const raw_changes = self.state.xorWith(state);
        var changes_iterator = raw_changes.iterator(.{});

        while (changes_iterator.next()) |index| {
            const last_key_change = self.timers[index];
            const elapsed = time.subtract(last_key_change);

            // change was too recent, do nothing
            if (elapsed.lt(self.debounce)) continue;

            self.timers[index] = time;
            self.state.setValue(index, state.isSet(index));
        }

        // actual changes
        return previous.xorWith(self.state);
    }
};
