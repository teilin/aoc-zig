const std = @import("std");

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day02.txt");
    const part1 = try safeReport(allocator, content, false);
    std.debug.print("Part 1 -> {d}\n", .{part1});
    const part2 = try safeReport(allocator, content, true);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn safeReport(allocator: std.mem.Allocator, content: []const u8, has_damper: bool) !i32 {
    var count: i32 = 0;
    var readIter = std.mem.tokenizeSequence(u8, content, "\n");
    while (readIter.next()) |line| {
        var words = std.mem.tokenizeSequence(u8, line, " ");
        var levels = std.array_list.Managed(i32).init(allocator);
        defer levels.deinit();
        while (words.next()) |w| {
            const iw = try std.fmt.parseInt(i32, w, 10);
            try levels.append(iw);
        }

        if (!has_damper) {
            if (isSafe(levels.items, false, 0)) {
                count += 1;
            }
        } else {
            for (0..levels.items.len) |i| {
                if (isSafe(levels.items, true, i)) {
                    count += 1;
                    break;
                }
            }
        }
    }
    return count;
}

fn isSafe(levels: []const i32, skip: bool, skip_index: usize) bool {
    var increment: bool = false;
    var decrement: bool = false;
    var diffCheck: bool = true;
    var prev: ?i32 = null;
    for (0.., levels) |index, level| {
        if (skip and index == skip_index) {
            continue;
        }
        if (prev) |p| {
            const diff = @abs(level - p);
            if ((level - p) < 0) {
                decrement = true;
            }
            if ((level - p) > 0) {
                increment = true;
            }
            if (diff < 1 or diff > 3) {
                diffCheck = false;
            }
        }
        prev = level;
    }
    return diffCheck and !(increment and decrement);
}

test "part1 test" {
    const content =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    try std.testing.expectEqual(2, safeReport(std.testing.allocator, content, false));
}

test "part2 test" {
    const content =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    try std.testing.expectEqual(4, safeReport(std.testing.allocator, content, true));
}
