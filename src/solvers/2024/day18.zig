const std = @import("std");

fn create2DArr(comptime T: type, allocator: *const std.mem.Allocator, height: usize, width: usize) ![][]T {
    var grid: [][]T = try allocator.*.alloc([]T, height);

    var grid_idx: usize = 0;
    while (grid_idx < height) : (grid_idx += 1) {
        grid[grid_idx] = try allocator.*.alloc(T, width);
    }

    return grid;
}

fn init2DBoolArr(grid: [][]bool) void {
    var y: usize = 0;
    while (y < grid.len) : (y += 1) {
        var x: usize = 0;
        while (x < grid[y].len) : (x += 1) {
            grid[y][x] = false;
        }
    }
}

const Vec2 = struct {
    x: u32,
    y: u32,
};

const State = struct {
    xy: Vec2,
    path_length: u32,
};

fn dijkstra(allocator: *const std.mem.Allocator, grid: [][]bool, seen: [][]bool) !i32 {
    var q = std.ArrayList(State).init(allocator.*);
    defer q.deinit();

    try q.append(State{ .xy = Vec2{ .x = 0, .y = 0 }, .path_length = 0 });

    const WIDTH = grid[0].len;
    const HEIGHT = grid.len;

    while (q.items.len > 0) {
        const state: State = q.pop();
        if (seen[state.xy.y][state.xy.x])
            continue;

        seen[state.xy.y][state.xy.x] = true;

        if (state.xy.x == WIDTH - 1 and state.xy.y == HEIGHT - 1)
            return @as(i32, @intCast(state.path_length));

        var dir_idx: u32 = 0;
        while (dir_idx < 4) : (dir_idx += 1) {
            const x = switch (dir_idx) {
                0 => state.xy.x + 1,
                2 => state.xy.x -% 1,
                1, 3 => state.xy.x,
                else => unreachable,
            };

            const y = switch (dir_idx) {
                0, 2 => state.xy.y,
                1 => state.xy.y + 1,
                3 => state.xy.y -% 1,
                else => unreachable,
            };

            if (x >= WIDTH or y >= HEIGHT)
                continue;

            const grid_pos = grid[y][x];
            if (grid_pos)
                continue;

            try q.insert(0, State{ .xy = Vec2{ .x = x, .y = y }, .path_length = state.path_length + 1 });
        }
    }

    return -1;
}

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day18.txt");
    var positions = std.ArrayList(Vec2).init(allocator);
    defer positions.deinit();

    var line_iter = std.mem.tokenizeSequence(u8, content, "\n");
    while (line_iter.next()) |line| {
        var coord_iter = std.mem.tokenizeScalar(u8, line, ',');
        const raw_x = coord_iter.next().?;
        const raw_y = coord_iter.next().?;
        const x = try std.fmt.parseInt(u32, raw_x, 10);
        const y = try std.fmt.parseInt(u32, raw_y, 10);
        const pos = Vec2{ .x = x, .y = y };
        try positions.append(pos);
    }

    const width = 71;
    const height = 71;

    var grid = try create2DArr(bool, &allocator, height, width);
    init2DBoolArr(grid);

    const size_p1 = 1024;
    var pos_index: usize = 0;
    while (pos_index < size_p1) : (pos_index += 1) {
        const pos = positions.items[pos_index];
        grid[pos.y][pos.x] = true;
    }

    const seen = try create2DArr(bool, &allocator, height, width);
    init2DBoolArr(seen);

    const soln_p1 = try dijkstra(&allocator, grid, seen);
    std.debug.print("Part 1 -> {d}", .{soln_p1});

    var soln_p2: usize = 0;
    while (pos_index < positions.items.len) : (pos_index += 1) {
        const pos = positions.items[pos_index];
        grid[pos.y][pos.x] = true;

        init2DBoolArr(seen);
        if (try dijkstra(&allocator, grid, seen) < 0) {
            soln_p2 = pos_index;
            break;
        }
    }

    const soln_p2_xy = positions.items[pos_index];
    std.debug.print("Part 2 -> {},{}\n", .{ soln_p2_xy.x, soln_p2_xy.y });
}
