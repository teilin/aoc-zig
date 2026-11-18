const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    const content = @embedFile("./data/day02.txt");
    const solution = try sumInvalidIds(content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

fn sumInvalidIds(input: []const u8) !Answer {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var ranges = std.mem.tokenizeAny(u8, input, ", \r\n");
    while (ranges.next()) |range| {
        const dash = std.mem.indexOfScalar(u8, range, '-') orelse return error.BadRange;
        const first = try std.fmt.parseInt(u64, range[0..dash], 10);
        const last = try std.fmt.parseInt(u64, range[dash + 1 ..], 10);

        var id = first;
        while (id <= last) : (id += 1) {
            var buf: [20]u8 = undefined;
            const digits = std.fmt.bufPrint(&buf, "{d}", .{id}) catch unreachable;
            if (isRepeatedTwice(digits)) part1 += id;
            if (isRepeatedAtLeastTwice(digits)) part2 += id;
        }
    }
    return .{ .part1 = part1, .part2 = part2 };
}

/// Part 1: the digits are some sequence written exactly twice, e.g. 6464.
fn isRepeatedTwice(digits: []const u8) bool {
    return digits.len % 2 == 0 and hasPeriod(digits, digits.len / 2);
}

/// Part 2: the digits are some sequence written two or more times, e.g. 121212.
fn isRepeatedAtLeastTwice(digits: []const u8) bool {
    var period: usize = 1;
    while (period <= digits.len / 2) : (period += 1) {
        if (digits.len % period == 0 and hasPeriod(digits, period)) return true;
    }
    return false;
}

/// True when every digit equals the one `period` places before it,
/// i.e. the string is its first `period` digits repeated.
fn hasPeriod(digits: []const u8, period: usize) bool {
    for (period..digits.len) |i| {
        if (digits[i] != digits[i - period]) return false;
    }
    return true;
}

const example =
    \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
    \\1698522-1698528,446443-446449,38593856-38593862,565653-565659,
    \\824824821-824824827,2121212118-2121212124
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 1227775554), (try sumInvalidIds(example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 4174379265), (try sumInvalidIds(example)).part2);
}

test "repeated twice" {
    try std.testing.expect(isRepeatedTwice("55"));
    try std.testing.expect(isRepeatedTwice("6464"));
    try std.testing.expect(isRepeatedTwice("123123"));
    try std.testing.expect(!isRepeatedTwice("101"));
    try std.testing.expect(!isRepeatedTwice("111"));
    try std.testing.expect(!isRepeatedTwice("12341235"));
}

test "repeated at least twice" {
    try std.testing.expect(isRepeatedAtLeastTwice("12341234"));
    try std.testing.expect(isRepeatedAtLeastTwice("123123123"));
    try std.testing.expect(isRepeatedAtLeastTwice("1212121212"));
    try std.testing.expect(isRepeatedAtLeastTwice("1111111"));
    try std.testing.expect(!isRepeatedAtLeastTwice("7"));
    try std.testing.expect(!isRepeatedAtLeastTwice("101"));
    try std.testing.expect(!isRepeatedAtLeastTwice("1698525"));
}
