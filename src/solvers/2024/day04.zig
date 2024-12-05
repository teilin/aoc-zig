const std = @import("std");

pub fn solve() !void {
    const content = @embedFile("./data/day04.txt");
    const part1 = try wordSearch(content, "XMAS");
    std.debug.print("Part 1 -> {d}", .{part1});
    const part2 = try xmasShape(content);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn countStrides(haystack: []const u8, needle: []const u8, stride: usize) usize {
    var found: usize = 0;

    outer: for (0..haystack.len - (needle.len - 1) * stride) |i| {
        for (0.., needle) |j, c| {
            if (haystack[i + j * stride] != c)
                continue :outer;
        }
        found += 1;
    }

    return found;
}

fn wordSearch(content: []const u8, searchTerm: []const u8) !usize {
    const numLines = std.mem.indexOfScalar(u8, content, '\n').? + 1;
    var count: usize = 0;
    inline for (.{ 1, numLines, numLines - 1, numLines + 1 }) |stride| {
        count += countStrides(content, searchTerm, stride);
        count += countStrides(content, "SAMX", stride);
    }
    return count;
}

fn xmasShape(content: []const u8) !usize {
    const lines = std.mem.indexOfScalar(u8, content, '\n').? + 1;
    var count: usize = 0;

    for (lines + 1..content.len - lines - 1) |i| {
        if (i % lines == 0 or i % lines == lines - 1)
            continue;
        if (content[i] != 'A')
            continue;
        const c0 = content[i - lines - 1];
        const c1 = content[i + lines + 1];
        if (!((c0 == 'M' and c1 == 'S') or (c0 == 'S' and c1 == 'M')))
            continue;

        const c2 = content[i - lines + 1];
        const c3 = content[i + lines - 1];
        if (!((c2 == 'M' and c3 == 'S') or (c2 == 'S' and c3 == 'M')))
            continue;

        count += 1;
    }

    return count;
}

test "part1 test" {
    const content =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    try std.testing.expectEqual(18, wordSearch(content, "XMAS"));
}

test "part2 test" {
    const content =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    try std.testing.expectEqual(9, xmasShape(content));
}
