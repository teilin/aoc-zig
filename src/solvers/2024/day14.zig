const std = @import("std");

const Coordinate = [2]i64;

const Robot = struct {
    Position: Coordinate,
    Velocity: Coordinate,

    fn move(self: *Robot, width: isize, height: isize) void {
        self.Position = add(self.Position, self.Velocity);
        self.Position[0] = @mod(self.Position[0], width);
        self.Position[1] = @mod(self.Position[1], height);
    }
};

const RobotList = std.ArrayList(Robot);

fn add(a: Coordinate, b: Coordinate) Coordinate {
    return Coordinate{ a[0] + b[0], a[1] + b[1] };
}

pub fn solve(allocator: std.mem.Allocator) !void {
    const content = @embedFile("./data/day14.txt");
    const p1 = try part1(allocator, content, 101, 103);
    std.debug.print("Part 1 -> {d}\n", .{p1});
    try part2(allocator, content, 101, 103);
}

fn part1(allocator: std.mem.Allocator, content: []const u8, width: isize, height: isize) !usize {
    var list = RobotList.init(allocator);
    defer list.deinit();

    var lineIter = std.mem.tokenizeSequence(u8, content, "\n");

    while (lineIter.next()) |line| {
        const robot = try parseLine(line);
        try list.append(robot);
    }

    for (0..100) |_| {
        for (list.items) |*robot| {
            robot.move(width, height);
        }
    }
    var sums = [_]usize{ 0, 0, 0, 0 };

    const WH = @divTrunc(width, 2);
    const HH = @divTrunc(height, 2);

    for (list.items) |robot| {
        if (robot.Position[0] < WH and robot.Position[1] < HH) sums[0] += 1;
        if (robot.Position[0] < WH and robot.Position[1] > HH) sums[1] += 1;
        if (robot.Position[0] > WH and robot.Position[1] < HH) sums[2] += 1;
        if (robot.Position[0] > WH and robot.Position[1] > HH) sums[3] += 1;
    }

    var saftyFactor: usize = 1;
    for (sums) |sum| saftyFactor *= sum;
    return saftyFactor;
}

fn print(allocator: std.mem.Allocator, list: *RobotList, width: isize, height: isize) !void {
    var map = std.AutoHashMap(Coordinate, void).init(allocator);
    defer map.deinit();
    for (list.items) |l| try map.put(l.Position, {});

    for (0..@intCast(height)) |y| {
        for (0..@intCast(width)) |x| {
            if (map.contains(.{ @intCast(x), @intCast(y) })) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn part2(allocator: std.mem.Allocator, content: []const u8, width: isize, height: isize) anyerror!void {
    var lineIter = std.mem.tokenizeSequence(u8, content, "\n");
    var robots = RobotList.init(allocator);
    defer robots.deinit();

    while (lineIter.next()) |line| {
        const robot = try parseLine(line);
        try robots.append(robot);
    }

    //TO HIGH => 7959
    //TO HIGHT => 7093
    //To HIGHT => 7042
    //The cirrect one => 6620
    for (1..6851) |i| {
        for (robots.items) |*robot| {
            robot.move(width, height);
        }
        //if (i > 6314) {
        //    try print(allocator, &robots, width, height);
        //    std.debug.print("Seconds {d}\n", .{i});
        //    std.time.sleep(400000000);
        //}
        if (i == 6620) {
            try print(allocator, &robots, width, height);
            break;
        }
    }
}

fn parseLine(line: []const u8) !Robot {
    var robotIter = std.mem.tokenizeScalar(u8, line, ' ');
    var pIter = std.mem.tokenizeScalar(u8, robotIter.next().?, ',');
    const pIterX = pIter.next().?;
    const pIterY = pIter.next().?;
    const px: i64 = try std.fmt.parseInt(i64, pIterX[2..], 10);
    const py: i64 = try std.fmt.parseInt(i64, pIterY, 10);

    var vIter = std.mem.tokenizeScalar(u8, robotIter.next().?, ',');
    const vIterX = vIter.next().?;
    const vIterY = vIter.next().?;

    const vx: i64 = try std.fmt.parseInt(i64, vIterX[2..], 10);
    const vy: i64 = try std.fmt.parseInt(i64, vIterY, 10);

    return .{
        .Position = .{ px, py },
        .Velocity = .{ vx, vy },
    };
}

test "part1 test" {
    const content =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;
    const num = try part1(std.testing.allocator, content, 11, 7);
    try std.testing.expectEqual(12, num);
}
