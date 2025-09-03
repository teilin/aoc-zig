const std = @import("std");

pub fn solve() !void {
    //const content = @embedFile("./data/day08.txt");
    //const part1 = try puzzel(content, .part1);
    //std.debug.print("Part 1 -> {d}\n", .{part1});
    //const part2 = try puzzel(content, .part2);
    //std.debug.print("Part 2 -> {d}\n", .{part2});
}

//fn puzzel(content: []const u8, comptime part: AocPart) !u32 {
//const l = std.mem.indexOfScalar(u8, content, '\n').? + 1;

//const m = l - 1;
//const n = content.len / l;

//var buffer: [5]struct { x: i8, y: i8 } = undefined;
//const BArr = std.ArrayListUnmanaged(struct { x: i8, y: i8 }).initBuffer(&buffer);

//var antennas = [_]BArr{try BArr.init(0)} ** (26 * 2 + 10);
//var antinodes = std.StaticBitSet(3000).initEmpty();

//var sum: u32 = 0;

//for (0.., content) |i, c| {
//    const x: i8 = @intCast(i % l);
//    const y: i8 = @intCast(i / l);

//    if (x == m or c == '.') continue;

//    const h = simpleHash(c);
//    for (antennas[h].slice()) |p| {
//        const dx = x - p.x;
//        const dy = y - p.y;

//        const start = if (comptime part == .part1) 1 else 0;
//        const end = if (comptime part == .part1) 1 else std.math.maxInt(i8);

//        inline for (.{ 0, 1 }) |t| {
//            var k: i8 = start;
//            while (k <= end) : (k += 1) {
//                const nx = if (t == 0) p.x - k * dx else x + k * dx;
//                const ny = if (t == 0) p.y - k * dy else y + k * dy;

//                if (nx < 0 or nx >= m or ny < 0 or ny >= n) break;

//                const u = @as(usize, @intCast(nx)) + @as(usize, @intCast(ny)) * l;
//                if (!antinodes.isSet(u)) {
//                    antinodes.set(u);
//                    sum += 1;
//                }
//            }
//        }
//    }

//    try antennas[h].append(.{ .x = x, .y = y });
//}

//return sum;
//}

const AocPart = enum { part1, part2 };

fn simpleHash(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'z' => c - 'a' + 10,
        'A'...'Z' => c - 'A' + 36,
        else => unreachable,
    };
}

test "part1 test" {
    //const content =
    //    \\............
    //    \\........0...
    //    \\.....0......
    //    \\.......0....
    //    \\....0.......
    //    \\......A.....
    //    \\............
    //    \\............
    //    \\........A...
    //    \\.........A..
    //    \\............
    //    \\............
    //    \\
    //;
    try std.testing.expectEqual(14, 0); //puzzel(content, .part1));
}

test "part2 test" {
    //const content =
    //    \\............
    //    \\........0...
    //    \\.....0......
    //    \\.......0....
    //    \\....0.......
    //    \\......A.....
    //    \\............
    //    \\............
    //    \\........A...
    //    \\.........A..
    //    \\............
    //    \\............
    //    \\
    //;
    try std.testing.expectEqual(34, 0); //puzzel(content, .part2));
}
