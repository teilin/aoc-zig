const std = @import("std");

const Vec2 = @Vector(2, i64);

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day20.txt");
    const p1 = try part1(allocator, content);
    const p2 = try part2(allocator, content);
    std.debug.print("Part 1 -> {d}\nPart 2 -> {d}\n", .{ p1, p2 });
}

fn part1(allocator: std.mem.Allocator, content: []const u8) !usize {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var maze = std.AutoArrayHashMap(Vec2, u8).init(allocator);
    defer maze.deinit();

    var row: i64 = 0;
    var cols: i64 = 0;
    while (lines.next()) |line| {
        cols = @intCast(line.len);
        var col: i64 = 0;
        for (line) |char| {
            const pos = .{ col, row };
            try maze.put(pos, char);
            col += 1;
        }
        row += 1;
    }

    const start = try findChar(maze, 'S');
    const end = try findChar(maze, 'E');

    const path = try aStar(allocator, maze, start, end);
    defer allocator.free(path);

    var poss_cheats = std.AutoArrayHashMap(Vec2, std.ArrayList(Vec2)).init(allocator);
    defer {
        var iter = poss_cheats.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        poss_cheats.deinit();
    }
    var cheat_times = std.AutoArrayHashMap(u64, u64).init(allocator);
    defer cheat_times.deinit();
    for (path, 101..) |pos1, i| {
        if (i >= path.len) {
            break;
        }
        for (path[i..]) |pos2| {
            const distance = manhattanDistance(pos1, pos2);
            if (distance == 2) {
                var l = poss_cheats.get(pos1) orelse std.ArrayList(Vec2).init(allocator);
                try l.append(pos2);
                try poss_cheats.put(pos1, l);
                const v = cheat_times.get(@intCast(i - 1)) orelse 0;
                try cheat_times.put(@intCast(i - 1), v + 1);
            }
        }
    }

    var iter = poss_cheats.iterator();
    var sum: usize = 0;
    while (iter.next()) |entry| {
        sum += entry.value_ptr.items.len;
    }
    return sum;
}

fn part2(allocator: std.mem.Allocator, content: []const u8) !usize {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var maze = std.AutoArrayHashMap(Vec2, u8).init(allocator);
    defer maze.deinit();

    var row: i64 = 0;
    var cols: i64 = 0;
    while (lines.next()) |line| {
        cols = @intCast(line.len);
        var col: i64 = 0;
        for (line) |char| {
            const pos = .{ col, row };
            try maze.put(pos, char);
            col += 1;
        }
        row += 1;
    }

    const start = try findChar(maze, 'S');
    const end = try findChar(maze, 'E');

    const path = try aStar(allocator, maze, start, end);
    defer allocator.free(path);

    var cheats = std.AutoArrayHashMap(Vec2, std.ArrayList(Vec2)).init(allocator);
    defer {
        for (cheats.values()) |l| {
            l.deinit();
        }
        cheats.deinit();
    }

    var cheat_times = std.AutoArrayHashMap(u64, u64).init(allocator);
    defer cheat_times.deinit();
    for (path, 0.., 101..) |pos1, cheat_start, i| {
        if (i >= path.len) {
            break;
        }
        for (path[i..], 0..) |pos2, j| {
            const cheat_end = i + j;
            const cheat_d: usize = @intCast(manhattanDistance(pos1, pos2));
            if (cheat_d > 20) continue;
            const path_d: usize = cheat_end - cheat_start;
            const saved_d = path_d - cheat_d;
            if (saved_d >= 100) {
                var l = cheats.get(pos1) orelse std.ArrayList(Vec2).init(allocator);
                try l.append(pos2);
                try cheats.put(pos1, l);
                const v = cheat_times.get(saved_d) orelse 0;
                try cheat_times.put(saved_d, v + 1);
            }
        }
    }

    var sum: usize = 0;
    for (cheats.values()) |v| {
        sum += v.items.len;
    }
    return sum;
}

fn manhattanDistance(a: Vec2, b: Vec2) i64 {
    const x: i64 = @intCast(@abs(a[0] - b[0]));
    const y: i64 = @intCast(@abs(a[1] - b[1]));
    return x + y;
}

fn lessThan(context: void, a: PqItem, b: PqItem) std.math.Order {
    _ = context;
    return std.math.order(a.f_score, b.f_score);
}

const PqItem = struct {
    pos: Vec2,
    f_score: i64,
};

const directions = [_]Vec2{
    Vec2{ -1, 0 },
    Vec2{ 1, 0 },
    Vec2{ 0, -1 },
    Vec2{ 0, 1 },
};

pub fn aStar(allocator: std.mem.Allocator, maze: std.AutoArrayHashMap(Vec2, u8), start: Vec2, goal: Vec2) ![]Vec2 {
    var open_set = std.PriorityQueue(PqItem, void, lessThan).init(allocator, {});
    defer open_set.deinit();
    try open_set.add(.{ .pos = start, .f_score = manhattanDistance(start, goal) });

    var came_from = std.AutoArrayHashMap(Vec2, Vec2).init(allocator);
    defer came_from.deinit();

    var g_score = std.AutoArrayHashMap(Vec2, i64).init(allocator);
    defer g_score.deinit();
    try g_score.put(start, 0);

    while (open_set.count() != 0) {
        const current = open_set.remove();

        if (std.meta.eql(current.pos, goal)) {
            return reconstructPath(allocator, came_from, current.pos);
        }

        for (directions) |dir| {
            const neighbor = current.pos + dir;
            if (!maze.contains(neighbor) or maze.get(neighbor) == '#') {
                continue;
            }

            const tentative_g_score: i64 = g_score.get(current.pos).? + 1;

            if (tentative_g_score < (g_score.get(neighbor) orelse std.math.maxInt(i64))) {
                try came_from.put(neighbor, current.pos);
                try g_score.put(neighbor, tentative_g_score);
                try open_set.add(.{ .pos = neighbor, .f_score = tentative_g_score + manhattanDistance(neighbor, goal) });
            }
        }
    }

    return error.PathNotFound;
}

fn reconstructPath(allocator: std.mem.Allocator, cameFrom: std.AutoArrayHashMap(Vec2, Vec2), current: Vec2) ![]Vec2 {
    var totalPath = std.ArrayList(Vec2).init(allocator);
    defer totalPath.deinit();

    try totalPath.append(current);
    var curr = current;
    while (cameFrom.contains(curr)) {
        curr = cameFrom.get(curr).?;
        try totalPath.append(curr);
    }

    return totalPath.toOwnedSlice();
}

fn findChar(maze: std.AutoArrayHashMap(Vec2, u8), char: u8) !Vec2 {
    var iter = maze.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.* == char) {
            return entry.key_ptr.*;
        }
    }
    return error.NotFound;
}
