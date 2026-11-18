const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = @embedFile("./data/day10.txt");
    const solution = try fewestPresses(gpa.allocator(), content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

const max_counters = 16;
const max_buttons = 16;
const impossible = std.math.maxInt(u32);

const Counters = [max_counters]u16;

const Machine = struct {
    /// Bit i set = light i must end up on.
    lights: u16 = 0,
    counter_count: usize = 0,
    /// Bit i set = button toggles light i / bumps counter i.
    buttons: [max_buttons]u16 = undefined,
    button_count: usize = 0,
    joltage: Counters = @splat(0),

    fn parse(line: []const u8) !Machine {
        var m = Machine{};
        var light_count: usize = 0;
        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        while (parts.next()) |part| {
            if (part.len < 2) return error.BadMachine;
            const body = part[1 .. part.len - 1];
            switch (part[0]) {
                '[' => {
                    if (body.len > max_counters) return error.TooManyLights;
                    for (body, 0..) |c, i| {
                        if (c == '#') m.lights |= @as(u16, 1) << @intCast(i);
                    }
                    light_count = body.len;
                },
                '(' => {
                    if (m.button_count == max_buttons) return error.TooManyButtons;
                    var mask: u16 = 0;
                    var nums = std.mem.tokenizeScalar(u8, body, ',');
                    while (nums.next()) |n| {
                        const i = try std.fmt.parseInt(u4, n, 10);
                        mask |= @as(u16, 1) << i;
                    }
                    m.buttons[m.button_count] = mask;
                    m.button_count += 1;
                },
                '{' => {
                    var nums = std.mem.tokenizeScalar(u8, body, ',');
                    while (nums.next()) |n| {
                        if (m.counter_count == max_counters) return error.TooManyCounters;
                        m.joltage[m.counter_count] = try std.fmt.parseInt(u16, n, 10);
                        m.counter_count += 1;
                    }
                },
                else => return error.BadMachine,
            }
        }
        if (light_count != m.counter_count) return error.LightCounterMismatch;
        return m;
    }
};

fn fewestPresses(allocator: std.mem.Allocator, input: []const u8) !Answer {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        const machine = try Machine.parse(line);
        var solver = try Solver.init(allocator, &machine);
        defer solver.deinit();

        const lights = solver.fewestForLights(machine.lights);
        const joltage = try solver.fewestForJoltage(machine.joltage);
        if (lights == impossible or joltage == impossible) return error.NoSolution;
        part1 += lights;
        part2 += joltage;
    }
    return .{ .part1 = part1, .part2 = part2 };
}

/// Every subset of buttons, each pressed once, grouped by which counters it
/// leaves odd. That odd/even pattern is also exactly which lights the subset
/// toggles on, so the same table answers both parts.
const Solver = struct {
    const Combo = struct { added: Counters, presses: u32 };
    const ComboList = std.array_list.Managed(Combo);

    counter_count: usize,
    /// by_parity[mask] = subsets that leave exactly the counters in `mask` odd.
    by_parity: []ComboList,
    memo: std.AutoHashMap(Counters, u32),

    fn init(allocator: std.mem.Allocator, machine: *const Machine) !Solver {
        const by_parity = try allocator.alloc(ComboList, @as(usize, 1) << @intCast(machine.counter_count));
        for (by_parity) |*list| list.* = ComboList.init(allocator);
        errdefer {
            for (by_parity) |*list| list.deinit();
            allocator.free(by_parity);
        }

        const subsets = @as(usize, 1) << @intCast(machine.button_count);
        for (0..subsets) |subset| {
            var combo = Combo{ .added = @splat(0), .presses = @popCount(subset) };
            var parity: u16 = 0;
            for (machine.buttons[0..machine.button_count], 0..) |mask, b| {
                if (subset & (@as(usize, 1) << @intCast(b)) == 0) continue;
                parity ^= mask;
                for (0..machine.counter_count) |c| {
                    if (mask & (@as(u16, 1) << @intCast(c)) != 0) combo.added[c] += 1;
                }
            }
            try by_parity[parity].append(combo);
        }

        return .{
            .counter_count = machine.counter_count,
            .by_parity = by_parity,
            .memo = std.AutoHashMap(Counters, u32).init(allocator),
        };
    }

    fn deinit(self: *Solver) void {
        const allocator = self.memo.allocator;
        for (self.by_parity) |*list| list.deinit();
        allocator.free(self.by_parity);
        self.memo.deinit();
    }

    /// Part 1: pressing a button twice undoes it, so only the set of buttons
    /// pressed an odd number of times matters.
    fn fewestForLights(self: *const Solver, lights: u16) u32 {
        var best: u32 = impossible;
        for (self.by_parity[lights].items) |combo| best = @min(best, combo.presses);
        return best;
    }

    /// Part 2. In any solution, the buttons pressed an odd number of times
    /// form a subset S that leaves the same counters odd as the target.
    /// Taking S away leaves only even press counts, which is the same
    /// problem for the halved target. So:
    ///
    ///   fewest(t) = min over matching S of |S| + 2 * fewest((t - S) / 2)
    ///
    /// The target halves at every step, so this only recurses about
    /// log2(max joltage) levels deep.
    fn fewestForJoltage(self: *Solver, target: Counters) !u32 {
        if (std.mem.allEqual(u16, target[0..self.counter_count], 0)) return 0;
        if (self.memo.get(target)) |known| return known;

        var parity: u16 = 0;
        for (target[0..self.counter_count], 0..) |t, c| {
            if (t % 2 == 1) parity |= @as(u16, 1) << @intCast(c);
        }

        var best: u32 = impossible;
        combos: for (self.by_parity[parity].items) |combo| {
            var rest: Counters = @splat(0);
            for (0..self.counter_count) |c| {
                if (combo.added[c] > target[c]) continue :combos;
                rest[c] = (target[c] - combo.added[c]) / 2;
            }
            const sub = try self.fewestForJoltage(rest);
            if (sub == impossible) continue;
            best = @min(best, combo.presses + 2 * sub);
        }

        try self.memo.put(target, best);
        return best;
    }
};

const example =
    \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
;

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 7), (try fewestPresses(std.testing.allocator, example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 33), (try fewestPresses(std.testing.allocator, example)).part2);
}

test "each example machine on its own" {
    const expected = [_][2]u32{ .{ 2, 10 }, .{ 3, 12 }, .{ 2, 11 } };
    var lines = std.mem.tokenizeScalar(u8, example, '\n');
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        const machine = try Machine.parse(line);
        var solver = try Solver.init(std.testing.allocator, &machine);
        defer solver.deinit();
        try std.testing.expectEqual(expected[i][0], solver.fewestForLights(machine.lights));
        try std.testing.expectEqual(expected[i][1], try solver.fewestForJoltage(machine.joltage));
    }
}

test "unreachable target is reported as impossible" {
    // Counter 1 can never move, but it has to reach 1.
    const machine = try Machine.parse("[..] (0) {2,1}");
    var solver = try Solver.init(std.testing.allocator, &machine);
    defer solver.deinit();
    try std.testing.expectEqual(impossible, solver.fewestForLights(0b10));
    try std.testing.expectEqual(impossible, try solver.fewestForJoltage(machine.joltage));
}
