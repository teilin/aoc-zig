# Day 6: Trash Compactor

Whitespace matters, so lines are kept exactly as they are; anything past the
end of a shorter line counts as a space. The sheet is cut into problems at
columns that are blank in every row, and the operator is the `+`/`*` in the
bottom row.

* **Part 1:** each row in a problem is one number.
* **Part 2:** each column is one number, read top to bottom. The puzzle reads
  right to left, but `+` and `*` don't care about order.

Watch out for editors that strip trailing spaces from the input file; there is a
test that covers it.
