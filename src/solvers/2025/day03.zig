const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    const content = @embedFile("./data/day03.txt");
    const solution = try totalJoltage(content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

fn totalJoltage(input: []const u8) !Answer {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var banks = std.mem.tokenizeAny(u8, input, "\r\n");
    while (banks.next()) |bank| {
        part1 += try maxJoltage(bank, 2);
        part2 += try maxJoltage(bank, 12);
    }
    return .{ .part1 = part1, .part2 = part2 };
}

/// Largest number formed by picking `count` digits from `bank` in order.
///
/// Greedy: for each output digit, take the largest digit we can still pick
/// while leaving enough batteries after it for the remaining digits. On ties
/// take the leftmost, so the most batteries are left for later.
fn maxJoltage(bank: []const u8, count: usize) !u64 {
    if (bank.len < count) return error.BankTooSmall;

    var joltage: u64 = 0;
    var start: usize = 0;
    for (0..count) |picked| {
        const remaining_after = count - picked - 1;
        const window = bank[start .. bank.len - remaining_after];

        var best: usize = 0;
        for (window, 0..) |c, i| {
            if (c < '0' or c > '9') return error.BadDigit;
            if (c > window[best]) best = i;
        }

        joltage = joltage * 10 + (window[best] - '0');
        start += best + 1;
    }
    return joltage;
}

const example =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 357), (try totalJoltage(example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 3121910778619), (try totalJoltage(example)).part2);
}

test "max joltage per bank, two batteries" {
    try std.testing.expectEqual(@as(u64, 98), try maxJoltage("987654321111111", 2));
    try std.testing.expectEqual(@as(u64, 89), try maxJoltage("811111111111119", 2));
    try std.testing.expectEqual(@as(u64, 78), try maxJoltage("234234234234278", 2));
    try std.testing.expectEqual(@as(u64, 92), try maxJoltage("818181911112111", 2));
}

test "max joltage per bank, twelve batteries" {
    try std.testing.expectEqual(@as(u64, 987654321111), try maxJoltage("987654321111111", 12));
    try std.testing.expectEqual(@as(u64, 811111111119), try maxJoltage("811111111111119", 12));
    try std.testing.expectEqual(@as(u64, 434234234278), try maxJoltage("234234234234278", 12));
    try std.testing.expectEqual(@as(u64, 888911112111), try maxJoltage("818181911112111", 12));
}
