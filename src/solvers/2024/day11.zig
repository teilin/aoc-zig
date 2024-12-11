const std = @import("std");

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day11.txt");
    const p1 = try stones(allocator, content, 25);
    std.debug.print("Part 1 -> {d}\n", .{p1});
    const p2 = try stones(allocator, content, 75);
    std.debug.print("Part 2 -> {d}\n", .{p2});
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

fn stones(allocator: std.mem.Allocator, content: []const u8, rounds: usize) !usize {
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
    try std.testing.expectEqual(55312, stones(std.testing.allocator, content, 25));
}
