const clap = @import("clap");
const std = @import("std");
const model = @import("./model.zig");
const Solver = @import("solver.zig").Solver;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-y, --year             Year of the puzzel
        \\-d, --day <usize>      An option parameter, which takes a value.
        \\-f, --file <str>...    An option parameter which can be specified multiple times.
        \\<str>...
        \\
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});
    if (res.args.day) |n|
        std.debug.print("--day = {}\n", .{n});
    if (res.args.year != 0) |y|
        std.debug.print("--year = {}", .{y});
    for (res.args.file) |s|
        std.debug.print("--file = {s}\n", .{s});
    for (res.positionals[0]) |pos|
        std.debug.print("{s}\n", .{pos});

    const puzzel = try model.Puzzle.init(res.args.year, res.args.day, res.args.file);

    Solver.init(puzzel);
}
