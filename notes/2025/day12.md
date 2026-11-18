# Day 12: Christmas Tree Farm

Each region goes through up to three checks:

1. **Quick no:** the presents need more cells than the region has.
2. **Quick yes:** the region has enough 3×3 boxes to give every present its own.
3. **Exact search:** backtracking over the first empty cell, either covering it
   with a present or leaving it empty, limited by how many cells can be spared.

The real input is fully decided by checks 1 and 2 (526 no, 474 yes), but the
example isn't: its two 12×5 regions need the search to tell them apart.

Part 2 has no puzzle; it's the free star for finishing everything else.
