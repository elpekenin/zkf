const std = @import("std");
const zkf = @import("zkf");

const Layout = []const []const ?usize;

const DiodeDirection = enum {
    row_col,
    col_row,
};

const Options = struct {
    diode_direction: DiodeDirection,
    output_delay: zkf.Time,
};

pub fn matrix(
    comptime Pin: type,
    comptime rows: []const Pin,
    comptime cols: []const Pin,
    comptime layout: Layout,
    comptime options: Options,
) zkf.Portability.ScanKeys {
    // validation
    comptime {
        if (layout.len != rows.len) {
            std.debug.panic(
                "layout size ({}) doesn't match number of rows ({})",
                .{
                    layout.len,
                    rows.len,
                },
            );
        }

        validateLayout(layout);

        for (layout, 0..) |row, row_index| {
            if (row.len != cols.len) {
                std.debug.panic("row {} of layout doesn't match number of cols", .{row_index});
            }
        }
    }

    const outputs: []const Pin, const inputs: []const Pin = switch (options.diode_direction) {
        .row_col => .{ rows, cols },
        .col_row => .{ cols, rows },
    };

    return struct {
        fn scan(keyboard: *const zkf.Keyboard) zkf.keys.State {
            var keys_state: zkf.keys.State = .initEmpty();

            for (0.., outputs) |i, output| {
                output.put(1);

                keyboard.sleep(options.output_delay);

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
    comptime {
        var n_keys: usize = 0;
        for (layout) |row| {
            for (row) |maybe_index| {
                if (maybe_index != null) {
                    n_keys += 1;
                }
            }
        }

        if (n_keys > zkf.keys.max) {
            @compileError("too many keys");
        }

        var seen: std.StaticBitSet(n_keys) = .initEmpty();
        for (layout) |row| {
            for (row) |maybe_index| {
                if (maybe_index) |index| {
                    if (index >= n_keys) {
                        std.debug.panic("layout index ({}) out of bounds (0-{})", .{ index, n_keys - 1 });
                    }

                    if (seen.isSet(index)) {
                        std.debug.panic("layout index ({}) appears twice in layout", .{index});
                    }

                    seen.set(index);
                }
            }
        }
    }
}
