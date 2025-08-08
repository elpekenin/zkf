pub const MAX = 256;
pub const Id = Index(MAX);
pub const State = std.StaticBitSet(MAX);

pub const Debouncer = struct {
    debounce: Time,
    state: State,
    timers: [MAX]Time,

    pub fn isPressed(self: *const Debouncer, key: Id) bool {
        return self.state.isSet(key);
    }

    pub fn init(debounce: Time) Debouncer {
        return .{
            .debounce = debounce,
            .state = .initEmpty(),
            .timers = @splat(.fromMillis(0)),
        };
    }

    pub fn update(self: *Debouncer, time: Time, state: State) State {
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

const std = @import("std");
const Index = @import("types.zig").Index;
const Time = @import("time.zig").Time;
