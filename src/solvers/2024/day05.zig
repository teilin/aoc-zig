const std = @import("std");

const OrderingRule = struct {
    firstPage: []const u8,
    nextPage: []const u8,
};

const Prints = struct {
    rules: std.array_list.Managed(OrderingRule),
    manuals: std.array_list.Managed([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, content: []const u8) !@This() {
        var lineIter = std.mem.tokenizeSequence(u8, content, "\n");
        var rules = std.array_list.Managed(OrderingRule).init(allocator);
        var manuals = std.array_list.Managed([]const u8).init(allocator);
        while (lineIter.next()) |line| {
            const pipe = std.mem.indexOf(u8, line, "|");
            if (pipe) |pipeIndex| {
                //const f: u32 = try std.fmt.parseInt(u32, line[0..pipeIndex], 10);
                //const l: u32 = try std.fmt.parseInt(u32, line[pipeIndex + 1 .. line.len], 10);
                //std.debug.print("\nFirst {d} Last {d}", .{ f, l });
                try rules.append(.{ .firstPage = line[0..pipeIndex], .nextPage = line[pipeIndex + 1 .. line.len] });
            } else {
                try manuals.append(line);
            }
        }
        return .{
            .allocator = allocator,
            .rules = rules,
            .manuals = manuals,
        };
    }

    pub fn deinit(self: @This()) void {
        self.manuals.deinit();
        self.rules.deinit();
    }
};

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day05.txt");
    const patrt1 = try validatePrintingOrders(allocator, content, false);
    std.debug.print("Part 1 -> {d}\n", .{patrt1});
    const part2 = try part2Solution(content);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn validatePrintingOrders(allocator: std.mem.Allocator, content: []const u8, includeCorrected: bool) !u32 {
    const print = try Prints.init(allocator, content);
    defer print.deinit();

    var sum: u32 = 0;
    for (print.manuals.items) |m| {
        if (validateRule(m, print.rules.items)) {
            if (!includeCorrected)
                sum += findMiddle(m);
        }
    }

    return sum;
}

fn findMiddle(line: []const u8) u32 {
    const countElements = ((std.mem.count(u8, line, ",") + 1) / 2) + 1;
    var index: usize = 1;
    var iter = std.mem.tokenizeSequence(u8, line, ",");
    while (iter.next()) |n| {
        if (index == countElements) {
            return safeParseInt(n);
        } else {
            index += 1;
        }
    }

    return 0;
}

fn validateRule(print: []const u8, rules: []OrderingRule) bool {
    var isValid: bool = true;
    for (rules) |rule| {
        const firstIndex = std.mem.indexOf(u8, print, rule.firstPage);
        const lastIndex = std.mem.indexOf(u8, print, rule.nextPage);
        if (firstIndex) |fi| {
            if (lastIndex) |li| {
                if (li < fi) {
                    isValid = false;
                }
            }
        }
    }
    return isValid;
}

fn findBrakingRule(print: []const u8, rules: []OrderingRule) ?OrderingRule {
    for (rules) |rule| {
        const firstIndex = std.mem.indexOf(u8, print, rule.firstPage);
        const lastIndex = std.mem.indexOf(u8, print, rule.nextPage);
        if (firstIndex) |fi| {
            if (lastIndex) |li| {
                if (li < fi) {
                    return rule;
                }
            }
        }
    }
    return null;
}

fn safeParseInt(num: []const u8) u32 {
    return std.fmt.parseInt(u8, num, 10) catch |err| switch (err) {
        else => {
            return 0;
        },
    };
}

inline fn parseRules(rules: []const u8) ![100][100]bool {
    var edge: [100][100]bool = [_][100]bool{.{false} ** 100} ** 100;

    var it = std.mem.tokenizeScalar(u8, rules, '\n');
    while (it.next()) |line| {
        const x = try std.fmt.parseInt(u8, line[0..2], 10);
        const y = try std.fmt.parseInt(u8, line[3..5], 10);

        edge[y][x] = true;
    }

    return edge;
}

fn part2Solution(input: []const u8) !u32 {
    const l = std.mem.indexOf(u8, input, "\n\n").?;
    const edge = try parseRules(input[0..l]);

    // use BoundedArray?
    var nums: [100]u8 = undefined;
    var sum: u32 = 0;

    var it = std.mem.tokenizeScalar(u8, input[l + 2 ..], '\n');
    while (it.next()) |line| {
        const n = (line.len + 1) / 3;
        var valid: bool = true;

        for (0..n) |i| {
            const x = try std.fmt.parseInt(u8, line[i * 3 .. i * 3 + 2], 10);
            nums[i] = x;
            for (nums[0..i], 0..) |y, j| {
                if (edge[y][x]) {
                    valid = false;
                    std.mem.rotate(u8, nums[j .. i + 1], i - j);
                    break;
                }
            }
        }

        if (!valid) sum += nums[n / 2];
    }

    return sum;
}

test "part1 test" {
    const content =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;
    try std.testing.expectEqual(143, validatePrintingOrders(std.testing.allocator, content, false));
}

test "part2 test" {
    const content =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;
    try std.testing.expectEqual(123, part2Solution(content));
}
