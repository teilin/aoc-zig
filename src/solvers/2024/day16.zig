const std = @import("std");

const Point = [2]i32;
const Map = std.AutoHashMap(Point, void);

const Dir = enum {
    N,
    S,
    W,
    E,

    fn turnRight(self: *const Dir) Dir {
        return switch (self.*) {
            Dir.N => Dir.E,
            Dir.S => Dir.W,
            Dir.W => Dir.N,
            Dir.E => Dir.S,
        };
    }

    fn turnLeft(self: *const Dir) Dir {
        return switch (self.*) {
            Dir.N => Dir.W,
            Dir.S => Dir.E,
            Dir.W => Dir.S,
            Dir.E => Dir.N,
        };
    }

    fn asVec(self: *const Dir) Point {
        return switch (self.*) {
            Dir.N => .{ 0, -1 },
            Dir.S => .{ 0, 1 },
            Dir.W => .{ -1, 0 },
            Dir.E => .{ 1, 0 },
        };
    }
};

const PC = struct { p: Point, c: usize, d: Dir };

const PC2 = struct { p: Point, c: usize, d: Dir, ps: std.AutoHashMap(Point, void) };

const PD = struct {
    p: Point,
    d: Dir,
};

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn compPc2(_: void, a: PC2, b: PC2) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day16.txt");
    //const trimmed = std.mem.trim(u8, content, "\n");

    var start: Point = undefined;
    var end: Point = undefined;
    var map = try parse(allocator, content, &start, &end);
    defer map.deinit();
    const p1 = try part1(allocator, &map, start, end);
    std.debug.print("Part 1 -> {d}\n", .{p1});

    const p2 = try part2(allocator, &map, start, end, p1);
    std.debug.print("Part 2 -> {d}\n", .{p2});
}

fn parse(alloator: std.mem.Allocator, content: []const u8, start: *Point, end: *Point) !Map {
    var map = Map.init(alloator);

    var lineIter = std.mem.tokenizeSequence(u8, content, "\n");

    var y: i32 = 0;
    while (lineIter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') try map.put(.{ x, y }, {});
            if (c == 'S') {
                start[0] = x;
                start[1] = y;
            } else if (c == 'E') {
                end[0] = x;
                end[1] = y;
            }
            x += 1;
        }
    }
    return map;
}

fn part1(allocator: std.mem.Allocator, map: *Map, start: Point, end: Point) !usize {
    var frontier = std.PriorityQueue(PC, void, compPc).init(allocator, {});
    defer frontier.deinit();

    std.debug.print("\nStart = {d},{d} END = {d} {d}", .{ start[0], start[1], end[0], end[1] });

    var visited = std.AutoHashMap(PD, usize).init(allocator);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0, .d = Dir.E });

    while (frontier.removeOrNull()) |*current| {
        if (current.p[0] == end[0] and current.p[1] == end[1]) {
            return current.c;
        }

        const list: [3]PC = .{
            PC{ .p = add(current.p, current.d.asVec()), .d = current.d, .c = current.c + 1 },
            PC{ .p = current.p, .d = current.d.turnLeft(), .c = current.c + 1000 },
            PC{ .p = current.p, .d = current.d.turnRight(), .c = current.c + 1000 },
        };

        for (list) |l| {
            if (!map.contains(l.p)) {
                const npd = PD{ .p = l.p, .d = l.d };
                var push = true;
                if (visited.get(npd)) |old_c| {
                    if (old_c <= l.c) {
                        push = false;
                    }
                }
                if (push) {
                    try frontier.add(PC{ .p = l.p, .c = l.c, .d = l.d });
                    try visited.put(npd, l.c);
                }
            }
        }
    }
    return 0;
}

fn part2(allocator: std.mem.Allocator, map: *Map, start: Point, end: Point, best: usize) !usize {
    var frontier = std.PriorityQueue(PC2, void, compPc2).init(allocator, {});
    defer frontier.deinit();

    var best_pos = std.AutoHashMap(Point, void).init(allocator);
    defer best_pos.deinit();

    var visited = std.AutoHashMap(PD, usize).init(allocator);
    defer visited.deinit();

    var ps = std.AutoHashMap(Point, void).init(allocator);

    try ps.put(start, {});

    try frontier.add(PC2{ .p = start, .c = 0, .d = Dir.E, .ps = ps });

    while (frontier.removeOrNull()) |*current| {
        defer @constCast(current).ps.deinit();

        if (current.p[0] == end[0] and current.p[1] == end[1]) {
            var kiter = current.ps.keyIterator();
            while (kiter.next()) |p| try best_pos.put(p.*, {});
            continue;
        }

        const list: [3]PC = .{
            PC{ .p = add(current.p, current.d.asVec()), .d = current.d, .c = current.c + 1 },
            PC{ .p = current.p, .d = current.d.turnLeft(), .c = current.c + 1000 },
            PC{ .p = current.p, .d = current.d.turnRight(), .c = current.c + 1000 },
        };

        for (list) |l| {
            if (!map.contains(l.p)) {
                const npd = PD{ .p = l.p, .d = l.d };
                if (l.c > best) continue;
                var push = true;
                if (visited.get(npd)) |old_c| {
                    if (old_c < l.c) {
                        push = false;
                    }
                }
                if (push) {
                    var psc = try current.ps.clone();
                    try psc.put(l.p, {});
                    try frontier.add(PC2{ .p = l.p, .c = l.c, .d = l.d, .ps = psc });
                    try visited.put(npd, l.c);
                }
            }
        }
    }

    return best_pos.count();
}

test "part1 test 1" {
    const content =
        \\###############
        \\#.......#....E#
        \\#.#.###.#.###.#
        \\#.....#.#...#.#
        \\#.###.#####.#.#
        \\#.#.#.......#.#
        \\#.#.#####.###.#
        \\#...........#.#
        \\###.#.#####.#.#
        \\#...#.....#.#.#
        \\#.#.#.###.#.#.#
        \\#.....#...#.#.#
        \\#.###.#.#.#.#.#
        \\#S..#.....#...#
        \\###############
    ;
    const trimmed = std.mem.trim(u8, content, "\n");
    var start: Point = undefined;
    var end: Point = undefined;
    var map = try parse(std.testing.allocator, trimmed, &start, &end);
    defer map.deinit();
    const p1 = try part1(std.testing.allocator, &map, start, end);
    try std.testing.expectEqual(7036, p1);
}
