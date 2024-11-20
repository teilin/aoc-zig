const std = @import("std");

pub const Day01 = struct {
    pub fn run(filePath: []const u8) void {
        std.debug.print("Hello world, {s}", .{filePath});
    }
};
