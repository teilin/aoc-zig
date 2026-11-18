const std = @import("std");

const Answer = struct { part1: u32, part2: u32 };

pub fn solve() !void {
    const content = @embedFile("./data/day01.txt");
    const solution = try dialPassZero(content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

fn dialPassZero(input: []const u8) !Answer {
    var dial: i32 = 50;
    var part1: u32 = 0;
    var part2: u32 = 0;

    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        const dist = try std.fmt.parseInt(i32, line[1..], 10);

        // Turning left from p is the mirror image of turning right from (100 - p) % 100,
        // so both directions become: "how many multiples of 100 do we reach counting up?"
        const start: i32 = switch (line[0]) {
            'R' => dial,
            'L' => @mod(100 - dial, 100),
            else => return error.BadDirection,
        };
        part2 += @intCast(@divFloor(start + dist, 100));

        const step = if (line[0] == 'L') -dist else dist;
        dial = @mod(dial + step, 100);
        if (dial == 0) part1 += 1;
    }
    return .{ .part1 = part1, .part2 = part2 };
}

test "example" {
    const example =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const answer = try dialPassZero(example);
    try std.testing.expectEqual(@as(u32, 3), answer.part1);
    try std.testing.expectEqual(@as(u32, 6), answer.part2);
}

test "R1000 from 50 hits zero ten times" {
    try std.testing.expectEqual(@as(u32, 10), (try dialPassZero("R1000")).part2);
}

test "starting on zero doesn't count as a hit" {
    try std.testing.expectEqual(@as(u32, 1), (try dialPassZero("L50\nL5")).part2);
    try std.testing.expectEqual(@as(u32, 2), (try dialPassZero("L50\nL100")).part2);
}
