const std = @import("std");

pub fn solve(alloc: std.mem.Allocator) !void {
    const content = @embedFile("./data/day22.txt");
    //const p1 = try part1(content);
    const p2 = try part2(alloc, content);
    std.debug.print("Part 1 -> {d}\nPart 2 -> {d}\n", .{ 0, p2 });
}

fn part1(content: []const u8) !i64 {
    var line_iter = std.mem.tokenizeSequence(u8, content, "\n");
    var sum: i64 = 0;
    while (line_iter.next()) |line| {
        var secret = try std.fmt.parseInt(i64, line, 10);

        for (0..2000) |_| {
            secret = nextSecretNumber(secret);
        }

        sum += secret;
    }

    return sum;
}

const Seq = std.ArrayList(i64);
const Seq4 = [4]i64;

fn Set(Type: type) type {
    return std.AutoArrayHashMap(Type, void);
}

fn part2(alloc: std.mem.Allocator, content: []const u8) !i64 {
    const Diffs = @Vector(4, i8);

    var seen = Set(Diffs).init(alloc);
    defer seen.deinit();

    // Total number of bananas for the given diff sequence
    var bananas = std.AutoArrayHashMap(Diffs, i64).init(alloc);
    defer bananas.deinit();

    var line_it = std.mem.tokenizeScalar(u8, content, '\n');
    while (line_it.next()) |line| {
        seen.clearRetainingCapacity();

        var secret = try std.fmt.parseInt(i64, line, 10);

        var diff: Diffs = @splat(0);
        var prev: i8 = @intCast(@mod(secret, 10));

        for (0..2000) |i| {
            secret ^= secret << 6;
            secret = @mod(secret, 16777216);
            secret ^= secret >> 5;
            secret = @mod(secret, 16777216);
            secret ^= secret << 11;
            secret = @mod(secret, 16777216);

            const num: i8 = @intCast(@mod(secret, 10));
            if (i == 0) {
                prev = num;
                continue;
            }

            const d: i8 = prev - num;
            diff = @shuffle(i8, diff, undefined, @Vector(4, i32){ 1, 2, 3, 3 });
            diff[3] = d;
            prev = num;

            if (i > 3) {
                if (seen.contains(diff)) {
                    continue;
                }
                try seen.put(diff, {});

                (try bananas.getOrPutValue(diff, 0)).value_ptr.* += num;
            }
        }
    }

    var best: i64 = 0;
    var it = bananas.iterator();
    while (it.next()) |item| {
        best = @max(best, item.value_ptr.*);
    }

    return best;
}

fn nextSecretNumber(secretNumber: i64) i64 {
    var cpy: i64 = secretNumber;
    cpy = prune(mix(cpy * 64, cpy));
    cpy = prune(mix(@divFloor(cpy, 32), cpy));
    cpy = prune(mix(cpy * 2048, cpy));
    return cpy;
}

fn prune(num: i64) i64 {
    return @mod(num, 16777216);
}

fn mix(num_a: i64, num_b: i64) i64 {
    return num_a ^ num_b;
}

test "nextSeretNumber" {
    try std.testing.expectEqual(15887950, nextSecretNumber(123));
}
