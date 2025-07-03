//! Create a scanning function given the rows and cols pins.

pub fn matrix(
    comptime Pin: type,
    rows: []const Pin,
    cols: []const Pin,
    comptime layout: Layout,
    comptime diode_direction: DiodeDirection,
    // wait between setting a pin, and reading the ones connected to it
    comptime delay: DelayFn,
) *const fn () Keys.State {
    if (layout.len != rows.len) {
        @compileError("layout size doesn't match number of rows");
    }
    validateLayout(layout);

    for (0.., layout) |r, row| {
        if (row.len != cols.len) {
            const msg = comptimePrint("row {d} of layout doesn't match number of cols", .{r});
            @compileError(msg);
        }
    }

    // TODO: check if this lines up with QMK's naming
    const outputs: []const Pin, const inputs: []const Pin = switch (diode_direction) {
        .row_col => .{ rows, cols },
        .col_row => .{ cols, rows },
    };

    return struct {
        fn scan() Keys.State {
            var keys_state: Keys.State = .initEmpty();

            for (0.., outputs) |i, output| {
                output.put(1);

                delay();

                for (0.., inputs) |j, input| {
                    const maybe_index = switch (diode_direction) {
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
                    const msg = comptimePrint("layout contains index ({d}) bigger than number of keys ({d})", .{ index, n_keys });
                    @compileError(msg);
                }

                if (seen.isSet(index)) {
                    const msg = comptimePrint("layout contains duplicate index ({d})", .{index});
                    @compileError(msg);
                }

                seen.set(index);
            }
        }
    }
}

//
// constants
//
const comptimePrint = std.fmt.comptimePrint;
const DelayFn = *const fn () void;
const DiodeDirection = types.DiodeDirection;
const Layout = types.Layout;

//
// imports
//
const std = @import("std");
const types = @import("types.zig");
const Keys = @import("Keys.zig");
