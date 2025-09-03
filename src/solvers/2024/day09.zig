const std = @import("std");

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day09.txt");
    const trimmed = std.mem.trim(u8, content, "\n");
    const part1 = try defragment(allocator, trimmed);
    std.debug.print("Part 1 -> {d}\n", .{part1});
    const part2 = try fileMove(allocator, trimmed);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn defragment(allocator: std.mem.Allocator, content: []const u8) !usize {
    var fragments = std.array_list.Managed(?usize).init(allocator);
    defer fragments.deinit();

    var iter = std.mem.window(u8, content, 2, 2);
    var index: usize = 0;
    while (iter.next()) |w| : (index += 1) {
        const b = try std.fmt.charToDigit(w[0], 10);
        const buf = [_]?usize{index} ** 9;
        try fragments.appendSlice(buf[0..b]);

        if (w.len == 1) break;

        const f = try std.fmt.charToDigit(w[1], 10);
        const bufn = [_]?usize{null} ** 9;
        try fragments.appendSlice(bufn[0..f]);
    }

    while (true) {
        const index_empty = std.mem.indexOf(?usize, fragments.items, &[_]?usize{null}).?;
        const index_last = std.mem.lastIndexOfNone(?usize, fragments.items, &[_]?usize{null}).?;
        if (index_empty > index_last) break;
        std.mem.swap(?usize, &fragments.items[index_last], &fragments.items[index_empty]);
    }

    var sum: usize = 0;
    for (0.., fragments.items) |i, p| {
        if (p == null) break;
        sum += p.? * i;
    }
    return sum;
}

fn fileMove(allocator: std.mem.Allocator, content: []const u8) !usize {
    var fragments = std.array_list.Managed(?usize).init(allocator);
    defer fragments.deinit();

    var iter = std.mem.window(u8, content, 2, 2);
    var index: usize = 0;
    while (iter.next()) |w| : (index += 1) {
        const b = try std.fmt.charToDigit(w[0], 10);
        const buf = [_]?usize{index} ** 9;
        try fragments.appendSlice(buf[0..b]);

        if (w.len == 1) break;

        const f = try std.fmt.charToDigit(w[1], 10);
        const bufn = [_]?usize{null} ** 9;
        try fragments.appendSlice(bufn[0..f]);
    }

    var block = index;
    while (block > 0) : (block -= 1) {
        const pos_left = std.mem.indexOf(?usize, fragments.items, &[_]?usize{block}).?;
        const pos_right = std.mem.lastIndexOf(?usize, fragments.items, &[_]?usize{block}).?;
        const len = pos_right - pos_left + 1;

        var empty_pos: ?usize = null;
        var slice = fragments.items[0..pos_left];
        while (true) {
            const empty_left = std.mem.indexOf(?usize, slice, &[_]?usize{null}) orelse break;
            const empty_len: usize = std.mem.indexOfNone(?usize, slice[empty_left..], &[_]?usize{null}) orelse slice.len - empty_left;
            if (empty_len >= len) {
                empty_pos = empty_left;
                break;
            }
            slice = slice[empty_left + empty_len ..];
        }
        if (empty_pos) |e| {
            std.mem.copyForwards(?usize, slice[e .. e + len], fragments.items[pos_left .. pos_left + len]);
            const bufn = [_]?usize{null} ** 9;
            std.mem.copyForwards(?usize, fragments.items[pos_left .. pos_left + len], bufn[0..len]);
            continue;
        }
    }
    var sum: usize = 0;
    for (0.., fragments.items) |i, p| {
        if (p == null) continue;
        sum += p.? * i;
    }
    return sum;
}

test "part1 test" {
    const content = "2333133121414131402";
    try std.testing.expectEqual(1928, defragment(std.testing.allocator, content));
}

test "part2 test" {
    const content = "2333133121414131402";
    try std.testing.expectEqual(2858, fileMove(std.testing.allocator, content));
}
