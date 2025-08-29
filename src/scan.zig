//! Create a scanning function given the rows and cols pins.

const Options = struct {
    diode_direction: DiodeDirection,
    /// time between setting a pin as output and iterating the inputs connected to it
    output_delay: Time,
};

pub fn matrix(
    comptime Pin: type,
    comptime rows: []const Pin,
    comptime cols: []const Pin,
    comptime layout: Layout,
    comptime options: Options,
) Keyboard.Portability.ScanKeys {
    if (layout.len != rows.len) {
        errors.fatal(
            "layout size ({}) doesn't match number of rows ({})",
            .{
                layout.len,
                rows.len,
            },
        );
    }

    validateLayout(layout);

    for (0.., layout) |r, row| {
        if (row.len != cols.len) {
            errors.fatal("row {d} of layout doesn't match number of cols", .{r});
        }
    }

    // TODO: check if this lines up with QMK's naming
    const outputs: []const Pin, const inputs: []const Pin = switch (options.diode_direction) {
        .row_col => .{ rows, cols },
        .col_row => .{ cols, rows },
    };

    return struct {
        fn scan(keyboard: *const Keyboard) keys.State {
            var keys_state: keys.State = .initEmpty();

            for (0.., outputs) |i, output| {
                output.put(1);

                wait(keyboard.portability.getTime, options.output_delay);

                for (0.., inputs) |j, input| {
                    const maybe_index = switch (options.diode_direction) {
                        .row_col => layout[i][j],
                        .col_row => layout[j][i],
                    };

                    if (maybe_index) |index| {
                        const value: u1 = input.read();
                        keys_state.setValue(index, value != 0);
                    }
                }

                output.put(0);
            }

            return keys_state;
        }
    }.scan;
}

fn validateLayout(comptime layout: Layout) void {
    var n_keys: usize = 0;
    for (layout) |row| {
        for (row) |maybe_index| {
            if (maybe_index != null) {
                n_keys += 1;
            }
        }
    }

    var seen: std.StaticBitSet(n_keys) = .initEmpty();
    for (layout) |row| {
        for (row) |maybe_index| {
            if (maybe_index) |index| {
                if (index >= n_keys) {
                    errors.fatal(
                        "layout contains index ({d}) bigger than number of keys ({d})",
                        .{
                            index,
                            n_keys,
                        },
                    );
                }

                if (seen.isSet(index)) {
                    errors.fatal(
                        "layout contains duplicate index ({d})",
                        .{
                            index,
                        },
                    );
                }

                seen.set(index);
            }
        }
    }
}

fn wait(getTime: Keyboard.Portability.GetTime, duration: Time) void {
    if (duration.toMillis() == 0) {
        return;
    }

    const start = getTime();
    const deadline = start.add(duration);

    while (getTime().lt(deadline)) {}
}

const std = @import("std");
const errors = @import("errors.zig");
const DiodeDirection = @import("types.zig").DiodeDirection;
const Keyboard = @import("Keyboard.zig");
const keys = @import("keys.zig");
const Layout = @import("types.zig").Layout;
const Time = @import("time.zig").Time;
