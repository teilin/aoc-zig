const std = @import("std");

const Point = [2]i32;
const Tile = enum { Wall, Open };
const WallMap = std.AutoHashMap(Point, void);
const BoxMap = std.AutoHashMap(Point, void);

pub fn solve(alloc: std.mem.Allocator) !void {
    const content = @embedFile("./data/day15.txt");
    const p1 = try part1(alloc, content);
    const p2 = try part2(alloc, content);
    std.debug.print("Part 1 -> {d}\nPart 2 -> {d}\n", .{ p1, p2 });
}

fn parseMap(text: []const u8, p: *Point, boxes: *BoxMap, map: *WallMap) !void {
    var line_iter = std.mem.splitSequence(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') {
                try map.put(.{ x, y }, {});
            } else if (c == '@') {
                p[0] = x;
                p[1] = y;
            } else if (c == 'O') {
                try boxes.put(.{ x, y }, {});
            }
            x += 1;
        }
    }
}

fn parseMap2(text: []const u8, p: *Point, boxes: *BoxMap, map: *WallMap) !void {
    var line_iter = std.mem.splitSequence(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') {
                try map.put(.{ x, y }, {});
                try map.put(.{ x + 1, y }, {});
            } else if (c == '@') {
                p[0] = x;
                p[1] = y;
            } else if (c == 'O') {
                try boxes.put(.{ x, y }, {});
            }
            x += 2;
        }
    }
}

const Dir = enum {
    N,
    S,
    W,
    E,

    fn asVec(self: *const Dir) Point {
        return switch (self.*) {
            Dir.N => .{ 0, -1 },
            Dir.S => .{ 0, 1 },
            Dir.W => .{ -1, 0 },
            Dir.E => .{ 1, 0 },
        };
    }

    fn fromChar(c: u8) Dir {
        switch (c) {
            '<' => return Dir.W,
            '>' => return Dir.E,
            '^' => return Dir.N,
            'v' => return Dir.S,
            else => unreachable,
        }
    }
};

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn isMoveable(map: *WallMap, boxes: *BoxMap, p: Point, v: Point) bool {
    var c = add(p, v);

    while (true) : (c = add(c, v)) {
        if (map.contains(c)) return false;
        if (boxes.contains(c)) continue;
        return true;
    }
}

fn moveBoxes(alloc: std.mem.Allocator, boxes: *BoxMap, p: Point, v: Point) !void {
    var c = add(p, v);

    var list = std.array_list.Managed(Point).init(alloc);
    defer list.deinit();

    while (true) : (c = add(c, v)) {
        if (boxes.remove(c)) {
            try list.append(c);
        } else {
            break;
        }
    }

    for (list.items) |b| {
        try boxes.put(add(b, v), {});
    }
}

fn isMoveable2(map: *WallMap, boxes: *BoxMap, p: Point, v: Point) bool {
    var c = add(p, v);

    while (true) : (c = add(c, v)) {
        if (map.contains(c)) return false;
        if (v[1] == 0) {
            if (boxes.contains(c)) continue;
            if (boxes.contains(.{ c[0] - 1, c[1] })) continue;
        }
        if (v[0] == 0) {
            if (boxes.contains(c)) {
                return isMoveable2(map, boxes, c, v) and isMoveable2(map, boxes, .{ c[0] + 1, c[1] }, v);
            }
            if (boxes.contains(.{ c[0] - 1, c[1] })) {
                return isMoveable2(map, boxes, c, v) and isMoveable2(map, boxes, .{ c[0] - 1, c[1] }, v);
            }
        }
        return true;
    }
}

fn moveBoxes2(boxes: *BoxMap, p: Point, v: Point, list: *std.array_list.Managed(Point)) !void {
    const c = add(p, v);

    const a = boxes.remove(c);
    const b = boxes.remove(.{ c[0] - 1, c[1] });
    if (v[1] == 0) {
        if (a) try list.append(c);
        if (b) try list.append(.{ c[0] - 1, c[1] });
        if (a) {
            try moveBoxes2(boxes, .{ c[0] + 1, c[1] }, v, list);
        }
        if (b) {
            try moveBoxes2(boxes, .{ c[0] - 1, c[1] }, v, list);
        }
        if (!a and !b) return;
    }
    if (v[0] == 0) {
        if (a) try list.append(c);
        if (b) try list.append(.{ c[0] - 1, c[1] });
        if (a) {
            try moveBoxes2(boxes, c, v, list);
            try moveBoxes2(boxes, .{ c[0] + 1, c[1] }, v, list);
        }
        if (b) {
            try moveBoxes2(boxes, c, v, list);
            try moveBoxes2(boxes, .{ c[0] - 1, c[1] }, v, list);
        }
        if (!a and !b) return;
    }
}

fn part1(alloc: std.mem.Allocator, content: []const u8) !i32 {
    var map = WallMap.init(alloc);
    defer map.deinit();
    var boxes = BoxMap.init(alloc);
    defer boxes.deinit();

    var parts_iter = std.mem.tokenizeSequence(u8, content, "\n\n");

    var pos: Point = undefined;

    try parseMap(parts_iter.next().?, &pos, &boxes, &map);

    var dirs = std.array_list.Managed(Point).init(alloc);
    defer dirs.deinit();

    const parts = parts_iter.next().?;

    for (parts) |c| {
        if (c == '\n') continue;
        try dirs.append(Dir.fromChar(c).asVec());
    }

    for (dirs.items) |d| {
        if (isMoveable(&map, &boxes, pos, d)) {
            try moveBoxes(alloc, &boxes, pos, d);
            pos = add(pos, d);
        }
    }

    var kitter = boxes.keyIterator();
    var sum: i32 = 0;
    while (kitter.next()) |b| {
        sum += b[0] + b[1] * 100;
    }

    return sum;
}

fn part2(alloc: std.mem.Allocator, content: []const u8) !i32 {
    var map = WallMap.init(alloc);
    defer map.deinit();
    var boxes = BoxMap.init(alloc);
    defer boxes.deinit();

    var parts_iter = std.mem.splitSequence(u8, content, "\n\n");

    var pos: Point = undefined;

    try parseMap2(parts_iter.next().?, &pos, &boxes, &map);

    var dirs = std.array_list.Managed(Point).init(alloc);
    defer dirs.deinit();

    const part = parts_iter.next().?;

    for (part) |c| {
        if (c == '\n') continue;
        try dirs.append(Dir.fromChar(c).asVec());
    }

    for (dirs.items) |d| {
        if (isMoveable2(&map, &boxes, pos, d)) {
            var list = std.array_list.Managed(Point).init(alloc);
            defer list.deinit();
            try moveBoxes2(&boxes, pos, d, &list);
            pos = add(pos, d);
            for (list.items) |b| {
                try boxes.put(add(b, d), {});
            }
        }
    }

    var kiter = boxes.keyIterator();

    var sum: i32 = 0;
    while (kiter.next()) |b| {
        sum += b[0] + b[1] * 100;
    }

    return sum;
}

test "part1 test" {
    const content =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
        \\
        \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    ;

    try std.testing.expectEqual(0, try part1(std.testing.allocator, content));
}
