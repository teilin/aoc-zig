const std = @import("std");

const Day01 = @import("./solvers/2025/day01.zig");
const Day02 = @import("./solvers/2025/day02.zig");
const Day03 = @import("./solvers/2025/day03.zig");
const Day04 = @import("./solvers/2025/day04.zig");
const Day05 = @import("./solvers/2025/day05.zig");
const Day06 = @import("./solvers/2025/day06.zig");
const Day08 = @import("./solvers/2025/day08.zig");
const Day09 = @import("./solvers/2025/day09.zig");
const Day10 = @import("./solvers/2025/day10.zig");
const Day11 = @import("./solvers/2025/day11.zig");
const Day12 = @import("./solvers/2025/day12.zig");

pub const Puzle2025 = struct {
    allocator: std.mem.Allocator,

    pub fn run(day: u64) !void {
        switch (day) {
            1 => {
                try Day01.solve();
            },
            2 => {
                try Day02.solve();
            },
            3 => {
                try Day03.solve();
            },
            4 => {
                try Day04.solve();
            },
            5 => {
                try Day05.solve();
            },
            6 => {
                try Day06.solve();
            },
            8 => {
                try Day08.solve();
            },
            9 => {
                try Day09.solve();
            },
            10 => {
                try Day10.solve();
            },
            11 => {
                try Day11.solve();
            },
            12 => {
                try Day12.solve();
            },
            else => {
                std.debug.print("No puzzel solver for day: {d}", .{day});
            },
        }
    }
};
