const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day04.txt");
    const solution = try accessibleRolls(gpa.allocator(), content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

/// A forklift can reach a roll when fewer than this many neighbours are rolls.
const max_neighbours = 4;

const Grid = struct {
    cells: []u8,
    width: usize,
    height: usize,

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Grid {
        var width: usize = 0;
        var height: usize = 0;
        var lines = std.mem.tokenizeAny(u8, input, "\r\n");
        while (lines.next()) |line| {
            if (width == 0) width = line.len;
            if (line.len != width) return error.RaggedGrid;
            height += 1;
        }

        const cells = try allocator.alloc(u8, width * height);
        lines.reset();
        var row: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            @memcpy(cells[row * width ..][0..width], line);
        }
        return .{ .cells = cells, .width = width, .height = height };
    }

    fn deinit(self: Grid, allocator: std.mem.Allocator) void {
        allocator.free(self.cells);
    }

    /// Indices of the (up to 8) cells around `idx`, written into `buf`.
    fn neighbours(self: Grid, idx: usize, buf: *[8]usize) []usize {
        const row = idx / self.width;
        const col = idx % self.width;
        var n: usize = 0;
        for ([_]isize{ -1, 0, 1 }) |dr| {
            for ([_]isize{ -1, 0, 1 }) |dc| {
                if (dr == 0 and dc == 0) continue;
                const r = @as(isize, @intCast(row)) + dr;
                const c = @as(isize, @intCast(col)) + dc;
                if (r < 0 or c < 0 or r >= self.height or c >= self.width) continue;
                buf[n] = @as(usize, @intCast(r)) * self.width + @as(usize, @intCast(c));
                n += 1;
            }
        }
        return buf[0..n];
    }
};

fn accessibleRolls(allocator: std.mem.Allocator, input: []const u8) !Answer {
    const grid = try Grid.parse(allocator, input);
    defer grid.deinit(allocator);

    // How many rolls surround each roll.
    const counts = try allocator.alloc(u8, grid.cells.len);
    defer allocator.free(counts);
    var buf: [8]usize = undefined;
    for (grid.cells, 0..) |cell, i| {
        counts[i] = 0;
        if (cell != '@') continue;
        for (grid.neighbours(i, &buf)) |n| {
            if (grid.cells[n] == '@') counts[i] += 1;
        }
    }

    // Part 1: rolls that are reachable right away. They also seed the queue
    // for part 2, and are removed from the grid as soon as they are queued.
    var queue = std.array_list.Managed(usize).init(allocator);
    defer queue.deinit();
    for (grid.cells, 0..) |*cell, i| {
        if (cell.* == '@' and counts[i] < max_neighbours) {
            try queue.append(i);
            cell.* = '.';
        }
    }
    const part1 = queue.items.len;

    // Part 2: removing a roll can only lower its neighbours' counts, so the
    // order doesn't matter. Whenever a neighbour drops below the limit it
    // becomes removable too.
    var removed: u64 = 0;
    while (queue.pop()) |i| {
        removed += 1;
        for (grid.neighbours(i, &buf)) |n| {
            if (grid.cells[n] != '@') continue;
            counts[n] -= 1;
            if (counts[n] == max_neighbours - 1) {
                try queue.append(n);
                grid.cells[n] = '.';
            }
        }
    }

    return .{ .part1 = part1, .part2 = removed };
}

const example =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 13), (try accessibleRolls(std.testing.allocator, example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 43), (try accessibleRolls(std.testing.allocator, example)).part2);
}

test "a solid 3x3 block keeps its middle until the corners go" {
    // Corners have 3 neighbours and go first; then the edges drop to < 4,
    // and finally the centre, so everything is removed.
    const block =
        \\@@@
        \\@@@
        \\@@@
    ;
    const answer = try accessibleRolls(std.testing.allocator, block);
    try std.testing.expectEqual(@as(u64, 4), answer.part1);
    try std.testing.expectEqual(@as(u64, 9), answer.part2);
}
