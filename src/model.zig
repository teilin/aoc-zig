//const std = @import("std");

pub const Puzzle = struct {
    Year: u64,
    Day: u64,
    FilePath: []const u8,

    pub fn init(year: u64, day: u64, filePath: []const u8) !@This() {
        return .{
            .Year = year,
            .Day = day,
            .FilePath = filePath,
        };
    }
};
