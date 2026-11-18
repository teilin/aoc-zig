const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day09.txt");
    const solution = try largestRectangles(gpa.allocator(), content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

const Tile = struct { x: i64, y: i64 };

fn largestRectangles(allocator: std.mem.Allocator, input: []const u8) !Answer {
    const red = try parseTiles(allocator, input);
    defer allocator.free(red);
    if (red.len < 2) return error.TooFewTiles;

    var floor = try CompressedFloor.init(allocator, red);
    defer floor.deinit(allocator);

    var part1: u64 = 0;
    var part2: u64 = 0;
    for (red, 0..) |a, i| {
        for (red[i + 1 ..]) |b| {
            const area = (@abs(a.x - b.x) + 1) * (@abs(a.y - b.y) + 1);
            part1 = @max(part1, area);
            if (area > part2 and floor.isInside(a, b)) part2 = area;
        }
    }
    return .{ .part1 = part1, .part2 = part2 };
}

fn parseTiles(allocator: std.mem.Allocator, input: []const u8) ![]Tile {
    var list = std.array_list.Managed(Tile).init(allocator);
    errdefer list.deinit();

    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        const comma = std.mem.indexOfScalar(u8, line, ',') orelse return error.BadTile;
        try list.append(.{
            .x = try std.fmt.parseInt(i64, line[0..comma], 10),
            .y = try std.fmt.parseInt(i64, line[comma + 1 ..], 10),
        });
    }
    return list.toOwnedSlice();
}

/// The floor shrunk down to the coordinates that matter.
///
/// Every distinct X used by a red tile gets its own column, and the run of
/// tiles between two neighbouring X values gets one more column. With an
/// extra column of padding on each side, X value number `i` lands in column
/// `2*i + 1`. Rows work the same way. Inside each cell every real tile is
/// either all inside the loop or all outside it, because loop edges only run
/// along the red tiles' coordinates.
///
/// After drawing the loop and flood-filling from the padding, `outside` holds
/// a 2D running total of outside cells, so any rectangle can be checked with
/// four lookups.
const CompressedFloor = struct {
    xs: []i64,
    ys: []i64,
    width: usize,
    height: usize,
    /// outside[(r) * (width + 1) + c] = number of outside cells in rows < r, cols < c.
    outside: []u32,

    fn init(allocator: std.mem.Allocator, red: []const Tile) !CompressedFloor {
        const xs = try sortedUnique(allocator, red, .x);
        errdefer allocator.free(xs);
        const ys = try sortedUnique(allocator, red, .y);
        errdefer allocator.free(ys);

        const width = 2 * xs.len + 1;
        const height = 2 * ys.len + 1;

        const Cell = enum(u8) { unknown, loop, outside };
        const cells = try allocator.alloc(Cell, width * height);
        defer allocator.free(cells);
        @memset(cells, .unknown);

        // Draw the loop: each red tile joins the next, and the last wraps to the first.
        for (red, 0..) |a, i| {
            const b = red[(i + 1) % red.len];
            const ca = colOf(xs, a.x);
            const cb = colOf(xs, b.x);
            const ra = colOf(ys, a.y);
            const rb = colOf(ys, b.y);
            if (ca != cb and ra != rb) return error.DiagonalEdge;
            for (@min(ra, rb)..@max(ra, rb) + 1) |r| {
                for (@min(ca, cb)..@max(ca, cb) + 1) |c| cells[r * width + c] = .loop;
            }
        }

        // Flood fill the outside from the padded corner.
        var stack = std.array_list.Managed(usize).init(allocator);
        defer stack.deinit();
        cells[0] = .outside;
        try stack.append(0);
        while (stack.pop()) |idx| {
            const r = idx / width;
            const c = idx % width;
            const around = [4]?usize{
                if (r > 0) idx - width else null,
                if (r + 1 < height) idx + width else null,
                if (c > 0) idx - 1 else null,
                if (c + 1 < width) idx + 1 else null,
            };
            for (around) |maybe| {
                const n = maybe orelse continue;
                if (cells[n] != .unknown) continue;
                cells[n] = .outside;
                try stack.append(n);
            }
        }

        // 2D running totals of outside cells.
        const stride = width + 1;
        const outside = try allocator.alloc(u32, stride * (height + 1));
        @memset(outside, 0);
        for (0..height) |r| {
            for (0..width) |c| {
                const here: u32 = @intFromBool(cells[r * width + c] == .outside);
                outside[(r + 1) * stride + c + 1] = here +
                    outside[r * stride + c + 1] +
                    outside[(r + 1) * stride + c] -
                    outside[r * stride + c];
            }
        }

        return .{ .xs = xs, .ys = ys, .width = width, .height = height, .outside = outside };
    }

    fn deinit(self: *CompressedFloor, allocator: std.mem.Allocator) void {
        allocator.free(self.xs);
        allocator.free(self.ys);
        allocator.free(self.outside);
    }

    /// True when the rectangle with corners `a` and `b` has no outside tiles.
    fn isInside(self: *const CompressedFloor, a: Tile, b: Tile) bool {
        const c0 = colOf(self.xs, @min(a.x, b.x));
        const c1 = colOf(self.xs, @max(a.x, b.x)) + 1;
        const r0 = colOf(self.ys, @min(a.y, b.y));
        const r1 = colOf(self.ys, @max(a.y, b.y)) + 1;
        const s = self.width + 1;
        const count = self.outside[r1 * s + c1] + self.outside[r0 * s + c0] -
            self.outside[r0 * s + c1] - self.outside[r1 * s + c0];
        return count == 0;
    }

    /// Grid column (or row) for a coordinate that is one of the red tiles' values.
    fn colOf(values: []const i64, v: i64) usize {
        const i = std.sort.binarySearch(i64, values, v, struct {
            fn order(target: i64, item: i64) std.math.Order {
                return std.math.order(target, item);
            }
        }.order).?;
        return 2 * i + 1;
    }

    fn sortedUnique(allocator: std.mem.Allocator, red: []const Tile, comptime field: std.meta.FieldEnum(Tile)) ![]i64 {
        const values = try allocator.alloc(i64, red.len);
        defer allocator.free(values);
        for (red, values) |t, *v| v.* = @field(t, @tagName(field));
        std.mem.sort(i64, values, {}, std.sort.asc(i64));

        var n: usize = 0;
        for (values) |v| {
            if (n == 0 or values[n - 1] != v) {
                values[n] = v;
                n += 1;
            }
        }
        return allocator.dupe(i64, values[0..n]);
    }
};

const example =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 50), (try largestRectangles(std.testing.allocator, example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 24), (try largestRectangles(std.testing.allocator, example)).part2);
}

test "example rectangles from the puzzle text" {
    const red = try parseTiles(std.testing.allocator, example);
    defer std.testing.allocator.free(red);
    var floor = try CompressedFloor.init(std.testing.allocator, red);
    defer floor.deinit(std.testing.allocator);

    // Allowed: 7,3 to 11,1 (area 15), 9,7 to 9,5 (area 3), 9,5 to 2,3 (area 24).
    try std.testing.expect(floor.isInside(.{ .x = 7, .y = 3 }, .{ .x = 11, .y = 1 }));
    try std.testing.expect(floor.isInside(.{ .x = 9, .y = 7 }, .{ .x = 9, .y = 5 }));
    try std.testing.expect(floor.isInside(.{ .x = 9, .y = 5 }, .{ .x = 2, .y = 3 }));
    // Not allowed: the part 1 winner 2,5 to 11,1 pokes outside the loop.
    try std.testing.expect(!floor.isInside(.{ .x = 2, .y = 5 }, .{ .x = 11, .y = 1 }));
    // Not allowed: 7,1 to 11,7 covers the notch at the bottom left of 9,7.
    try std.testing.expect(!floor.isInside(.{ .x = 7, .y = 1 }, .{ .x = 11, .y = 7 }));
}

test "U-shaped loop: a rectangle across the gap is rejected" {
    // A U opening upward; spanning the two arms covers the empty middle.
    const u =
        \\0,0
        \\2,0
        \\2,4
        \\4,4
        \\4,0
        \\6,0
        \\6,6
        \\0,6
    ;
    const red = try parseTiles(std.testing.allocator, u);
    defer std.testing.allocator.free(red);
    var floor = try CompressedFloor.init(std.testing.allocator, red);
    defer floor.deinit(std.testing.allocator);

    try std.testing.expect(!floor.isInside(.{ .x = 0, .y = 0 }, .{ .x = 6, .y = 0 }));
    try std.testing.expect(floor.isInside(.{ .x = 0, .y = 0 }, .{ .x = 2, .y = 4 }));
    try std.testing.expect(floor.isInside(.{ .x = 2, .y = 4 }, .{ .x = 6, .y = 6 }));
}
