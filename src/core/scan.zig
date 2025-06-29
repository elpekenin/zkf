//! Create a scanning function given the rows and cols pins.

pub fn matrix(
    comptime Pin: type,
    rows: []const Pin,
    cols: []const Pin,
    comptime layout: Layout,
    comptime diode_direction: DiodeDirection,
    // wait between setting a pin, and reading the ones connected to it
    comptime delay: DelayFn,
) *const fn () KeyStateFromLayout(layout) {
    if (layout.len != rows.len) {
        @compileError("Size of layout doesn't match number of rows");
    }

    for (0.., layout) |r, row| {
        if (row.len != cols.len) {
            const msg = comptimePrint("Row {d} of layout doesn't match number of cols", .{r});
            @compileError(msg);
        }
    }

    const KeysState = KeyStateFromLayout(layout);

    // TODO: check if this lines up with QMK's naming
    const output: []const Pin, const input: []const Pin = switch (diode_direction) {
        .row_col => .{ rows, cols },
        .col_row => .{ cols, rows },
    };

    return struct {
        fn scan() KeysState {
            var keys_state: KeysState = .initEmpty();

            for (0.., output) |i, out| {
                out.put(1);

                delay();

                for (0.., input) |j, in| {
                    const maybe_index = switch (diode_direction) {
                        .row_col => layout[i][j],
                        .col_row => layout[j][i],
                    };

                    if (maybe_index) |index| {
                        const value: u1 = in.read();
                        keys_state.setValue(index, value != 0);
                    }
                }

                out.put(0);
            }

            return keys_state;
        }
    }.scan;
}

const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;

const types = @import("types.zig");
const DelayFn = *const fn () void;
const DiodeDirection = types.DiodeDirection;
const KeyStateFromLayout = types.KeyStateFromLayout;
const Layout = types.Layout;
