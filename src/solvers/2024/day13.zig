const std = @import("std");

const Move = struct {
    X: usize,
    Y: usize,
};

const Game = struct {
    ButtonA: Move,
    ButtonB: Move,
    Prize: Move,
};

const GameList = std.ArrayList(Game);

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day13.txt");
    const games = try parse(allocator, content);
    defer games.deinit();

    const p1 = try play(games.items);
    std.debug.print("Part 1 -> {d}\n", .{p1});

    for (games.items) |*game| {
        game.Prize.X += 10000000000000;
        game.Prize.Y += 10000000000000;
    }

    const p2 = try play(games.items);
    std.debug.print("Part 2 -> {d}\n", .{p2});
}

fn parse(allocator: std.mem.Allocator, content: []const u8) !GameList {
    var list = GameList.init(allocator);
    errdefer list.deinit();

    var iter = std.mem.tokenizeSequence(u8, content, "\n\n");
    while (iter.next()) |game| {
        var gameIter = std.mem.tokenizeAny(u8, game, "+,=\n");

        _ = gameIter.next();
        const ax = try std.fmt.parseInt(usize, gameIter.next().?, 10);
        _ = gameIter.next();
        const ay = try std.fmt.parseInt(usize, gameIter.next().?, 10);

        _ = gameIter.next();
        const bx = try std.fmt.parseInt(usize, gameIter.next().?, 10);
        _ = gameIter.next();
        const by = try std.fmt.parseInt(usize, gameIter.next().?, 10);

        _ = gameIter.next();
        const px = try std.fmt.parseInt(usize, gameIter.next().?, 10);
        _ = gameIter.next();
        const py = try std.fmt.parseInt(usize, gameIter.next().?, 10);

        try list.append(.{
            .ButtonA = .{ .X = ax, .Y = ay },
            .ButtonB = .{ .X = bx, .Y = by },
            .Prize = .{ .X = px, .Y = py },
        });
    }

    return list;
}

fn play(games: []const Game) !usize {
    var sum: usize = 0;
    for (games) |game| {
        const ax: f64 = @floatFromInt(game.ButtonA.X);
        const ay: f64 = @floatFromInt(game.ButtonA.Y);
        const bx: f64 = @floatFromInt(game.ButtonB.X);
        const by: f64 = @floatFromInt(game.ButtonB.Y);
        const px: f64 = @floatFromInt(game.Prize.X);
        const py: f64 = @floatFromInt(game.Prize.Y);

        const d = (by * ax - bx * ay);

        if (d == 0) {
            return error.InvalidInput;
        }

        const a = -(bx * py - by * px) / d;
        const b = -(px * ay - py * ax) / d;

        if (a == @round(a) and b == @round(b)) {
            sum += @intFromFloat(3 * a + b);
        }
    }
    return sum;
}

test "part1 test" {
    const content =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
    ;
    const games = try parse(std.testing.allocator, content);
    try std.testing.expectEqual(480, try play(games.items));
}
