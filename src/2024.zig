const std = @import("std");

const Day01 = @import("./solvers/2024/day01.zig");
const Day02 = @import("./solvers/2024/day02.zig");

pub const Puzzel2024 = struct {
    allocator: std.mem.Allocator,

    pub fn run(allocator: std.mem.Allocator, day: u64) !void {
        switch (day) {
            1 => {
                try Day01.solve(allocator);
            },
            2 => {
                try Day02.solve(allocator);
            },
            else => {
                std.debug.print("No puzzel solver for day: {d}", .{day});
            },
        }
    }
};
