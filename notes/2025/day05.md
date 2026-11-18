# Day 5: Cafeteria

Sort the ranges by start and merge any that overlap, touch (`3-5` and `6-7`)
or sit inside another.

* **Part 1:** binary search each ID in the merged ranges.
* **Part 2:** merged ranges don't overlap, so add up `last - first + 1`. The
  input has about 3.5 × 10¹⁴ fresh IDs, so this never visits them one at a time.
