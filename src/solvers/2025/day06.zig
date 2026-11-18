const std = @import("std");

const Answer = struct { part1: u64, part2: u64 };

pub fn solve() !void {
    const content = @embedFile("./data/day06.txt");
    const solution = try grandTotal(content);
    std.debug.print("Part 1 -> {d}\n", .{solution.part1});
    std.debug.print("Part 2 -> {d}", .{solution.part2});
}

const max_rows = 16;

/// The worksheet as a grid of characters. Lines may differ in length;
/// anything past the end of a line counts as a space.
const Worksheet = struct {
    rows_buf: [max_rows][]const u8 = undefined,
    row_count: usize = 0,
    width: usize = 0,

    fn parse(input: []const u8) !Worksheet {
        var sheet = Worksheet{};
        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |raw| {
            const line = std.mem.trimEnd(u8, raw, "\r");
            if (std.mem.trim(u8, line, " ").len == 0) continue;
            if (sheet.row_count == max_rows) return error.TooManyRows;
            sheet.rows_buf[sheet.row_count] = line;
            sheet.row_count += 1;
            sheet.width = @max(sheet.width, line.len);
        }
        if (sheet.row_count < 2) return error.MissingRows;
        return sheet;
    }

    /// All rows except the last one, which holds the operators.
    fn numberRows(self: *const Worksheet) []const []const u8 {
        return self.rows_buf[0 .. self.row_count - 1];
    }

    fn operatorRow(self: *const Worksheet) []const u8 {
        return self.rows_buf[self.row_count - 1];
    }

    fn at(row: []const u8, col: usize) u8 {
        return if (col < row.len) row[col] else ' ';
    }

    fn isBlankColumn(self: *const Worksheet, col: usize) bool {
        for (self.rows_buf[0..self.row_count]) |row| {
            if (at(row, col) != ' ') return false;
        }
        return true;
    }
};

const Op = enum {
    add,
    mul,

    fn identity(self: Op) u64 {
        return switch (self) {
            .add => 0,
            .mul => 1,
        };
    }

    fn apply(self: Op, acc: u64, value: u64) u64 {
        return switch (self) {
            .add => acc + value,
            .mul => acc * value,
        };
    }
};

fn grandTotal(input: []const u8) !Answer {
    const sheet = try Worksheet.parse(input);

    var part1: u64 = 0;
    var part2: u64 = 0;

    // Walk the columns and cut the sheet into problems at fully blank columns.
    var col: usize = 0;
    while (col < sheet.width) {
        if (sheet.isBlankColumn(col)) {
            col += 1;
            continue;
        }
        const start = col;
        while (col < sheet.width and !sheet.isBlankColumn(col)) col += 1;

        part1 += try solveRowWise(&sheet, start, col);
        part2 += try solveColumnWise(&sheet, start, col);
    }

    return .{ .part1 = part1, .part2 = part2 };
}

/// The operator is the one non-space symbol in the bottom row of the problem.
fn problemOp(sheet: *const Worksheet, start: usize, end: usize) !Op {
    const row = sheet.operatorRow();
    for (start..end) |c| {
        switch (Worksheet.at(row, c)) {
            '+' => return .add,
            '*' => return .mul,
            ' ' => {},
            else => return error.BadOperator,
        }
    }
    return error.MissingOperator;
}

/// Part 1: each row holds one number; alignment within the problem is ignored.
fn solveRowWise(sheet: *const Worksheet, start: usize, end: usize) !u64 {
    const op = try problemOp(sheet, start, end);
    var acc = op.identity();
    for (sheet.numberRows()) |row| {
        const slice = row[@min(start, row.len)..@min(end, row.len)];
        const digits = std.mem.trim(u8, slice, " ");
        if (digits.len == 0) continue;
        acc = op.apply(acc, try std.fmt.parseInt(u64, digits, 10));
    }
    return acc;
}

/// Part 2: each column holds one number, read top (most significant) to bottom.
/// The puzzle reads columns right to left, but + and * don't care about order.
fn solveColumnWise(sheet: *const Worksheet, start: usize, end: usize) !u64 {
    const op = try problemOp(sheet, start, end);
    var acc = op.identity();
    for (start..end) |c| {
        var value: u64 = 0;
        var has_digit = false;
        for (sheet.numberRows()) |row| {
            const ch = Worksheet.at(row, c);
            if (ch == ' ') continue;
            if (ch < '0' or ch > '9') return error.BadDigit;
            value = value * 10 + (ch - '0');
            has_digit = true;
        }
        if (has_digit) acc = op.apply(acc, value);
    }
    return acc;
}

// Trailing spaces matter here, so the example is built line by line.
const example =
    "123 328  51 64 \n" ++
    " 45 64  387 23 \n" ++
    "  6 98  215 314\n" ++
    "*   +   *   +  \n";

test "part1 example" {
    try std.testing.expectEqual(@as(u64, 4277556), (try grandTotal(example)).part1);
}

test "part2 example" {
    try std.testing.expectEqual(@as(u64, 3263827), (try grandTotal(example)).part2);
}

test "part2 example problems one by one" {
    const sheet = try Worksheet.parse(example);
    try std.testing.expectEqual(@as(u64, 8544), try solveColumnWise(&sheet, 0, 3)); // 356 * 24 * 1
    try std.testing.expectEqual(@as(u64, 625), try solveColumnWise(&sheet, 4, 7)); // 8 + 248 + 369
    try std.testing.expectEqual(@as(u64, 3253600), try solveColumnWise(&sheet, 8, 11)); // 175 * 581 * 32
    try std.testing.expectEqual(@as(u64, 1058), try solveColumnWise(&sheet, 12, 15)); // 4 + 431 + 623
}

test "trailing spaces stripped from lines still parse the same" {
    const trimmed =
        \\123 328  51 64
        \\ 45 64  387 23
        \\  6 98  215 314
        \\*   +   *   +
    ;
    const answer = try grandTotal(trimmed);
    try std.testing.expectEqual(@as(u64, 4277556), answer.part1);
    try std.testing.expectEqual(@as(u64, 3263827), answer.part2);
}
