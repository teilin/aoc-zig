const std = @import("std");
const model = @import("model.zig");

const Puzzel2023 = @import("2023.zig");

pub const Solver = struct {
    pub fn init(puzzel: model.Puzzle) void {
        switch (puzzel.Year) {
            2023 => {
                Puzzel2023.Puzzel2023.run(puzzel.Day, puzzel.FilePath);
            },
            else => {
                std.debug.print("No puzzels yet", .{});
            },
        }
    }
};
