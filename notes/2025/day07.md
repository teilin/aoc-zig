# Day 7: Laboratories

Walk down the grid one row at a time, keeping a count of timelines in each
column, starting with 1 at `S`. A `.` passes its count straight down; a `^`
counts a split and sends its count both left and right. Beams landing in the
same column add their counts, which is the merge from part 1.

* **Part 1:** splitters reached by at least one beam.
* **Part 2:** total of all counts after the last row.

Assumption: a beam split off the edge of the grid still counts as a finished
timeline (the puzzle doesn't say, and the example has no edge splitters).

Status: tested on the example; not yet run on the real input.
