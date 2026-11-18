const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day11.txt");
    const solution = try reactorPaths(gpa.allocator(), content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

fn reactorPaths(allocator: std.mem.Allocator, input: []const u8) !Answer {
    var graph = try Graph.parse(allocator, input);
    defer graph.deinit(allocator);

    return .{
        .part1 = try graph.countPaths(allocator, try Graph.id("you"), try Graph.id("out")),
        .part2 = try pathsViaBoth(allocator, &graph, "svr", "dac", "fft", "out"),
    };
}

/// Paths from `from` to `to` that pass through both `a` and `b`.
///
/// The graph has no loops (counting fails otherwise), so a path visits each
/// device at most once and meets `a` and `b` in one of two orders. Each
/// order splits into three independent legs whose counts multiply. At most
/// one order can have paths, since having both would mean a loop.
fn pathsViaBoth(
    allocator: std.mem.Allocator,
    graph: *const Graph,
    from: []const u8,
    a: []const u8,
    b: []const u8,
    to: []const u8,
) !u64 {
    const legs = struct {
        fn product(alloc: std.mem.Allocator, g: *const Graph, stops: [4][]const u8) !u64 {
            var total: u64 = 1;
            for (stops[0..3], stops[1..4]) |start, end| {
                const n = try g.countPaths(alloc, try Graph.id(start), try Graph.id(end));
                total = try std.math.mul(u64, total, n);
            }
            return total;
        }
    };
    const a_first = try legs.product(allocator, graph, .{ from, a, b, to });
    const b_first = try legs.product(allocator, graph, .{ from, b, a, to });
    return std.math.add(u64, a_first, b_first);
}

/// Devices keyed by their three-letter name, which maps straight to a number
/// below 26^3. Each device keeps the rest of its input line (its outputs)
/// as a slice into the input, so parsing copies nothing.
const Graph = struct {
    const DeviceId = u16;
    const device_count = 26 * 26 * 26;

    outputs: []?[]const u8,

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Graph {
        const outputs = try allocator.alloc(?[]const u8, device_count);
        @memset(outputs, null);
        errdefer allocator.free(outputs);

        var lines = std.mem.tokenizeAny(u8, input, "\r\n");
        while (lines.next()) |line| {
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse return error.BadLine;
            const device = try id(line[0..colon]);
            if (outputs[device] != null) return error.DuplicateDevice;
            outputs[device] = line[colon + 1 ..];
        }
        return .{ .outputs = outputs };
    }

    fn deinit(self: *Graph, allocator: std.mem.Allocator) void {
        allocator.free(self.outputs);
    }

    fn id(name: []const u8) !DeviceId {
        if (name.len != 3) return error.BadDeviceName;
        var n: DeviceId = 0;
        for (name) |c| {
            if (c < 'a' or c > 'z') return error.BadDeviceName;
            n = n * 26 + (c - 'a');
        }
        return n;
    }

    /// Number of distinct paths from `from` to `to`, following outputs only.
    fn countPaths(self: *const Graph, allocator: std.mem.Allocator, from: DeviceId, to: DeviceId) !u64 {
        var counter = try PathCounter.init(allocator, self, to);
        defer counter.deinit(allocator);
        return counter.count(from);
    }

    /// paths(n) = sum of paths(m) over n's outputs, with paths(to) = 1.
    /// Each device is worked out once and remembered.
    const PathCounter = struct {
        const State = enum(u8) { unvisited, in_progress, done };

        graph: *const Graph,
        to: DeviceId,
        state: []State,
        paths: []u64,

        fn init(allocator: std.mem.Allocator, graph: *const Graph, to: DeviceId) !PathCounter {
            const state = try allocator.alloc(State, device_count);
            errdefer allocator.free(state);
            const paths = try allocator.alloc(u64, device_count);
            @memset(state, .unvisited);
            return .{ .graph = graph, .to = to, .state = state, .paths = paths };
        }

        fn deinit(self: *PathCounter, allocator: std.mem.Allocator) void {
            allocator.free(self.state);
            allocator.free(self.paths);
        }

        fn count(self: *PathCounter, device: DeviceId) !u64 {
            if (device == self.to) return 1;
            switch (self.state[device]) {
                .done => return self.paths[device],
                // Coming back to a device we're still inside means a loop,
                // and a loop would allow endlessly many paths.
                .in_progress => return error.CycleDetected,
                .unvisited => {},
            }
            self.state[device] = .in_progress;

            var total: u64 = 0;
            if (self.graph.outputs[device]) |outs| {
                var names = std.mem.tokenizeScalar(u8, outs, ' ');
                while (names.next()) |name| {
                    total = try std.math.add(u64, total, try self.count(try id(name)));
                }
            }

            self.state[device] = .done;
            self.paths[device] = total;
            return total;
        }
    };
};

const example =
    \\aaa: you hhh
    \\you: bbb ccc
    \\bbb: ddd eee
    \\ccc: ddd eee fff
    \\ddd: ggg
    \\eee: out
    \\fff: out
    \\ggg: out
    \\hhh: ccc fff iii
    \\iii: out
;

const example2 =
    \\svr: aaa bbb
    \\aaa: fft
    \\fft: ccc
    \\bbb: tty
    \\tty: ccc
    \\ccc: ddd eee
    \\ddd: hub
    \\hub: fff
    \\eee: dac
    \\dac: fff
    \\fff: ggg hhh
    \\ggg: out
    \\hhh: out
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 5), (try reactorPaths(std.testing.allocator, example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 2), (try reactorPaths(std.testing.allocator, example2)).part2);
}

test "part2 example: all paths vs. paths through dac and fft" {
    var graph = try Graph.parse(std.testing.allocator, example2);
    defer graph.deinit(std.testing.allocator);
    const alloc = std.testing.allocator;
    // 8 paths in total from svr to out, listed in the puzzle text.
    try std.testing.expectEqual(@as(u64, 8), try graph.countPaths(alloc, try Graph.id("svr"), try Graph.id("out")));
    // Order doesn't matter when asking for both devices.
    try std.testing.expectEqual(@as(u64, 2), try pathsViaBoth(alloc, &graph, "svr", "fft", "dac", "out"));
    // Only fft -> dac exists here, never dac -> fft.
    try std.testing.expectEqual(@as(u64, 0), try graph.countPaths(alloc, try Graph.id("dac"), try Graph.id("fft")));
}

test "paths counted from other devices in the example" {
    var graph = try Graph.parse(std.testing.allocator, example);
    defer graph.deinit(std.testing.allocator);
    const out = try Graph.id("out");
    // ccc -> ddd->ggg->out, eee->out, fff->out
    try std.testing.expectEqual(@as(u64, 3), try graph.countPaths(std.testing.allocator, try Graph.id("ccc"), out));
    // hhh -> ccc (3), fff (1), iii (1)
    try std.testing.expectEqual(@as(u64, 5), try graph.countPaths(std.testing.allocator, try Graph.id("hhh"), out));
    // A device with no way to out has zero paths.
    try std.testing.expectEqual(@as(u64, 0), try graph.countPaths(std.testing.allocator, try Graph.id("out"), try Graph.id("you")));
}

test "a loop is reported instead of counted forever" {
    const looped =
        \\you: aaa
        \\aaa: bbb
        \\bbb: aaa out
    ;
    try std.testing.expectError(error.CycleDetected, reactorPaths(std.testing.allocator, looped));
}
