const std = @import("std");
const model = @import("model.zig");

const Puzzel2024 = @import("2024.zig").Puzzel2024;
const Puzzel2023 = @import("2023.zig").Puzzel2023;

pub const Solver = struct {
    pub fn init(allocator: std.mem.Allocator, puzzel: model.Puzzle) !void {
        switch (puzzel.Year) {
            2024 => {
                try Puzzel2024.run(allocator, puzzel.Day);
            },
            2023 => {
                try Puzzel2023.run(puzzel.Day);
            },
            else => {
                std.debug.print("No puzzels yet", .{});
            },
        }
    }
};
