# Day 10: Factory

Build a table of every subset of buttons, each pressed once (at most 2¹³),
grouped by which counters the subset leaves odd. That pattern is also exactly
which lights the subset turns on.

* **Part 1:** pressing a button twice cancels out, so the answer is the
  smallest subset that matches the light pattern.
* **Part 2:** no integer-programming solver needed. In any solution, the
  buttons pressed an odd number of times form a subset with the same odd/even
  pattern as the target. Take it away and everything left is even, which is the
  same problem for half the target:

  `fewest(t) = min over matching S of |S| + 2 × fewest((t − S) / 2)`

  The target halves each step, so with a cache it's only about 9 levels deep.
  It is exact, because every solution breaks down this way.

Part 2 was checked against an independent Gaussian-elimination search.
