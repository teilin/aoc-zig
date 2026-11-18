# Day 8: Playground

Compute the squared distance of all 499,500 pairs (no square roots needed for
ordering), sort once, and connect pairs in that order with union-find.

* **Part 1:** after the first 1000 pairs, multiply the three largest circuit
  sizes. Pairs already in the same circuit still count toward the 1000.
* **Part 2:** keep going until one circuit is left; multiply the X coordinates
  of the pair that joined the last two.

Ties in distance are ordered by box index so the result never changes between
runs.
