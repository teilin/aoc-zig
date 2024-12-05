const std = @import("std");

const OrderingRule = struct {
    firstPage: []const u8,
    nextPage: []const u8,
};

const Prints = struct {
    rules: std.ArrayList(OrderingRule),
    manuals: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, content: []const u8) !@This() {
        var lineIter = std.mem.tokenizeSequence(u8, content, "\n");
        var rules = std.ArrayList(OrderingRule).init(allocator);
        var manuals = std.ArrayList([]const u8).init(allocator);
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
    const patrt1 = try validatePrintingOrders(allocator, content);
    std.debug.print("Part 1 -> {d}\n", .{patrt1});
}

fn validatePrintingOrders(allocator: std.mem.Allocator, content: []const u8) !u32 {
    const print = try Prints.init(allocator, content);
    defer print.deinit();

    var sum: u32 = 0;
    for (print.manuals.items) |m| {
        if (validateRule(m, print.rules.items)) {
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

fn safeParseInt(num: []const u8) u32 {
    return std.fmt.parseInt(u8, num, 10) catch |err| switch (err) {
        else => {
            return 0;
        },
    };
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
    try std.testing.expectEqual(143, validatePrintingOrders(std.testing.allocator, content));
}
