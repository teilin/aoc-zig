const std = @import("std");

const Day01 = @import("./solvers/2024/day01.zig");
const Day02 = @import("./solvers/2024/day02.zig");
const Day03 = @import("./solvers/2024/day03.zig");
const Day04 = @import("./solvers/2024/day04.zig");
const Day05 = @import("./solvers/2024/day05.zig");
const Day06 = @import("./solvers/2024/day06.zig");
const Day07 = @import("./solvers/2024/day07.zig");
const Day08 = @import("./solvers/2024/day08.zig");
const Day09 = @import("./solvers/2024/day09.zig");
const Day10 = @import("./solvers/2024/day10.zig");
const Day11 = @import("./solvers/2024/day11.zig");
const Day12 = @import("./solvers/2024/day12.zig");
const Day13 = @import("./solvers/2024/day13.zig");
const Day14 = @import("./solvers/2024/day14.zig");
const Day15 = @import("./solvers/2024/day15.zig");
const Day16 = @import("./solvers/2024/day16.zig");
const Day17 = @import("./solvers/2024/day17.zig");
const Day18 = @import("./solvers/2024/day18.zig");
const Day19 = @import("./solvers/2024/day19.zig");
const Day20 = @import("./solvers/2024/day20.zig");
const Day21 = @import("./solvers/2024/day21.zig");
const Day22 = @import("./solvers/2024/day22.zig");
const Day23 = @import("./solvers/2024/day23.zig");
const Day24 = @import("./solvers/2024/day24.zig");
const Day25 = @import("./solvers/2024/day25.zig");

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
            8 => {
                try Day08.solve();
            },
            9 => {
                try Day09.solve(allocator);
            },
            10 => {
                try Day10.solve();
            },
            11 => {
                try Day11.solve();
            },
            12 => {
                try Day12.solve(allocator);
            },
            13 => {
                try Day13.solve(allocator);
            },
            14 => {
                try Day14.solve(allocator);
            },
            15 => {
                try Day15.solve(allocator);
            },
            16 => {
                try Day16.solve(allocator);
            },
            17 => {
                try Day17.solve();
            },
            18 => {
                try Day18.solve(allocator);
            },
            19 => {
                try Day19.solve(allocator);
            },
            20 => {
                try Day20.solve(allocator);
            },
            21 => {
                try Day21.solve();
            },
            22 => {
                try Day22.solve(allocator);
            },
            23 => {
                try Day23.solve(allocator);
            },
            24 => {
                try Day24.solve();
            },
            25 => {
                try Day25.solve(allocator);
            },
            else => {
                std.debug.print("No puzzel solver for day: {d}", .{day});
            },
        }
    }
};
