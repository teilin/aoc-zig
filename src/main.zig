const std = @import("std");
const model = @import("./model.zig");
const Solver = @import("solver.zig").Solver;

const usage_text =
    \\Usage: aoc-zig [options]
    \\
    \\Run the selected AOC solution
    \\
    \\Options:
    \\ -y, --year <year>
    \\ -d, --day <day>
    \\
;

const Command = struct { raw_cmd: []const u8, argv: []const []const u8 };

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try std.process.argsAlloc(arena);

    var commands = std.array_list.Managed(Command).init(arena);

    var y: u64 = 2024;
    var d: u64 = 1;

    var arg_i: usize = 1;
    while (arg_i < args.len) : (arg_i += 1) {
        const arg = args[arg_i];
        if (!std.mem.startsWith(u8, arg, "-")) {
            var cmd_argv = std.array_list.Managed([]const u8).init(arena);
            try parseCmd(&cmd_argv, arg);
            try commands.append(.{
                .raw_cmd = arg,
                .argv = try cmd_argv.toOwnedSlice(),
            });
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            // Print usage_text
            return std.process.cleanExit();
        } else if (std.mem.eql(u8, arg, "-y") or std.mem.eql(u8, arg, "--year")) {
            arg_i += 1;
            if (arg_i >= args.len) {
                std.debug.print("'{s}' requires  a year.\n{s}", .{ arg, usage_text });
                std.process.exit(1);
            }
            const next = args[arg_i];
            const year = std.fmt.parseInt(u64, next, 10) catch |err| {
                std.debug.print("unable to parse --year argument '{s}': {s}\n", .{
                    next,
                    @errorName(err),
                });
                std.process.exit(1);
            };
            y = year;
        } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--day")) {
            arg_i += 1;
            if (arg_i >= args.len) {
                std.debug.print("'{s}' requires a day.\n{s}", .{ arg, usage_text });
                return std.process.exit(1);
            }
            const next = args[arg_i];
            const day = std.fmt.parseInt(u64, next, 10) catch |err| {
                std.debug.print("unable to parse --day argument '{s}': {s}\n", .{
                    next,
                    @errorName(err),
                });
                std.process.exit(1);
            };
            d = day;
        } else {
            std.debug.print("unrecognized argument: '{s}'\n{s}", .{ arg, usage_text });
            std.process.exit(1);
        }
    }

    const puzzel = try model.Puzzle.init(y, d);

    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();

    try Solver.init(allocator, puzzel);
}

fn parseCmd(list: *std.array_list.Managed([]const u8), cmd: []const u8) !void {
    var it = std.mem.tokenizeScalar(u8, cmd, ' ');
    while (it.next()) |s| try list.append(s);
}
