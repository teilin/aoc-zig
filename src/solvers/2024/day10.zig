const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

pub fn solve() !void {
    defer _ = gpa.deinit();
    const content = @embedFile("./data/day10.txt");
    var guide = try HikingGuide.fromRaw(content);
    defer guide.deinit();
    const p1 = try part1(guide);
    std.debug.print("Part 1 -> {d}\n", .{p1});
    const p2 = try part2(guide);
    std.debug.print("Part 2 -> {d}", .{p2});
}

fn part1(guide: HikingGuide) !u64 {
    const heads = try guide.potentialTrailheads();
    defer heads.deinit();

    var ans: u64 = 0;
    for (heads.items) |item| ans += try guide.trailheadScore(item);
    return ans;
}

fn part2(guide: HikingGuide) !u64 {
    const heads = try guide.potentialTrailheads();
    defer heads.deinit();

    var ans: u64 = 0;
    for (heads.items) |item| ans += try guide.trailheadRating(item);
    return ans;
}

const Pos = struct { x: usize, y: usize, lvl: u8 = 0 };
const HikingGuide = struct {
    width: usize,
    height: usize,
    topo: [][]u8,

    const Self = @This();

    fn fromRaw(raw: []const u8) !Self {
        var list = std.ArrayList([]u8).init(allocator);
        defer list.deinit();

        var width: usize = 0;
        var height: usize = 0;

        var lines = std.mem.splitSequence(u8, raw, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) break;

            const topo = try allocator.dupe(u8, line);
            for (topo) |*val| val.* = val.* - '0';
            try list.append(topo);

            width = line.len;
            height += 1;
        }

        return .{ .width = width, .height = height, .topo = try allocator.dupe([]u8, list.items) };
    }

    fn deinit(guide: *HikingGuide) void {
        for (guide.topo) |row| allocator.free(row);
        allocator.free(guide.topo);
    }

    fn potentialTrailheads(guide: HikingGuide) !std.ArrayList(Pos) {
        var list = std.ArrayList(Pos).init(allocator);
        var i: usize = 0;
        while (i < guide.height) : (i += 1) {
            var j: usize = 0;
            while (j < guide.width) : (j += 1) {
                if (guide.topo[i][j] == 0) try list.append(.{ .x = j, .y = i });
            }
        }
        return list;
    }

    fn trailheadScore(guide: HikingGuide, head: Pos) !u64 {
        if (guide.topo[head.y][head.x] != 0) return 0;

        var score: usize = 0;

        var q = Queue.init();
        defer q.deinit();

        var visited = std.AutoHashMap(Pos, void).init(allocator);
        defer visited.deinit();

        try q.append(head);
        while (q.pop()) |cur| {
            if (cur.lvl == 9) {
                if (!visited.contains(cur)) {
                    try visited.put(cur, void{});
                    score += 1;
                }
                continue;
            }

            var cpy = cur;
            cpy.lvl += 1;

            if (cur.x < guide.width - 1 and guide.topo[cur.y][cur.x + 1] == cpy.lvl) {
                cpy.x = cur.x + 1;
                cpy.y = cur.y;
                try q.append(cpy);
            }
            if (cur.y < guide.width - 1 and guide.topo[cur.y + 1][cur.x] == cur.lvl + 1) {
                cpy.x = cur.x;
                cpy.y = cur.y + 1;
                try q.append(cpy);
            }
            if (cur.x > 0 and guide.topo[cur.y][cur.x - 1] == cur.lvl + 1) {
                cpy.x = cur.x - 1;
                cpy.y = cur.y;
                try q.append(cpy);
            }
            if (cur.y > 0 and guide.topo[cur.y - 1][cur.x] == cur.lvl + 1) {
                cpy.x = cur.x;
                cpy.y = cur.y - 1;
                try q.append(cpy);
            }
        }

        return score;
    }

    fn trailheadRating(guide: HikingGuide, head: Pos) !u64 {
        if (guide.topo[head.y][head.x] != 0) return 0;

        var rating: usize = 0;

        var q = Queue.init();
        defer q.deinit();

        try q.append(head);
        while (q.pop()) |cur| {
            if (cur.lvl == 9) {
                rating += 1;
                continue;
            }

            var cpy = cur;
            cpy.lvl += 1;

            if (cur.x < guide.width - 1 and guide.topo[cur.y][cur.x + 1] == cpy.lvl) {
                cpy.x = cur.x + 1;
                cpy.y = cur.y;
                try q.append(cpy);
            }
            if (cur.y < guide.width - 1 and guide.topo[cur.y + 1][cur.x] == cur.lvl + 1) {
                cpy.x = cur.x;
                cpy.y = cur.y + 1;
                try q.append(cpy);
            }
            if (cur.x > 0 and guide.topo[cur.y][cur.x - 1] == cur.lvl + 1) {
                cpy.x = cur.x - 1;
                cpy.y = cur.y;
                try q.append(cpy);
            }
            if (cur.y > 0 and guide.topo[cur.y - 1][cur.x] == cur.lvl + 1) {
                cpy.x = cur.x;
                cpy.y = cur.y - 1;
                try q.append(cpy);
            }
        }

        return rating;
    }
};

const Queue = struct {
    list: std.DoublyLinkedList(Pos),
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    inline fn init() Self {
        return .{ .list = .{}, .arena = std.heap.ArenaAllocator.init(allocator) };
    }

    inline fn deinit(q: *@This()) void {
        q.arena.deinit();
    }

    inline fn append(q: *@This(), pos: Pos) !void {
        var nd = try q.arena.allocator().create(@TypeOf(q.list).Node);
        nd.data = pos;
        q.list.append(nd);
    }

    inline fn pop(q: *@This()) ?Pos {
        return if (q.list.pop()) |nd| nd.data else null;
    }
};

test "part1 test" {
    const content =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;
    var guide = try HikingGuide.fromRaw(content);
    defer guide.deinit();
    try std.testing.expectEqual(9, try part1(guide));
}

test "part2 test" {
    const content =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;
    var guide = try HikingGuide.fromRaw(content);
    defer guide.deinit();
    try std.testing.expectEqual(81, try part2(guide));
}
