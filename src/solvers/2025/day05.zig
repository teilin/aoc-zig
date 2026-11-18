const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day05.txt");
    const solution = try freshIngredients(gpa.allocator(), content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

/// Inclusive range of fresh ingredient IDs.
const Range = struct {
    first: u64,
    last: u64,

    fn lessThan(_: void, a: Range, b: Range) bool {
        return a.first < b.first;
    }
};

fn freshIngredients(allocator: std.mem.Allocator, input: []const u8) !Answer {
    var ranges = std.array_list.Managed(Range).init(allocator);
    defer ranges.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');

    // First section: ranges, until the blank line.
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \r");
        if (line.len == 0) break;
        const dash = std.mem.indexOfScalar(u8, line, '-') orelse return error.BadRange;
        const range = Range{
            .first = try std.fmt.parseInt(u64, line[0..dash], 10),
            .last = try std.fmt.parseInt(u64, line[dash + 1 ..], 10),
        };
        if (range.first > range.last) return error.BadRange;
        try ranges.append(range);
    }

    const merged = mergeRanges(ranges.items);

    // Part 1: how many of the listed IDs fall inside a fresh range.
    var part1: u64 = 0;
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \r");
        if (line.len == 0) continue;
        const id = try std.fmt.parseInt(u64, line, 10);
        if (isFresh(merged, id)) part1 += 1;
    }

    // Part 2: merged ranges don't overlap, so just add up their sizes.
    var part2: u64 = 0;
    for (merged) |r| part2 += r.last - r.first + 1;

    return .{ .part1 = part1, .part2 = part2 };
}

/// Sorts `ranges` in place and merges overlapping or touching ones.
/// Returns the merged ranges, which reuse the front of the same slice.
fn mergeRanges(ranges: []Range) []Range {
    if (ranges.len == 0) return ranges;
    std.mem.sort(Range, ranges, {}, Range.lessThan);

    var out: usize = 0;
    for (ranges[1..]) |r| {
        const current = &ranges[out];
        if (r.first <= current.last +| 1) {
            current.last = @max(current.last, r.last);
        } else {
            out += 1;
            ranges[out] = r;
        }
    }
    return ranges[0 .. out + 1];
}

/// Binary search over sorted, non-overlapping ranges.
fn isFresh(merged: []const Range, id: u64) bool {
    var lo: usize = 0;
    var hi: usize = merged.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        const r = merged[mid];
        if (id < r.first) {
            hi = mid;
        } else if (id > r.last) {
            lo = mid + 1;
        } else {
            return true;
        }
    }
    return false;
}

const example =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 3), (try freshIngredients(std.testing.allocator, example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 14), (try freshIngredients(std.testing.allocator, example)).part2);
}

test "merge overlapping, touching and nested ranges" {
    var ranges = [_]Range{
        .{ .first = 10, .last = 14 },
        .{ .first = 3, .last = 5 },
        .{ .first = 6, .last = 7 }, // touches 3-5
        .{ .first = 11, .last = 12 }, // inside 10-14
        .{ .first = 20, .last = 20 },
    };
    const merged = mergeRanges(&ranges);
    try std.testing.expectEqualSlices(Range, &.{
        .{ .first = 3, .last = 7 },
        .{ .first = 10, .last = 14 },
        .{ .first = 20, .last = 20 },
    }, merged);

    try std.testing.expect(isFresh(merged, 3));
    try std.testing.expect(isFresh(merged, 7));
    try std.testing.expect(!isFresh(merged, 8));
    try std.testing.expect(isFresh(merged, 20));
    try std.testing.expect(!isFresh(merged, 21));
}
