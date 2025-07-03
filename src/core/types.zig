/// type needed to index into some number of bits
/// eg: 32 -> `u5`, 4 -> `u2`, 10 -> `u4`
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

const Type = std.builtin.Type;

pub const DiodeDirection = enum {
    row_col,
    col_row,
};
pub const Layout = []const []const ?usize;

const std = @import("std");
