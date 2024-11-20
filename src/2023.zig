const std = @import("std");
const model = @import("model.zig");

const day1 = @import("solvers/2023/Day01.zig");

pub const Puzzel2023 = struct {
    pub fn run(day: u64, filePath: []const u8) void {
        std.debug.print("2023", .{});
        switch (day) {
            1 => {
                day1.Day01.run(filePath);
            },
            else => {
                std.debug.print("No solution yet...", .{});
            },
        }
    }
};
