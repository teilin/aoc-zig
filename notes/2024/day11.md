# Day 11

# First iteration

For the first part...

```
fn blinkingStones(allocator: std.mem.Allocator, content: []const u8, rounds: usize) !u64 {
    var arr = std.ArrayList(usize).init(allocator);
    defer arr.deinit();

    var iter = std.mem.tokenizeSequence(u8, std.mem.trim(u8, content, "\n"), " ");
    while (iter.next()) |elm| {
        const num = try std.fmt.parseUnsigned(usize, elm, 10);
        try arr.append(num);
    }

    for (0..rounds) |_| {
        var i: usize = 0;
        while (i < arr.items.len) : (i += 1) {
            const stone = arr.items[i];
            const digits = if (stone == 0) 0 else std.math.log10(stone) + 1;
            if (stone == 0) {
                arr.items[i] = 1;
            } else if (digits % 2 == 0) {
                const half_digits = digits / 2;
                const divisor = std.math.pow(usize, 10, half_digits);
                const left = stone / divisor;
                const right = stone % divisor;
                arr.items[i] = left;
                try arr.insert(i + 1, right);
                i += 1;
            } else {
                arr.items[i] *= 2024;
            }
        }
    }

    return arr.items.len;
}
```
