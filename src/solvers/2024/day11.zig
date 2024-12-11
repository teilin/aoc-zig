const std = @import("std");

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day11.txt");
    const p1 = try blinkingStones(allocator, content, 25);
    std.debug.print("Part 1 -> {d}\n", .{p1});
    const p2 = try part2(allocator, content, 75);
    std.debug.print("Part 2 -> {d}", .{p2});
}

fn blinkingStones(allocator: std.mem.Allocator, content: []const u8, rounds: usize) !u64 {
    var arr = std.ArrayList(usize).init(allocator);
    defer arr.deinit();

    var iter = std.mem.tokenizeSequence(u8, std.mem.trim(u8, content, "\n"), " ");
    while (iter.next()) |elm| {
        const num = try std.fmt.parseUnsigned(usize, elm, 10);
        try arr.append(num);
    }

    for (0..rounds) |_| {
        var i: usize = 0;
        while (i < arr.items.len) : (i += 1) {
            const stone = arr.items[i];
            const digits = if (stone == 0) 0 else std.math.log10(stone) + 1;
            if (stone == 0) {
                arr.items[i] = 1;
            } else if (digits % 2 == 0) {
                const half_digits = digits / 2;
                const divisor = std.math.pow(usize, 10, half_digits);
                const left = stone / divisor;
                const right = stone % divisor;
                arr.items[i] = left;
                try arr.insert(i + 1, right);
                i += 1;
            } else {
                arr.items[i] *= 2024;
            }
        }
    }

    return arr.items.len;
}

var cache = std.AutoArrayHashMap(@Vector(2, usize), usize).init(std.heap.page_allocator);

fn calculate(num: usize, n: usize) usize {
    const digits = if (num == 0) 0 else std.math.log10(num) + 1;
    if (n == 0) {
        return 1;
    }
    if (!cache.contains(.{ num, n })) {
        var v: usize = 0;
        if (num == 0) {
            v = calculate(1, n - 1);
        } else if (digits % 2 == 0) {
            const half_digits = digits / 2;
            const divisor = std.math.pow(usize, 10, half_digits);
            const left = num / divisor;
            const right = num % divisor;
            v += calculate(left, n - 1);
            v += calculate(right, n - 1);
        } else {
            v = calculate(num * 2024, n - 1);
        }
        cache.put(.{ num, n }, v) catch unreachable;
    }
    return cache.get(.{ num, n }).?;
}

fn part2(allocator: std.mem.Allocator, content: []const u8, rounds: usize) !usize {
    var iter = std.mem.tokenizeSequence(u8, std.mem.trim(u8, content, "\n"), " ");
    var arr = std.ArrayList(usize).init(allocator);
    defer arr.deinit();
    while (iter.next()) |num| {
        const n = try std.fmt.parseUnsigned(usize, num, 10);
        try arr.append(n);
    }
    var out: usize = 0;
    for (arr.items) |num| {
        out += calculate(num, rounds);
    }
    return out;
}

test "part1 test" {
    const content = "125 17";
    try std.testing.expectEqual(55312, blinkingStones(std.testing.allocator, content, 25));
}
