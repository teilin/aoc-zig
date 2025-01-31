const std = @import("std");

const H: usize = 7;
const W: usize = 5;
const V = @Vector(W, usize);

pub fn solve(alloc: std.mem.Allocator) !void {
    const content = @embedFile("./data/day25.txt");
    const p1 = try part1(alloc, content);
    std.debug.print("Part 1 -> {d}\nPart 2 -> {d}\n", .{ p1, 0 });
}

fn part1(alloc: std.mem.Allocator, content: []const u8) !u32 {
    var locks = std.ArrayList([W]usize).init(alloc);
    defer locks.deinit();

    var keys = std.ArrayList([W]usize).init(alloc);
    defer keys.deinit();

    var it_schematics = std.mem.splitSequence(u8, content, "\n\n");
    while (it_schematics.next()) |raw| {
        var it_row = std.mem.tokenizeScalar(u8, raw, '\n');
        const is_lock: bool = if (std.mem.eql(u8, it_row.peek().?, "#" ** W)) true else false;
        var schematic: [H][W]u8 = undefined;
        var row: usize = 0;
        while (it_row.next()) |row_schema| {
            for (row_schema, 0..) |c, col| schematic[row][col] = c;
            row += 1;
        }
        var heights: [W]usize = undefined;
        for (0..W) |col_s| {
            var height: usize = 0;
            for (0..H) |row_s| {
                if (schematic[row_s][col_s] == '#') height += 1;
            }
            heights[col_s] = height - 1;
        }
        if (is_lock) {
            try locks.append(heights);
        } else {
            try keys.append(heights);
        }
    }
    var ans: u32 = 0;
    for (locks.items) |lock| {
        for (keys.items) |key| {
            const lock_v: V = lock;
            const key_v: V = key;
            const is_overlap = @reduce(.Or, (lock_v + key_v) > @as(V, @splat(5)));
            if (!is_overlap) ans += 1;
        }
    }

    return ans;
}
