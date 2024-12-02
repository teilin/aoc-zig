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
        var levels = std.ArrayList(i32).init(allocator);
        while (words.next()) |w| {
            const iw = std.fmt.parseInt(i32, w, 10);
            try levels.append(iw);
        }

        if (!has_damper) {
            if (isSafe(levels, false, 0)) {
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
}

fn isSafe(levels: []const i32, skip: bool, skip_id: usize) bool {
    var increment: bool = false;
    var decrement: bool = false;
    var diffCheck: bool = true;
    var prev: ?i32 = null;
    for (0.., levels) |index, level| {
        if (skip and index == skip_id) {
            continue;
        }
        if (prev) |p| {
            const diff = @abs(level - p);
            if (level - p < 0) {
                decrement = true;
            }
            if (level - p > 0) {
                increment = true;
            }
            if (diff > 0 and diff <= 3) {
                diffCheck = true;
            }
        }
        prev = level;
    }
    return diffCheck and !(increment and decrement);
}

fn safeReportAnalyzer(content: []const u8, has_problem_damper: bool) !i32 {
    var safeReports: i32 = 0;
    var readIter = std.mem.tokenizeSequence(u8, content, "\n");

    while (readIter.next()) |line| {
        var lineIter = std.mem.tokenizeSequence(u8, line, " ");
        var prevLevel: ?i32 = null;
        var is_safe: bool = true;
        var isIncreasing: ?bool = null;
        while (lineIter.next()) |level| {
            const levelInt: i32 = try std.fmt.parseInt(i32, level, 10);
            if (prevLevel) |pl| {
                if (isIncreasing == null) {
                    if (pl > levelInt) {
                        isIncreasing = false;
                    } else {
                        isIncreasing = true;
                    }
                }
                const diff = @abs(levelInt - pl);
                if (isIncreasing) |inc| {
                    if (inc) {
                        if (pl > levelInt) {
                            is_safe = false;
                        }
                    } else {
                        if (pl < levelInt) {
                            is_safe = false;
                        }
                    }
                }
                if (diff > 0 and diff <= 3) {
                    prevLevel = levelInt;
                } else {
                    is_safe = false;
                }
            } else {
                prevLevel = levelInt;
            }
            prevLevel = levelInt;
        }
        if (has_problem_damper) {}
        if (is_safe) {
            safeReports += 1;
        }
    }

    return safeReports;
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
    try std.testing.expectEqual(2, safeReportAnalyzer(content, false));
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
    try std.testing.expectEqual(4, safeReportAnalyzer(content, true));
}
