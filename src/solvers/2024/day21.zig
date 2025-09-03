const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};

const allocator = gpa_impl.allocator();

const Point = [2]i32;
const Map = std.AutoHashMap(Point, u8);
const Path = std.array_list.Managed(u8);

const numpad_str = "789\n456\n123\n#0A";
const dirpad_str = "#^A\n<v>";

fn parse(content: []const u8) !Map {
    var map = Map.init(allocator);
    defer map.deinit();

    var line_iter = std.mem.tokenizeSequence(u8, content, "\n");
    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        for (line, 0..) |c, x| {
            if (c != '#') try map.put(.{ @intCast(x), y }, c);
        }
    }
    return map;
}

const PC = struct {
    p: Point,
    c: usize,
    path: Path,
};

fn getDistance(a: u8, b: u8) usize {
    if (a == b) return 0;

    if (a == '<') {
        if (b == '>') return 3;
        if (b == 'v') return 2;
        if (b == '^') return 3;
        if (b == 'A') return 4;
    }
    if (a == '>') {
        if (b == '<') return 3;
        if (b == 'v') return 2;
        if (b == '^') return 3;
        if (b == 'A') return 2;
    }
    if (a == '^') {
        if (b == '<') return 3;
        if (b == 'v') return 2;
        if (b == '>') return 3;
        if (b == 'A') return 2;
    }
    if (a == 'v') {
        if (b == 'A') return 3;
        return 2;
    }
    unreachable;
}

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    const cmp = std.math.order(a.c, b.c);
    if (cmp != std.math.Order.eq) return cmp;

    var flips_a: usize = 0;
    var w_iter = std.mem.window(u8, a.path.items, 2, 1);
    while (w_iter.next()) |btns| {
        if (btns.len < 2) break;
        if (btns[0] != btns[1]) flips_a += getDistance(btns[0], btns[1]);
    }

    var flips_b: usize = 0;
    w_iter = std.mem.window(u8, b.path.items, 2, 1);
    while (w_iter.next()) |btns| {
        if (btns.len < 2) break;
        if (btns[0] != btns[1]) flips_b += getDistance(btns[0], btns[1]);
    }
    return std.math.order(flips_a, flips_b);
}

fn getNeigbours(p: Point) [4]Point {
    const x = p[0];
    const y = p[1];

    const neighbours = [_]Point{
        .{ x - 1, y },
        .{ x + 1, y },
        .{ x, y - 1 },
        .{ x, y + 1 },
    };

    return neighbours;
}

fn shortestPath(map: *Map, start: *Point, end: u8) !Path {
    var frontier = std.PriorityQueue(PC, void, compPc).init(allocator, {});
    defer frontier.deinit();

    var visited = std.AutoHashMap(Point, usize).init(allocator);
    defer visited.deinit();

    var iPath = Path.init(allocator);
    //defer iPath.deinit();
    if (map.get(start.*)) |c| {
        if (c == end) {
            try iPath.append('A');
        }
    }

    try frontier.add(PC{ .p = start.*, .c = 0, .path = iPath });
    defer for (frontier.items) |*f| @constCast(f).path.deinit();

    while (frontier.removeOrNull()) |*cur| {
        if (map.get(cur.p)) |c| {
            if (c == end) {
                start.* = cur.p;
                return cur.path;
            }
        }
        defer @constCast(cur).path.deinit();

        const ns = getNeigbours(cur.p);
        const dirs = "<>^v";

        for (ns, dirs) |n, d| {
            if (map.contains(n)) {
                var push = true;
                if (visited.get(n)) |old_c| {
                    if (old_c < cur.c + 1) {
                        push = false;
                    }
                }
                if (push) {
                    var npath = try cur.path.clone();
                    try npath.append(d);
                    if (map.get(n)) |c| {
                        if (c == end) {
                            try npath.append('A');
                        }
                    }
                    try frontier.add(PC{ .p = n, .c = cur.c + 1, .path = npath });
                    try visited.put(n, cur.c + 1);
                }
            }
        }
    }

    unreachable;
}

fn takeLeft(comptime T: type, slice: []const T, values_to_take: []const T) []const T {
    var end: usize = 0;
    while (end < slice.len and std.mem.indexOfScalar(T, values_to_take, slice[end]) != null) : (end += 1) {}
    return slice[0..end];
}

const StartEnd = struct {
    s: Point,
    e: u8,
};

const PathPoint = struct {
    path: Path,
    end: Point,
};

const Memo = std.AutoHashMap(StartEnd, PathPoint);

pub fn solve() !void {
    const content = @embedFile("./data/day21.txt");
    const p1 = try part1(content);
    std.debug.print("Part 1 -> {d}\nPart 2 -> {d}\n", .{ p1, 0 });
}

fn part1(content: []const u8) !usize {
    var numpad = try parse(numpad_str);
    defer numpad.deinit();
    var dirpad = try parse(dirpad_str);
    defer dirpad.deinit();

    var memo = Memo.init(allocator);

    var line_iter = std.mem.tokenizeSequence(u8, content, "\n");

    var sum: usize = 0;
    while (line_iter.next()) |line| {
        var p = Point{ 2, 3 };
        var numpad_path = Path.init(allocator);
        defer numpad_path.deinit();
        for (line) |c| {
            var to_btn = try shortestPath(&numpad, &p, c);
            defer to_btn.deinit();
            try numpad_path.appendSlice(to_btn.items);
        }

        var dirpad_path_a = Path.init(allocator);
        defer dirpad_path_a.deinit();
        var dirpad_path_b = Path.init(allocator);
        defer dirpad_path_b.deinit();

        var tgt = numpad_path.items;
        var pad = &dirpad_path_a;

        for (0..2) |i| {
            if (i % 2 == 0) {
                pad = &dirpad_path_a;
            } else {
                pad = &dirpad_path_b;
            }
            pad.clearRetainingCapacity();
            p = Point{ 2, 0 };
            for (tgt) |c| {
                const se = StartEnd{ .s = p, .e = c };
                if (memo.get(se)) |best| {
                    try pad.appendSlice(best.path.items);
                    p = best.end;
                } else {
                    const to_btn = try shortestPath(&dirpad, &p, c);
                    try pad.appendSlice(to_btn.items);
                    try memo.put(se, PathPoint{ .path = to_btn, .end = p });
                }
            }
            tgt = pad.items;
        }

        const nums = takeLeft(u8, line, "0123456789");

        sum += try std.fmt.parseInt(usize, nums, 10) * pad.items.len;
    }

    return sum;
}
