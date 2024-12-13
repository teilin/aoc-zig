const std = @import("std");

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day12.txt");
    const p1 = try part1(allocator, content);
    std.debug.print("Part 1 -> {d}\n", .{p1});
    const p2 = try part2(allocator, content);
    std.debug.print("Part 2 -> {d}", .{p2});
}

fn part1(allocator: std.mem.Allocator, content: []const u8) !u64 {
    const width = std.mem.indexOfScalar(u8, content, '\n').?;
    const stride = width + 1;
    var height: usize = 0;
    {
        var lines_iter = std.mem.splitScalar(u8, content, '\n');
        while (lines_iter.next()) |line| {
            if (line.len == 0) continue;
            height += 1;
        }
    }

    const array = Array{ .buf = content, .stride = stride, .width = width, .height = height };

    var seen = std.AutoHashMap(Position, void).init(allocator);
    defer seen.deinit();
    var regions = try std.ArrayList(Region).initCapacity(allocator, 128);
    defer regions.deinit();
    defer for (regions.items) |*region| region.deinit();

    for (0..height) |row| {
        for (0..width) |col| {
            const pos = Position{ .row = @intCast(row), .col = @intCast(col) };
            if (seen.contains(pos)) continue;
            const item = array.at(pos.row, pos.col) orelse unreachable;

            var region = Region{
                .positions = try std.ArrayList(Position).initCapacity(allocator, 128),
                .item = item,
            };

            try collectRegion(&array, item, pos, &region.positions, &seen);
            try regions.append(region);
        }
    }

    var sum: u64 = 0;
    for (regions.items) |region| {
        const area = region.area();
        const perimeter = region.perimeter(&array);
        sum += area * perimeter;
    }
    return sum;
}

const Array = struct {
    buf: []const u8,
    stride: usize,
    width: usize,
    height: usize,

    fn at(self: *const @This(), row: isize, col: isize) ?u8 {
        if (row < 0 or col < 0) return null;
        const r = @as(usize, @intCast(row));
        const c = @as(usize, @intCast(col));
        if (r >= self.height or c >= self.width) return null;
        const idx = r * self.stride + c;
        return self.buf[idx];
    }
};

const Position = struct {
    row: isize,
    col: isize,
};

const SideDir = enum { vertical, horizontal };

const Region = struct {
    positions: std.ArrayList(Position),
    item: u8,

    const Self = @This();

    fn area(self: *const Self) u64 {
        return self.positions.items.len;
    }

    fn perimeter(self: *const Self, array: *const Array) u64 {
        var p: u64 = 0;
        for (self.positions.items) |pos| {
            for (makeNeighbors(pos)) |n| {
                if (array.at(n.row, n.col)) |v| {
                    if (v != self.item) p += 1;
                } else {
                    p += 1;
                }
            }
        }
        return p;
    }

    fn side_count(self: *Self, array: *const Array) u64 {
        var sides: u64 = 0;

        const less_then_row = struct {
            fn lessThen(_: void, lhs: Position, rhs: Position) bool {
                return lhs.row < rhs.row;
            }
        }.lessThen;
        const less_then_col = struct {
            fn lessThen(_: void, lhs: Position, rhs: Position) bool {
                return lhs.col < rhs.col;
            }
        }.lessThen;

        // top/bottom sides
        {
            std.sort.block(Position, self.positions.items, {}, less_then_col);
            std.sort.block(Position, self.positions.items, {}, less_then_row);
            inline for (.{ -1, 1 }) |offset| {
                var active_pos: ?Position = null;
                for (self.positions.items) |pos| {
                    const neighbor_pos: Position = .{ .row = pos.row + offset, .col = pos.col };
                    const neighbor = array.at(neighbor_pos.row, neighbor_pos.col);
                    const has_side = neighbor == null or neighbor.? != self.item;
                    if (active_pos != null and (pos.row != active_pos.?.row or pos.col != active_pos.?.col + 1)) {
                        sides += 1;
                        active_pos = null;
                    }
                    if (active_pos != null) {
                        if (has_side) {
                            active_pos = pos;
                        } else {
                            sides += 1;
                            active_pos = null;
                        }
                    } else {
                        if (has_side) {
                            active_pos = pos;
                        }
                    }
                }
                if (active_pos != null) {
                    sides += 1;
                }
            }
        }

        // left/right sides
        {
            std.sort.block(Position, self.positions.items, {}, less_then_row);
            std.sort.block(Position, self.positions.items, {}, less_then_col);
            inline for (.{ -1, 1 }) |offset| {
                var active_pos: ?Position = null;
                for (self.positions.items) |pos| {
                    const left_neighbor_pos: Position = .{ .row = pos.row, .col = pos.col + offset };
                    const left_neighbor = array.at(left_neighbor_pos.row, left_neighbor_pos.col);
                    const has_left_side = left_neighbor == null or left_neighbor.? != self.item;
                    if (active_pos != null and (pos.col != active_pos.?.col or pos.row != active_pos.?.row + 1)) {
                        sides += 1;
                        active_pos = null;
                    }
                    if (active_pos != null) {
                        if (has_left_side) {
                            active_pos = pos;
                        } else {
                            sides += 1;
                            active_pos = null;
                        }
                    } else {
                        if (has_left_side) {
                            active_pos = pos;
                        }
                    }
                }
                if (active_pos != null) {
                    sides += 1;
                }
            }
        }

        return sides;
    }

    fn deinit(self: *Self) void {
        self.positions.deinit();
    }
};

fn makeNeighbors(pos: Position) [4]Position {
    return [_]Position{
        .{ .row = pos.row + 1, .col = pos.col },
        .{ .row = pos.row - 1, .col = pos.col },
        .{ .row = pos.row, .col = pos.col + 1 },
        .{ .row = pos.row, .col = pos.col - 1 },
    };
}

fn collectRegion(array: *const Array, item: u8, start: Position, positions: *std.ArrayList(Position), seen_positions: *std.AutoHashMap(Position, void)) !void {
    if (seen_positions.contains(start)) return;
    if (array.at(start.row, start.col) != item) return;
    try positions.append(start);
    try seen_positions.put(start, {});

    for (makeNeighbors(start)) |p| {
        try collectRegion(array, item, p, positions, seen_positions);
    }
}

fn part2(allocator: std.mem.Allocator, content: []const u8) !u64 {
    const width = std.mem.indexOfScalar(u8, content, '\n').?;
    const stride = width + 1;
    var height: usize = 0;
    {
        var line_iter = std.mem.splitScalar(u8, content, '\n');
        while (line_iter.next()) |line| {
            if (line.len == 0) continue;
            height += 1;
        }
    }

    const array = Array{ .buf = content, .stride = stride, .width = width, .height = height };

    var seen = std.AutoHashMap(Position, void).init(allocator);
    defer seen.deinit();
    var regions = try std.ArrayList(Region).initCapacity(allocator, 128);
    defer regions.deinit();
    defer for (regions.items) |*region| region.deinit();

    for (0..height) |row| {
        for (0..width) |col| {
            const pos = Position{ .row = @intCast(row), .col = @intCast(col) };
            if (seen.contains(pos)) continue;
            const item = array.at(pos.row, pos.col) orelse unreachable;

            var region = Region{
                .positions = try std.ArrayList(Position).initCapacity(allocator, 128),
                .item = item,
            };

            try collectRegion(&array, item, pos, &region.positions, &seen);
            try regions.append(region);
        }
    }

    var sum: u64 = 0;
    for (regions.items) |*region| sum += region.area() * region.side_count(&array);
    return sum;
}

test "part1 test 1" {
    const content =
        \\AAAA
        \\BBCD
        \\BBCC
        \\EEEC
    ;
    try std.testing.expectEqual(140, part1(std.testing.allocator, content));
}

test "part1 test 2" {
    const content =
        \\00000
        \\0X0X0
        \\00000
        \\0X0X0
        \\00000
    ;
    try std.testing.expectEqual(772, part1(std.testing.allocator, content));
}

test "part2 test 1" {
    const content =
        \\AAAA
        \\BBCD
        \\BBCC
        \\EEEC
    ;
    try std.testing.expectEqual(80, part2(std.testing.allocator, content));
}

test "part2 test 2" {
    const content =
        \\00000
        \\0X0X0
        \\00000
        \\0X0X0
        \\00000
    ;
    try std.testing.expectEqual(432, part2(std.testing.allocator, content));
}

test "part2 test 3" {
    const content =
        \\EEEEE
        \\EXXXX
        \\EEEEE
        \\EXXXX
        \\EEEEE
    ;
    try std.testing.expectEqual(236, part2(std.testing.allocator, content));
}

test "part2 test 4" {
    const content =
        \\AAAAAA
        \\AAABBA
        \\AAABBA
        \\ABBAAA
        \\ABBAAA
        \\AAAAAA
    ;
    try std.testing.expectEqual(368, part2(std.testing.allocator, content));
}
