const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day07.txt");
    const solution = try traceBeams(gpa.allocator(), content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

/// Sends the beam down the manifold one row at a time, tracking how many
/// timelines are currently in each column.
///
/// Part 1 only cares whether a column has a beam at all, so it counts every
/// splitter that is reached by at least one timeline. Part 2 is the total
/// number of timelines once everything has left the manifold. Beams that
/// merge into the same column add their timeline counts together, which is
/// exactly what makes them collapse into one beam in part 1.
fn traceBeams(allocator: std.mem.Allocator, input: []const u8) !Answer {
    var lines = std.mem.tokenizeAny(u8, input, "\r\n");

    const first = lines.next() orelse return error.EmptyInput;
    const width = first.len;
    const start = std.mem.indexOfScalar(u8, first, 'S') orelse return error.MissingStart;

    var timelines = try allocator.alloc(u64, width);
    defer allocator.free(timelines);
    var next = try allocator.alloc(u64, width);
    defer allocator.free(next);

    @memset(timelines, 0);
    timelines[start] = 1;

    var splits: u64 = 0;
    // Timelines that split off the side of the manifold have finished their
    // journey too, so they still count in part 2.
    var exited_sideways: u64 = 0;

    while (lines.next()) |row| {
        if (row.len != width) return error.RaggedGrid;
        @memset(next, 0);

        for (timelines, 0..) |count, col| {
            if (count == 0) continue;
            switch (row[col]) {
                '^' => {
                    splits += 1;
                    if (col > 0) next[col - 1] += count else exited_sideways += count;
                    if (col + 1 < width) next[col + 1] += count else exited_sideways += count;
                },
                '.', 'S' => next[col] += count,
                else => return error.BadCell,
            }
        }
        std.mem.swap([]u64, &timelines, &next);
    }

    var total = exited_sideways;
    for (timelines) |count| total += count;

    return .{ .part1 = splits, .part2 = total };
}

const example =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 21), (try traceBeams(std.testing.allocator, example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 40), (try traceBeams(std.testing.allocator, example)).part2);
}

test "two splitters feeding the same column merge in part 1 but not part 2" {
    // Row 3: beams at cols 1 and 3 split; both send a beam into col 2.
    const grid =
        \\..S..
        \\..^..
        \\.^.^.
        \\.....
    ;
    const answer = try traceBeams(std.testing.allocator, grid);
    try std.testing.expectEqual(@as(u64, 3), answer.part1);
    // Timelines end up in cols 0, 2, 2, 4.
    try std.testing.expectEqual(@as(u64, 4), answer.part2);
}

test "a beam split off the edge still counts as a timeline" {
    const grid =
        \\S..
        \\^..
        \\...
    ;
    const answer = try traceBeams(std.testing.allocator, grid);
    try std.testing.expectEqual(@as(u64, 1), answer.part1);
    try std.testing.expectEqual(@as(u64, 2), answer.part2);
}
