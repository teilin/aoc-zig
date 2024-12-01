//const std = @import("std");

pub const Puzzle = struct {
    Year: u64,
    Day: u64,

    pub fn init(year: u64, day: u64) !@This() {
        return .{
            .Year = year,
            .Day = day,
        };
    }
};
