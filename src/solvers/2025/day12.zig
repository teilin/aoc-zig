const std = @import("std");

const Answer = struct { part1: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day12.txt");
    const solution = try regionsThatFit(gpa.allocator(), content);
    std.debug.print("Part 1 -> {d}", .{solution.part1});
}

const max_shapes = 16;
const max_shape_cells = 16;

/// Packed so two cells can be compared with `==` (used by std.mem.eql).
const Cell = packed struct { r: i8, c: i8 };

/// One rotation/flip of a shape. Cells are sorted top-to-bottom,
/// left-to-right and shifted so the first cell is at (0, 0). That way,
/// "place this so it covers the first empty cell" means anchoring cell 0
/// there.
const Orientation = struct {
    cells: [max_shape_cells]Cell = undefined,
    len: usize = 0,

    fn slice(self: *const Orientation) []const Cell {
        return self.cells[0..self.len];
    }

    fn lessThan(_: void, a: Cell, b: Cell) bool {
        return if (a.r != b.r) a.r < b.r else a.c < b.c;
    }

    fn normalized(cells: []const Cell) Orientation {
        var o = Orientation{ .len = cells.len };
        @memcpy(o.cells[0..cells.len], cells);
        std.mem.sort(Cell, o.cells[0..o.len], {}, lessThan);
        const first = o.cells[0];
        for (o.cells[0..o.len]) |*cell| {
            cell.r -= first.r;
            cell.c -= first.c;
        }
        return o;
    }

    fn eql(a: *const Orientation, b: *const Orientation) bool {
        return std.mem.eql(Cell, a.slice(), b.slice());
    }
};

const Shape = struct {
    orientations: [8]Orientation = undefined,
    orientation_count: usize = 0,
    cell_count: usize = 0,
    /// Side of the smallest square box that holds the shape in any rotation.
    box: usize = 0,

    fn fromCells(cells: []const Cell) Shape {
        var shape = Shape{ .cell_count = cells.len };
        var max_r: i8 = 0;
        var max_c: i8 = 0;
        for (cells) |cell| {
            max_r = @max(max_r, cell.r);
            max_c = @max(max_c, cell.c);
        }
        shape.box = @intCast(@max(max_r, max_c) + 1);

        // All 8 rotations and flips, keeping only the distinct ones.
        var buf: [max_shape_cells]Cell = undefined;
        for (0..8) |t| {
            for (cells, 0..) |cell, i| {
                const c = if (t >= 4) -cell.c else cell.c;
                buf[i] = switch (t % 4) {
                    0 => .{ .r = cell.r, .c = c },
                    1 => .{ .r = c, .c = -cell.r },
                    2 => .{ .r = -cell.r, .c = -c },
                    else => .{ .r = -c, .c = cell.r },
                };
            }
            const o = Orientation.normalized(buf[0..cells.len]);
            const seen = for (shape.orientations[0..shape.orientation_count]) |*existing| {
                if (existing.eql(&o)) break true;
            } else false;
            if (!seen) {
                shape.orientations[shape.orientation_count] = o;
                shape.orientation_count += 1;
            }
        }
        return shape;
    }
};

const Region = struct {
    width: usize,
    height: usize,
    counts: [max_shapes]u32 = @splat(0),
};

fn regionsThatFit(allocator: std.mem.Allocator, input: []const u8) !Answer {
    var shapes: [max_shapes]Shape = undefined;
    var shape_count: usize = 0;
    var fits: u64 = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \r");
        if (line.len == 0) continue;

        if (std.mem.indexOfScalar(u8, line, 'x') != null) {
            const region = try parseRegion(line);
            if (try canFit(allocator, shapes[0..shape_count], region)) fits += 1;
        } else if (line[line.len - 1] == ':') {
            const index = try std.fmt.parseInt(usize, line[0 .. line.len - 1], 10);
            if (index != shape_count or index >= max_shapes) return error.ShapesOutOfOrder;
            shapes[index] = try parseShape(&lines);
            shape_count += 1;
        } else return error.BadLine;
    }
    return .{ .part1 = fits };
}

/// Reads diagram rows until a blank line.
fn parseShape(lines: *std.mem.SplitIterator(u8, .scalar)) !Shape {
    var cells: [max_shape_cells]Cell = undefined;
    var n: usize = 0;
    var r: i8 = 0;
    while (lines.next()) |raw| : (r += 1) {
        const row = std.mem.trim(u8, raw, " \r");
        if (row.len == 0) break;
        for (row, 0..) |ch, c| {
            if (ch != '#') continue;
            if (n == max_shape_cells) return error.ShapeTooBig;
            cells[n] = .{ .r = r, .c = @intCast(c) };
            n += 1;
        }
    }
    if (n == 0) return error.EmptyShape;
    return Shape.fromCells(cells[0..n]);
}

fn parseRegion(line: []const u8) !Region {
    const x = std.mem.indexOfScalar(u8, line, 'x').?;
    const colon = std.mem.indexOfScalar(u8, line, ':') orelse return error.BadRegion;
    var region = Region{
        .width = try std.fmt.parseInt(usize, line[0..x], 10),
        .height = try std.fmt.parseInt(usize, line[x + 1 .. colon], 10),
    };
    var nums = std.mem.tokenizeScalar(u8, line[colon + 1 ..], ' ');
    var i: usize = 0;
    while (nums.next()) |n| : (i += 1) {
        if (i == max_shapes) return error.TooManyCounts;
        region.counts[i] = try std.fmt.parseInt(u32, n, 10);
    }
    return region;
}

fn canFit(allocator: std.mem.Allocator, shapes: []const Shape, region: Region) !bool {
    var cells_needed: usize = 0;
    var presents: usize = 0;
    var box: usize = 1;
    for (shapes, 0..) |shape, i| {
        cells_needed += shape.cell_count * region.counts[i];
        presents += region.counts[i];
        if (region.counts[i] > 0) box = @max(box, shape.box);
    }
    for (region.counts[shapes.len..]) |c| if (c != 0) return error.UnknownShape;

    // Quick no: not enough room even if presents packed perfectly.
    const area = region.width * region.height;
    if (cells_needed > area) return false;
    // Quick yes: every present gets its own box, no interlocking needed.
    if ((region.width / box) * (region.height / box) >= presents) return true;

    // Otherwise, search for a real packing.
    var packer = try Packer.init(allocator, shapes, region, area - cells_needed);
    defer packer.deinit(allocator);
    return packer.search(0);
}

/// Exact backtracking. It always works on the first empty cell: either a
/// present covers it (with that present's first cell), or it's left empty
/// for good. Only `slack` cells can be left empty, since the rest are
/// needed for presents.
const Packer = struct {
    shapes: []const Shape,
    width: usize,
    height: usize,
    filled: []bool,
    remaining: [max_shapes]u32,
    presents_left: usize,
    slack: usize,

    fn init(allocator: std.mem.Allocator, shapes: []const Shape, region: Region, slack: usize) !Packer {
        const filled = try allocator.alloc(bool, region.width * region.height);
        @memset(filled, false);
        var presents: usize = 0;
        for (region.counts[0..shapes.len]) |c| presents += c;
        return .{
            .shapes = shapes,
            .width = region.width,
            .height = region.height,
            .filled = filled,
            .remaining = region.counts,
            .presents_left = presents,
            .slack = slack,
        };
    }

    fn deinit(self: *Packer, allocator: std.mem.Allocator) void {
        allocator.free(self.filled);
    }

    fn search(self: *Packer, start: usize) bool {
        if (self.presents_left == 0) return true;

        var idx = start;
        while (idx < self.filled.len and self.filled[idx]) idx += 1;
        if (idx == self.filled.len) return false;

        for (self.shapes, 0..) |*shape, s| {
            if (self.remaining[s] == 0) continue;
            for (shape.orientations[0..shape.orientation_count]) |*o| {
                if (!self.fits(o, idx)) continue;
                self.set(o, idx, true);
                self.remaining[s] -= 1;
                self.presents_left -= 1;
                const done = self.search(idx + 1);
                self.presents_left += 1;
                self.remaining[s] += 1;
                self.set(o, idx, false);
                if (done) return true;
            }
        }

        // Leave this cell empty.
        if (self.slack == 0) return false;
        self.slack -= 1;
        self.filled[idx] = true;
        const done = self.search(idx + 1);
        self.filled[idx] = false;
        self.slack += 1;
        return done;
    }

    fn fits(self: *const Packer, o: *const Orientation, anchor: usize) bool {
        const r0: isize = @intCast(anchor / self.width);
        const c0: isize = @intCast(anchor % self.width);
        for (o.slice()) |cell| {
            const r = r0 + cell.r;
            const c = c0 + cell.c;
            if (r < 0 or c < 0 or r >= self.height or c >= self.width) return false;
            if (self.filled[@as(usize, @intCast(r)) * self.width + @as(usize, @intCast(c))]) return false;
        }
        return true;
    }

    fn set(self: *Packer, o: *const Orientation, anchor: usize, value: bool) void {
        const r0 = anchor / self.width;
        const c0: isize = @intCast(anchor % self.width);
        for (o.slice()) |cell| {
            const r = r0 + @as(usize, @intCast(cell.r));
            const c: usize = @intCast(c0 + cell.c);
            self.filled[r * self.width + c] = value;
        }
    }
};

const example =
    \\0:
    \\###
    \\##.
    \\##.
    \\
    \\1:
    \\###
    \\##.
    \\.##
    \\
    \\2:
    \\.##
    \\###
    \\##.
    \\
    \\3:
    \\##.
    \\###
    \\##.
    \\
    \\4:
    \\###
    \\#..
    \\###
    \\
    \\5:
    \\###
    \\.#.
    \\###
    \\
    \\4x4: 0 0 0 0 2 0
    \\12x5: 1 0 1 0 2 2
    \\12x5: 1 0 1 0 3 2
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 2), (try regionsThatFit(std.testing.allocator, example)).part1);
}

test "example regions one by one need the real search" {
    // Each region on its own, so a wrong answer points at the right one.
    const shapes_only = example[0 .. std.mem.indexOf(u8, example, "4x4").?];
    const cases = [_]struct { line: []const u8, fits: u64 }{
        .{ .line = "4x4: 0 0 0 0 2 0", .fits = 1 },
        .{ .line = "12x5: 1 0 1 0 2 2", .fits = 1 },
        .{ .line = "12x5: 1 0 1 0 3 2", .fits = 0 },
    };
    for (cases) |case| {
        const input = try std.mem.concat(std.testing.allocator, u8, &.{ shapes_only, case.line });
        defer std.testing.allocator.free(input);
        try std.testing.expectEqual(case.fits, (try regionsThatFit(std.testing.allocator, input)).part1);
    }
}

test "orientations: symmetric shapes collapse" {
    // A plus sign looks the same every way round; an L has all 8 forms.
    const plus = Shape.fromCells(&.{ .{ .r = 0, .c = 1 }, .{ .r = 1, .c = 0 }, .{ .r = 1, .c = 1 }, .{ .r = 1, .c = 2 }, .{ .r = 2, .c = 1 } });
    try std.testing.expectEqual(@as(usize, 1), plus.orientation_count);
    const ell = Shape.fromCells(&.{ .{ .r = 0, .c = 0 }, .{ .r = 1, .c = 0 }, .{ .r = 2, .c = 0 }, .{ .r = 2, .c = 1 } });
    try std.testing.expectEqual(@as(usize, 8), ell.orientation_count);
    // Example shape 5 (###/.#./###) only has 2 distinct forms.
    const h = Shape.fromCells(&.{ .{ .r = 0, .c = 0 }, .{ .r = 0, .c = 1 }, .{ .r = 0, .c = 2 }, .{ .r = 1, .c = 1 }, .{ .r = 2, .c = 0 }, .{ .r = 2, .c = 1 }, .{ .r = 2, .c = 2 } });
    try std.testing.expectEqual(@as(usize, 2), h.orientation_count);
}
