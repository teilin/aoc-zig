const std = @import("std");

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day07.txt");
    const part1 = try calibration(allocator, content, 2);
    std.debug.print("Part 1 -> {d}\n", .{part1});
    const part2 = try calibration(allocator, content, 3);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn calibration(allocator: std.mem.Allocator, content: []const u8, tgt: usize) !u64 {
    var line_iter = std.mem.tokenizeSequence(u8, content, "\n");

    var sum: u64 = 0;
    while (line_iter.next()) |line| {
        var num_iter = std.mem.tokenizeSequence(u8, line, " ");
        const firstVal = num_iter.next().?;
        const val = try std.fmt.parseInt(u64, firstVal[0 .. firstVal.len - 1], 10);

        var list = std.ArrayList(u64).init(allocator);
        defer list.deinit();

        while (num_iter.next()) |num_str| {
            const n = try std.fmt.parseInt(u64, num_str, 10);
            try list.append(n);
        }

        const limit = try std.math.powi(usize, tgt, list.items.len);

        for (0..limit) |iter| {
            var acc = list.items[0];
            for (list.items[1..], 0..) |n, idx| {
                const op = (iter / (try std.math.powi(usize, tgt, idx))) % tgt;
                if (op == 0) acc += n;
                if (op == 1) acc *= n;
                if (op == 2) {
                    var cp = n;
                    var cnt: u64 = 1;
                    while (cp >= 10) : (cnt += 1) cp /= 10;
                    acc = acc * (try std.math.powi(u64, 10, cnt)) + n;
                }
            }
            if (acc > val) continue;
            if (acc == val) {
                sum += val;
                break;
            }
        }
    }
    return sum;
}

test "part1 test" {
    const content =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    try std.testing.expectEqual(3749, calibration(std.testing.allocator, content, 2));
}

test "part2 test" {
    const content =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    try std.testing.expectEqual(11387, calibration(std.testing.allocator, content, 3));
}
