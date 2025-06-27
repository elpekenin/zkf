//! Create a scanning function given the rows and cols pins.

fn rowColMatrix(comptime Pin: type, rows: []const Pin, cols: []const Pin, comptime layout: Layout) *const fn () KeyStateFromLayout(layout) {
    const KeysState = KeyStateFromLayout(layout);

    return struct {
        fn scan() KeysState {
            var keys_state: KeysState = .initEmpty();

            inline for (0.., rows) |r, row| {
                row.put(1);

                inline for (0.., cols) |c, col| {
                    const maybe_index = layout[r][c];
                    if (maybe_index) |index| {
                        const value: u1 = col.read();
                        keys_state.setValue(index, value != 0);
                    }
                }

                row.put(0);
            }

            return keys_state;
        }
    }.scan;
}

fn colRowMatrix(comptime Pin: type, rows: []const Pin, cols: []const Pin, comptime layout: Layout) *const fn () KeyStateFromLayout(layout) {
    const KeysState = KeyStateFromLayout(layout);

    return struct {
        fn scan() KeysState {
            var keys_state: KeysState = .initEmpty();

            inline for (0.., cols) |c, col| {
                col.put(1);

                inline for (0.., rows) |r, row| {
                    const maybe_index = layout[r][c];
                    if (maybe_index) |index| {
                        const value: u1 = row.read();
                        keys_state.setValue(index, value != 0);
                    }
                }

                col.put(0);
            }

            return keys_state;
        }
    }.scan;
}

// TODO: add (configurable) delays
pub fn matrix(comptime Pin: type, rows: []const Pin, cols: []const Pin, comptime layout: Layout, comptime direction: DiodeDirection) *const fn () KeyStateFromLayout(layout) {
    if (layout.len != rows.len) {
        @compileError("Size of layout doesn't match number of rows");
    }

    for (0.., layout) |r, row| {
        if (row.len != cols.len) {
            const msg = comptimePrint("Row {d} of layout doesn't match number of cols", .{r});
            @compileError(msg);
        }
    }

    return switch (direction) {
        .row_col => rowColMatrix(Pin, rows, cols, layout),
        .col_row => colRowMatrix(Pin, rows, cols, layout),
    };
}

const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;
const Struct = std.builtin.Type.Struct;

const types = @import("types.zig");
const DiodeDirection = types.DiodeDirection;
const KeyStateFromLayout = types.KeyStateFromLayout;
const Layout = types.Layout;
