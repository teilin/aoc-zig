const std = @import("std");

const Day01 = @import("./solvers/2024/day01.zig");
const Day02 = @import("./solvers/2024/day02.zig");
const Day03 = @import("./solvers/2024/day03.zig");
const Day04 = @import("./solvers/2024/day04.zig");
const Day05 = @import("./solvers/2024/day05.zig");
const Day06 = @import("./solvers/2024/day06.zig");
const Day07 = @import("./solvers/2024/day07.zig");

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
            3 => {
                try Day03.solve();
            },
            4 => {
                try Day04.solve();
            },
            5 => {
                try Day05.solve(allocator);
            },
            6 => {
                try Day06.solve(allocator);
            },
            7 => {
                try Day07.solve(allocator);
            },
            else => {
                std.debug.print("No puzzel solver for day: {d}", .{day});
            },
        }
    }
};
