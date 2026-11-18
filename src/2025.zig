const std = @import("std");

const Day01 = @import("./solvers/2025/day01.zig");

pub const Puzle2025 = struct {
    allocator: std.mem.Allocator,

    pub fn run(day: u64) !void {
        switch (day) {
            1 => {
                try Day01.solve();
            },
            else => {
                std.debug.print("No puzzel solver for day: {d}", .{day});
            },
        }
    }
};
