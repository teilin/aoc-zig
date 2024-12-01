const std = @import("std");
const model = @import("model.zig");

const Puzzel2024 = @import("2024.zig").Puzzel2024;

pub const Solver = struct {
    pub fn init(allocator: std.mem.Allocator, puzzel: model.Puzzle) !void {
        switch (puzzel.Year) {
            2024 => {
                try Puzzel2024.run(allocator, puzzel.Day);
            },
            else => {
                std.debug.print("No puzzels yet", .{});
            },
        }
    }
};
