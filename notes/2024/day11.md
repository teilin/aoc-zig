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

## Second iteration

With allocator

```
Benchmark 1 (54 runs): ./zig-out/bin/aoc-zig -y 2024 -d 11                                                                                                                              
  measurement          mean ± σ            min … max           outliers
  wall_time          91.9ms ± 8.33ms    85.7ms …  114ms          1 ( 2%)        
  peak_rss           11.6MB ±  126KB    11.5MB … 11.9MB          4 ( 7%)        
  cpu_cycles          403M  ± 9.34M      370M  …  412M           9 (17%)        
  instructions       1.25G  ± 28.8M     1.14G  … 1.27G          10 (19%)        
  cache_references    907K  ± 14.2K      886K  …  939K           0 ( 0%)        
  cache_misses       1.01K  ±  715       339   … 3.45K           2 ( 4%)        
  branch_misses       718K  ± 16.8K      652K  …  730K           9 (17%)
```

Without allocator

```
Benchmark 1 (56 runs): ./zig-out/bin/aoc-zig -y 2024 -d 11                                                                                                                              
  measurement          mean ± σ            min … max           outliers
  wall_time          88.8ms ± 5.41ms    85.2ms …  112ms         11 (20%)        
  peak_rss           11.5MB ± 47.9KB    11.4MB … 11.7MB          7 (13%)        
  cpu_cycles          403M  ± 5.81M      373M  …  411M           3 ( 5%)        
  instructions       1.26G  ± 16.2M     1.18G  … 1.27G           2 ( 4%)        
  cache_references    899K  ± 13.6K      881K  …  954K           3 ( 5%)        
  cache_misses        882   ± 1.01K      190   … 4.93K           5 ( 9%)        
  branch_misses       704K  ± 9.07K      657K  …  711K           2 ( 4%)        
> time ./zig-out/bin/aoc-zig -y 2024 -d 11
Part 1 -> 199982
Part 2 -> 237149922829154
./zig-out/bin/aoc-zig -y 2024 -d 11  0.10s user 0.00s system 99% cpu 0.104 total
```
