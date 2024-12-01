const std = @import("std");

pub fn solve() !void {
    const content = @embedFile("./data/day01.txt");

    const part1 = try calibration(content);
    std.debug.print("Part 1 -> {d}\n", .{part1});
    const part2 = try calibration2(content);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn calibration(content: []const u8) !u32 {
    var readIter = std.mem.tokenizeSequence(u8, content, "\n");

    var sum: u32 = 0;
    while (readIter.next()) |line| {
        var first: ?u8 = null;
        var last: ?u8 = null;
        for (line) |c| {
            if (c < '0' or c > '9') {
                continue;
            }
            const digit = c - '0';
            if (first == null) {
                first = digit;
            }
            last = digit;
        }
        sum += (10 * first.? + last.?);
    }

    return sum;
}

const NUMS = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn calibration2(content: []const u8) !u32 {
    var sum: u32 = 0;
    var readIter = std.mem.tokenizeSequence(u8, content, "\n");

    while (readIter.next()) |line| {
        var first: ?u8 = null;
        var last: ?u8 = null;

        for (line, 0..) |c, i| {
            var digit: ?u8 = null;
            if (c >= '0' and c <= '9') {
                digit = c - '0';
            } else {
                for (NUMS, 1..) |numStr, d| {
                    if (std.mem.startsWith(u8, line[i..], numStr)) {
                        digit = @intCast(d);
                    }
                }
            }

            if (digit) |d| {
                _ = d;
                if (first == null) {
                    first = digit;
                }
                last = digit;
            }
        }
        sum += (10 * first.? + last.?);
    }
    return sum;
}

test "part1 test" {
    const content =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    try std.testing.expectEqual(142, calibration(content));
}

test "part2 test" {
    const content =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    try std.testing.expectEqual(281, calibration2(content));
}
