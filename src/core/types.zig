/// type needed to index into some number of bits
/// eg: 32 -> u5, 4 -> u2, 10 -> u4
pub fn Index(comptime n_bits: usize) type {
    var n = std.math.log2(n_bits);
    if ((1 << n) < n_bits) {
        n += 1;
    }

    const info: Type = .{
        .int = .{
            .bits = n,
            .signedness = .unsigned,
        },
    };

    return @Type(info);
}

pub fn KeyStateFromLayout(comptime layout: Layout) type {
    var n_keys: usize = 0;

    for (layout) |row| {
        for (row) |maybe_index| {
            if (maybe_index != null) {
                n_keys += 1;
            }
        }
    }

    const Ret = std.StaticBitSet(n_keys);

    var seen: Ret = .initEmpty();
    for (layout) |row| {
        for (row) |maybe_index| {
            if (maybe_index) |index| {
                if (index >= n_keys) {
                    const msg = comptimePrint("Layout contains index ({d}) bigger than number of keys ({d})", .{ index, n_keys });
                    @compileError(msg);
                }

                if (seen.isSet(index)) {
                    const msg = comptimePrint("Layout contains duplicate index ({d})", .{index});
                    @compileError(msg);
                }

                seen.set(index);
            }
        }
    }

    return Ret;
}

const std = @import("std");
const keycodes = @import("keycodes.zig");

const comptimePrint = std.fmt.comptimePrint;
const Type = std.builtin.Type;

pub const DiodeDirection = enum {
    row_col,
    col_row,
};
pub const Keymap = []const []const keycodes.Keycode;
pub const Layout = []const []const ?usize;
