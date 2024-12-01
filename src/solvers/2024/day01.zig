const std = @import("std");
const log = std.log;

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day01.txt");

    const part1 = try distance(allocator, content, false);
    std.debug.print("Part 1 -> {d}\n", .{part1});

    const part2 = try distance(allocator, content, true);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn distance(allocator: std.mem.Allocator, content: []const u8, is_weighted: bool) !i32 {
    var result: i32 = 0;
    var readIter = std.mem.tokenizeSequence(u8, content, "\n");

    var left = std.ArrayList(i32).init(allocator);
    var right = std.ArrayList(i32).init(allocator);

    var counter = std.AutoHashMap(i32, i32).init(allocator);

    while (readIter.next()) |line| {
        var lineIter = std.mem.tokenizeSequence(u8, line, " ");
        try left.append(try std.fmt.parseInt(i32, lineIter.next().?, 10));

        const r = try std.fmt.parseInt(i32, lineIter.next().?, 10);
        if (counter.contains(r)) {
            const v = counter.get(r) orelse unreachable;
            try counter.put(r, v + 1);
        } else {
            try counter.put(r, 1);
        }
        try right.append(r);
    }

    const l = try left.toOwnedSlice();
    std.mem.sort(i32, l, {}, comptime std.sort.asc(i32));
    const r = try right.toOwnedSlice();
    std.mem.sort(i32, r, {}, comptime std.sort.asc(i32));

    var i: usize = 0;
    while (true) : (i += 1) {
        if (i >= l.len or i >= r.len) {
            break;
        }
        const x = l[i];
        const y = r[i];

        if (is_weighted) {
            const numTimes: i32 = counter.get(x) orelse 0;
            result += @intCast(@abs(numTimes * x));
        } else {
            result += @intCast(@abs(y - x));
        }
    }

    return result;
}

test "part1 test" {
    const content =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    const result = distance(std.testing.allocator, content, false);
    try std.testing.expectEqual(@as(i32, 11), result);
}

test "part2 test" {
    const content =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    const result = distance(std.testing.allocator, content, true);
    try std.testing.expectEqual(@as(i32, 31), result);
}
