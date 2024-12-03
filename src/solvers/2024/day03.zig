const std = @import("std");

pub fn solve() !void {
    const content = @embedFile("./data/day03.txt");
    const part1 = try mulMachine(content);
    std.debug.print("Part 1 -> {d}\n", .{part1});
}

fn mulMachine(content: []const u8) !i64 {
    var mulIter = std.mem.tokenizeSequence(u8, content, "mul(");

    var sum: i64 = 0;
    while (mulIter.next()) |mul| {
        if (mul.len >= 4) {
            const index: ?usize = std.mem.indexOf(u8, mul, ")");
            if (index) |i| {
                const subStr = mul[0..i];
                const sepIndex = std.mem.indexOf(u8, subStr, ",");
                if (sepIndex) |si| {
                    if (safeParseInt(subStr[0..si])) |first| {
                        if (safeParseInt(subStr[si + 1 .. subStr.len])) |last| {
                            sum += (first * last);
                        }
                    }
                }
            }
        }
    }
    return sum;
}

fn safeParseInt(str: []const u8) ?i64 {
    return std.fmt.parseInt(i64, str, 10) catch |err| switch (err) {
        else => {
            return null;
        },
    };
}

test "part1 test" {
    const content =
        \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
    ;
    try std.testing.expectEqual(161, mulMachine(content));
}
