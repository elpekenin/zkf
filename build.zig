pub fn build(b: *std.Build) void {
    _ = b.addModule("zkf", .{
        .root_source_file = b.path("src/zkf.zig"),
    });
}

const std = @import("std");
