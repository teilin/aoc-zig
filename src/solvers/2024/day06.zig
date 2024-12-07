const std = @import("std");
const List = std.ArrayList;

const Visited = struct {
    char: u8,
    visited: bool,
};

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day06.txt");
    const part1 = try predictedWalking(allocator, content);
    std.debug.print("Part 1 -> {d}", .{part1});
    const part2 = try numDifferentPossitions(allocator, content);
    std.debug.print("Part 2 -> {d}", .{part2});
}

fn predictedWalking(allocator: std.mem.Allocator, content: []const u8) !u64 {
    var lines = std.mem.tokenizeSequence(u8, content, "\n");
    var map = std.AutoArrayHashMap([2]i64, Visited).init(allocator);
    defer map.deinit();

    var start_index: [2]i64 = undefined;
    var row: i64 = 0;
    while (lines.next()) |line| {
        for (0.., line) |col, char| {
            try map.put(.{ row, @intCast(col) }, Visited{ .char = char, .visited = false });
            if (char == '^' or char == 'v' or char == '<' or char == '>') {
                start_index = .{ row, @intCast(col) };
            }
        }
        row += 1;
    }

    var curr_dir = map.get(start_index).?.char;
    var curr_index = start_index;
    while (true) {
        const curr_char = map.get(curr_index).?.char;
        try map.put(curr_index, Visited{ .char = curr_char, .visited = true });
        var next_index: [2]i64 = undefined;
        if (curr_dir == '^') {
            next_index = .{ curr_index[0] - 1, curr_index[1] };
        } else if (curr_dir == 'v') {
            next_index = .{ curr_index[0] + 1, curr_index[1] };
        } else if (curr_dir == '<') {
            next_index = .{ curr_index[0], curr_index[1] - 1 };
        } else if (curr_dir == '>') {
            next_index = .{ curr_index[0], curr_index[1] + 1 };
        }

        const next_char = map.get(next_index);
        if (next_char == null) break;
        if (next_char.?.char == '#') {
            if (curr_dir == '^') {
                curr_dir = '>';
                next_index = .{ curr_index[0], curr_index[1] + 1 };
            } else if (curr_dir == '>') {
                curr_dir = 'v';
                next_index = .{ curr_index[0] + 1, curr_index[1] };
            } else if (curr_dir == 'v') {
                curr_dir = '<';
                next_index = .{ curr_index[0], curr_index[1] - 1 };
            } else if (curr_dir == '<') {
                curr_dir = '^';
                next_index = .{ curr_index[0] - 1, curr_index[1] };
            }
        }
        curr_index = next_index;
    }

    var mapIter = map.iterator();
    var sum: u64 = 0;
    while (mapIter.next()) |entry| {
        if (entry.value_ptr.*.visited == true) {
            sum += 1;
        }
    }
    return sum;
}

fn numDifferentPossitions(allocator: std.mem.Allocator, content: []const u8) !u32 {
    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();
    var iter = std.mem.tokenizeScalar(u8, content, '\n');
    while (iter.next()) |line| {
        const owned = try allocator.dupe(u8, line);
        try lines.append(owned);
    }
    const map = try lines.toOwnedSlice();

    var sum: u32 = 0;
    for (0..map.len) |y| {
        for (0..map[0].len) |x| {
            var walker = Walker.init(map);
            var grid = try Grid.init(allocator, map);
            const x1 = @as(i32, @intCast(x));
            const y1 = @as(i32, @intCast(y));

            if (grid.get(x1, y1) != '.') continue;
            grid.set(x1, y1, '#');

            if (try loops(allocator, &walker, &grid)) {
                sum += 1;
            }
        }
    }
    return sum;
}

fn loops(allocator: std.mem.Allocator, walker: *Walker, grid: *Grid) !bool {
    var seen = std.AutoHashMap(Walker, void).init(allocator);
    try seen.put(walker.*, {});
    while (true) {
        while (grid.ahead(walker) == '#') {
            walker.turn();
            if (seen.contains(walker.*)) return true;
            try seen.put(walker.*, {});
        }
        if (grid.ahead(walker) == null) {
            return false;
        }
        walker.move();
        if (seen.contains(walker.*)) return true;
        try seen.put(walker.*, {});
    }
}

const Grid = struct {
    map: [][]u8,
    sizeX: usize,
    sizeY: usize,

    pub fn init(allocator: std.mem.Allocator, map: [][]u8) !Grid {
        var lines = std.ArrayList([]u8).init(allocator);
        for (map) |line| {
            const owned = try allocator.dupe(u8, line);
            try lines.append(owned);
        }
        const copy = try lines.toOwnedSlice();

        return Grid{
            .map = copy,
            .sizeY = copy.len,
            .sizeX = copy[0].len,
        };
    }

    pub fn get(self: *Grid, x: i32, y: i32) ?u8 {
        if (y >= 0 and y < self.sizeY and x >= 0 and x < self.sizeX) {
            return self.map[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
        }
        return null;
    }

    pub fn set(self: *Grid, x: i32, y: i32, val: u8) void {
        if (y >= 0 and y < self.sizeY and x >= 0 and x < self.sizeX) {
            self.map[@as(usize, @intCast(y))][@as(usize, @intCast(x))] = val;
        } else {
            @panic("set out of bounds");
        }
    }

    pub fn ahead(self: *Grid, walker: *Walker) ?u8 {
        return self.get(walker.x + walker.dx, walker.y + walker.dy);
    }
};

const Walker = struct {
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,

    pub fn start(grid: [][]const u8) struct { x: i32, y: i32 } {
        const lenY = grid.len;
        const lenX = grid[0].len;
        for (0..lenY) |y| {
            for (0..lenX) |x| {
                if (grid[y][x] == '^') {
                    return .{ .x = @intCast(x), .y = @intCast(y) };
                }
            }
        }
        unreachable;
    }

    pub fn init(grid: [][]const u8) Walker {
        const s = Walker.start(grid);
        return Walker{ .x = s.x, .y = s.y, .dx = 0, .dy = -1 };
    }

    pub fn turn(self: *Walker) void {
        const tmp = self.dx;
        self.dx = -self.dy;
        self.dy = tmp;
    }

    pub fn move(self: *Walker) void {
        self.x += self.dx;
        self.y += self.dy;
    }
};

test "part1 test" {
    const content =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    try std.testing.expectEqual(41, predictedWalking(std.testing.allocator, content));
}

test "part2 test" {
    const content =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    try std.testing.expectEqual(6, numDifferentPossitions(std.testing.allocator, content));
}
