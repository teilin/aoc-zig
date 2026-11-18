const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day08.txt");
    const solution = try connectBoxes(gpa.allocator(), content, 1000);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

const Box = struct { x: i64, y: i64, z: i64 };

/// A possible string of lights between boxes `a` and `b`.
const Pair = struct {
    /// Squared distance: same ordering as the real distance, no floats needed.
    dist2: u64,
    a: u32,
    b: u32,

    /// Ties are broken by box index so the order is always the same.
    fn lessThan(_: void, lhs: Pair, rhs: Pair) bool {
        if (lhs.dist2 != rhs.dist2) return lhs.dist2 < rhs.dist2;
        if (lhs.a != rhs.a) return lhs.a < rhs.a;
        return lhs.b < rhs.b;
    }
};

/// Union-find over box indices, tracking the size of each circuit.
const Circuits = struct {
    parent: []u32,
    size: []u32,
    count: usize,

    fn init(allocator: std.mem.Allocator, n: usize) !Circuits {
        const parent = try allocator.alloc(u32, n);
        errdefer allocator.free(parent);
        const size = try allocator.alloc(u32, n);
        for (parent, size, 0..) |*p, *s, i| {
            p.* = @intCast(i);
            s.* = 1;
        }
        return .{ .parent = parent, .size = size, .count = n };
    }

    fn deinit(self: Circuits, allocator: std.mem.Allocator) void {
        allocator.free(self.parent);
        allocator.free(self.size);
    }

    fn find(self: *Circuits, i: u32) u32 {
        var root = i;
        while (self.parent[root] != root) root = self.parent[root];
        // Path compression: point everything on the way straight at the root.
        var cur = i;
        while (self.parent[cur] != root) {
            const next = self.parent[cur];
            self.parent[cur] = root;
            cur = next;
        }
        return root;
    }

    /// Joins the circuits of `a` and `b`. Returns false if they were already one.
    fn join(self: *Circuits, a: u32, b: u32) bool {
        var ra = self.find(a);
        var rb = self.find(b);
        if (ra == rb) return false;
        if (self.size[ra] < self.size[rb]) std.mem.swap(u32, &ra, &rb);
        self.parent[rb] = ra;
        self.size[ra] += self.size[rb];
        self.count -= 1;
        return true;
    }
};

/// Part 1: after the `connections` shortest pairs (even ones that change
/// nothing), the product of the three largest circuit sizes.
/// Part 2: keep going until there is one circuit; product of the X
/// coordinates of the pair that completes it.
fn connectBoxes(allocator: std.mem.Allocator, input: []const u8, connections: usize) !Answer {
    const boxes = try parseBoxes(allocator, input);
    defer allocator.free(boxes);
    if (boxes.len < 3) return error.TooFewBoxes;

    const pairs = try allocator.alloc(Pair, boxes.len * (boxes.len - 1) / 2);
    defer allocator.free(pairs);
    var k: usize = 0;
    for (boxes, 0..) |p, i| {
        for (boxes[i + 1 ..], i + 1..) |q, j| {
            pairs[k] = .{ .dist2 = dist2(p, q), .a = @intCast(i), .b = @intCast(j) };
            k += 1;
        }
    }
    std.mem.sort(Pair, pairs, {}, Pair.lessThan);

    var circuits = try Circuits.init(allocator, boxes.len);
    defer circuits.deinit(allocator);

    var part1: ?u64 = null;
    var part2: ?u64 = null;
    for (pairs, 1..) |pair, made| {
        if (circuits.join(pair.a, pair.b) and circuits.count == 1) {
            part2 = @intCast(boxes[pair.a].x * boxes[pair.b].x);
        }
        if (made == connections) part1 = try largestThreeProduct(&circuits);
        if (part1 != null and part2 != null) break;
    }

    return .{
        .part1 = part1 orelse return error.NotEnoughPairs,
        .part2 = part2 orelse return error.NeverConnected,
    };
}

fn parseBoxes(allocator: std.mem.Allocator, input: []const u8) ![]Box {
    var list = std.array_list.Managed(Box).init(allocator);
    errdefer list.deinit();

    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeScalar(u8, line, ',');
        var coords: [3]i64 = undefined;
        for (&coords) |*c| {
            c.* = try std.fmt.parseInt(i64, fields.next() orelse return error.BadBox, 10);
        }
        if (fields.next() != null) return error.BadBox;
        try list.append(.{ .x = coords[0], .y = coords[1], .z = coords[2] });
    }
    return list.toOwnedSlice();
}

fn dist2(p: Box, q: Box) u64 {
    const dx = p.x - q.x;
    const dy = p.y - q.y;
    const dz = p.z - q.z;
    return @intCast(dx * dx + dy * dy + dz * dz);
}

fn largestThreeProduct(circuits: *Circuits) !u64 {
    var top = [3]u64{ 0, 0, 0 };
    for (circuits.parent, 0..) |p, i| {
        if (p != i) continue; // only roots carry a circuit's size
        var s: u64 = circuits.size[i];
        // Insert into the descending top-3.
        for (&top) |*t| {
            if (s > t.*) std.mem.swap(u64, &s, t);
        }
    }
    if (top[2] == 0) return error.FewerThanThreeCircuits;
    return top[0] * top[1] * top[2];
}

const example =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 40), (try connectBoxes(std.testing.allocator, example, 10)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 25272), (try connectBoxes(std.testing.allocator, example, 10)).part2);
}

test "closest pairs in the example come first" {
    const boxes = try parseBoxes(std.testing.allocator, example);
    defer std.testing.allocator.free(boxes);
    // 162,817,812 (0) and 425,690,689 (19) are the closest pair...
    // ...then 162,817,812 (0) and 431,825,988 (7).
    try std.testing.expect(dist2(boxes[0], boxes[19]) < dist2(boxes[0], boxes[7]));
    for (boxes, 0..) |p, i| {
        for (boxes[i + 1 ..], i + 1..) |q, j| {
            if (i == 0 and j == 19) continue;
            try std.testing.expect(dist2(boxes[0], boxes[19]) <= dist2(p, q));
        }
    }
}

test "circuits join and count" {
    var c = try Circuits.init(std.testing.allocator, 5);
    defer c.deinit(std.testing.allocator);
    try std.testing.expect(c.join(0, 1));
    try std.testing.expect(c.join(1, 2));
    try std.testing.expect(!c.join(0, 2)); // already the same circuit
    try std.testing.expect(c.join(3, 4));
    try std.testing.expectEqual(@as(usize, 2), c.count);
    try std.testing.expectEqual(@as(u32, 3), c.size[c.find(2)]);
}
