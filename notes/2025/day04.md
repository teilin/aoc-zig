# Day 4: Printing Department

* **Part 1:** count each roll's neighbours once; the answer is the number of
  rolls with fewer than 4.
* **Part 2:** instead of repeating whole rounds, use a work queue. Removing a
  roll only lowers its neighbours' counts, so the order doesn't matter. Queue
  the rolls from part 1; whenever a removal drops a neighbour to 3, queue that
  neighbour too. Each roll is handled once.

Checked against a round-by-round simulation: same answer, after 80 rounds.
