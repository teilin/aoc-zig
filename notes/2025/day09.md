# Day 9: Movie Theater

* **Part 1:** try every pair of red tiles.
* **Part 2:** the floor is about 98,000 × 98,000 tiles, too big to fill. Only the
  X and Y values the red tiles use matter, so shrink the floor: one cell per
  distinct value plus one for each gap between them (about 500 × 500). Draw the
  loop, flood-fill the outside from the border, and build a 2D running total of
  outside cells. A rectangle is allowed when it contains no outside cells, which
  takes four lookups.

A U-shaped loop is the tricky case: all four corners can be on the loop while
the rectangle covers the empty middle.
