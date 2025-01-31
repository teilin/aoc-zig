const std = @import("std");

const Node = @Vector(2, u8);
const NodeList = std.ArrayList(Node);
const BoundedNodeList = std.BoundedArray(Node, 16);

pub fn solve(alloc: std.mem.Allocator) !void {
    const content = @embedFile("./data/day23.txt");
    const p1 = try part1(alloc, content);
    const p2 = try part2(alloc, content);
    std.debug.print("Part 1 -> {d}\nPart2 -> {s}\n", .{ p1, p2 });
}

fn part1(alloc: std.mem.Allocator, content: []const u8) !i64 {
    var adj = std.AutoArrayHashMap(Node, Set(Node)).init(alloc);
    defer {
        var it = adj.iterator();
        while (it.next()) |item| {
            item.value_ptr.deinit();
        }
        adj.deinit();
    }

    var line_it = std.mem.tokenizeScalar(u8, content, '\n');
    while (line_it.next()) |line| {
        const a: Node = .{ line[0], line[1] };
        const b: Node = .{ line[3], line[4] };

        var aa = try adj.getOrPutValue(a, .init(alloc));
        try aa.value_ptr.put(b);

        var ba = try adj.getOrPutValue(b, .init(alloc));
        try ba.value_ptr.put(a);
    }

    var count: i64 = 0;

    var a_it = adj.iterator();
    while (a_it.next()) |item| {
        const a = item.key_ptr.*;
        const a_adj = item.value_ptr;

        var b_it = a_adj.iterator();
        while (b_it.next()) |b| {
            if (lte(b, a)) continue;

            var c_it = a_adj.intersection(adj.get(b).?);
            while (c_it.next()) |c| {
                if (lte(c, b)) continue;

                if (a[0] == 't' or b[0] == 't' or c[0] == 't') {
                    count += 1;
                }
            }
        }
    }
    return count;
}

fn part2(alloc: std.mem.Allocator, content: []const u8) ![]const u8 {
    var adj = std.AutoArrayHashMap(Node, Set(Node)).init(alloc);
    defer {
        var it = adj.iterator();
        while (it.next()) |item| {
            item.value_ptr.deinit();
        }
        adj.deinit();
    }

    var line_it = std.mem.tokenizeScalar(u8, content, '\n');
    while (line_it.next()) |line| {
        const a: Node = .{ line[0], line[1] };
        const b: Node = .{ line[3], line[4] };

        var aa = try adj.getOrPutValue(a, .init(alloc));
        try aa.value_ptr.put(b);

        var ba = try adj.getOrPutValue(b, .init(alloc));
        try ba.value_ptr.put(a);
    }

    var nodes = NodeList.init(alloc);
    defer nodes.deinit();

    var it = adj.iterator();
    while (it.next()) |item| {
        try nodes.append(item.key_ptr.*);
    }

    var best: BoundedNodeList = try .init(0);
    var r: BoundedNodeList = try .init(0);

    try bronKerbosch(&adj, &best, &r, nodes.items, &.{});

    const lte_fn = struct {
        pub fn inner(_: void, a: Node, b: Node) bool {
            return lte(a, b);
        }
    }.inner;
    std.mem.sort(Node, best.slice(), {}, lte_fn);

    const res = try alloc.alloc(u8, 2 * best.len + best.len - 1);
    for (0.., best.slice()) |i, n| {
        res[3 * i] = n[0];
        res[3 * i + 1] = n[1];
        if (i != best.len - 1) {
            res[3 * i + 2] = ',';
        }
    }
    return res;
}

fn intersection(a: []const Node, b: Set(Node)) !BoundedNodeList {
    var out: BoundedNodeList = try .init(0);
    for (a) |n| {
        if (b.contains(n)) {
            try out.append(n);
        }
    }
    return out;
}

fn bronKerbosch(
    adj: *const std.AutoArrayHashMap(Node, Set(Node)),
    best: *BoundedNodeList,
    r: *BoundedNodeList,
    p: []const Node,
    x: []const Node,
) !void {
    if (p.len == 0 and x.len == 0) {
        if (r.len > best.len) {
            best.* = r.*;
        }
    }

    var cur_p = p;
    while (cur_p.len > 0) {
        const v = cur_p[cur_p.len - 1];
        const ip = try intersection(cur_p, adj.get(v).?);
        const ix = try intersection(x, adj.get(v).?);

        try r.append(v);
        try bronKerbosch(adj, best, r, ip.slice(), ix.slice());
        _ = r.pop();
        cur_p = cur_p[0 .. cur_p.len - 1];
    }
}

fn Set(Type: type) type {
    return struct {
        const Map = std.AutoArrayHashMap(Type, void);

        const Self = @This();
        const Iterator = struct {
            it: Map.Iterator,

            pub fn next(self: *@This()) ?Type {
                if (self.it.next()) |item| {
                    return item.key_ptr.*;
                }
                return null;
            }
        };
        const IntersectIterator = struct {
            it: Map.Iterator,
            other: Self,

            pub fn next(self: *@This()) ?Type {
                while (self.it.next()) |item| {
                    if (self.other.contains(item.key_ptr.*)) {
                        return item.key_ptr.*;
                    }
                }
                return null;
            }
        };

        data: Map,

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .data = .init(alloc),
            };
        }
        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }
        pub fn put(self: *Self, key: Type) !void {
            try self.data.put(key, {});
        }
        pub fn contains(self: Self, key: Type) bool {
            return self.data.contains(key);
        }

        pub fn iterator(self: Self) Iterator {
            return .{
                .it = self.data.iterator(),
            };
        }
        pub fn intersection(self: Self, other: Self) IntersectIterator {
            return .{
                .it = self.data.iterator(),
                .other = other,
            };
        }
    };
}

fn lte(a: Node, b: Node) bool {
    return a[0] < b[0] or (a[0] == b[0] and a[1] <= b[1]);
}

test "part1 test" {
    const content =
        \\kh-tc
        \\qp-kh
        \\de-cg
        \\ka-co
        \\yn-aq
        \\qp-ub
        \\cg-tb
        \\vc-aq
        \\tb-ka
        \\wh-tc
        \\yn-cg
        \\kh-ub
        \\ta-co
        \\de-co
        \\tc-td
        \\tb-wq
        \\wh-td
        \\ta-ka
        \\td-qp
        \\aq-cg
        \\wq-ub
        \\ub-vc
        \\de-ta
        \\wq-aq
        \\wq-vc
        \\wh-yn
        \\ka-de
        \\kh-ta
        \\co-tc
        \\wh-qp
        \\tb-vc
        \\td-yn
    ;

    try std.testing.expectEqual(7, try part1(std.testing.allocator, content));
}
