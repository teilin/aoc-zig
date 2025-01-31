const std = @import("std");

const HotSpring = struct {
    memo: std.StringHashMap(i64),
    patterns: std.ArrayList([]const u8),

    const Self = @This();

    fn recurse(self: *Self, s: []const u8) !i64 {
        if (s.len == 0) {
            return 1;
        }
        if (self.memo.get(s)) |r| {
            return r;
        }
        var sum: i64 = 0;

        for (self.patterns.items) |p| {
            if (std.mem.startsWith(u8, s, p)) {
                sum += try self.recurse(s[p.len..]);
            }
        }

        try self.memo.put(s, sum);

        return sum;
    }
};

pub fn solve(alloc: std.mem.Allocator) !void {
    const content = @embedFile("./data/day19.txt");
    const p1 = try part1(alloc, content);
    const p2 = try part2(alloc, content);
    std.debug.print("Part 1 -> {d}\nPart 2 -> {d}\n", .{ p1, p2 });
}

fn part1(alloc: std.mem.Allocator, content: []const u8) !i64 {
    const patterns_, const designs = splitOnce(content, "\n\n");
    const patterns = try stringsAny(patterns_, ", ", alloc);
    defer patterns.deinit();

    var memo = std.StringHashMap(i64).init(alloc);
    defer memo.deinit();

    var sum: i64 = 0;
    var iter = std.mem.tokenizeAny(u8, designs, "\n");
    var x = HotSpring{ .memo = memo, .patterns = patterns };
    while (iter.next()) |design| {
        const result = try x.recurse(design);
        if (result > 0) {
            sum += 1;
        }
    }
    return sum;
}

fn part2(alloc: std.mem.Allocator, content: []const u8) !i64 {
    const patterns_, const designs = splitOnce(content, "\n\n");
    const patterns = try stringsAny(patterns_, ", ", alloc);
    defer patterns.deinit();

    var memo = std.StringHashMap(i64).init(alloc);
    defer memo.deinit();

    var sum: i64 = 0;
    var iter = std.mem.tokenizeAny(u8, designs, "\n");
    var x = HotSpring{ .memo = memo, .patterns = patterns };
    while (iter.next()) |design| {
        sum += try x.recurse(design);
    }
    return sum;
}

pub fn splitOnce(s: []const u8, delimiter: []const u8) [2][]const u8 {
    const idx = std.mem.indexOf(u8, s, delimiter);
    if (idx == null) {
        return [2][]const u8{ s, "" };
    } else {}
    return [2][]const u8{ s[0..idx.?], s[idx.? + delimiter.len ..] };
}

pub fn stringsAny(s: []const u8, delimiters: []const u8, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var iter = std.mem.tokenizeAny(u8, s, delimiters);
    var l = std.ArrayList([]const u8).init(allocator);
    errdefer l.deinit();

    while (iter.next()) |v| {
        try l.append(v);
    }

    return l;
}

test "part1 test" {
    const content =
        \\r, wr, b, g, bwu, rb, gb, br
        \\brwrr
        \\bggr
        \\gbbr
        \\rrbgbr
        \\ubwu
        \\bwurrg
        \\brgr
        \\bbrgwb
    ;
    const p1 = try part1(std.testing.allocator, content);
    try std.testing.expectEqual(6, p1);
}

test "part2 test" {
    const content =
        \\r, wr, b, g, bwu, rb, gb, br
        \\brwrr
        \\bggr
        \\gbbr
        \\rrbgbr
        \\ubwu
        \\bwurrg
        \\brgr
        \\bbrgwb
    ;
    const p2 = try part2(std.testing.allocator, content);
    try std.testing.expectEqual(16, p2);
}
