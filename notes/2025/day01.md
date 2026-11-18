# Day 1: Secret Entrance

Turning the dial left from position `p` is the mirror image of turning right
from `(100 - p) % 100`. So both directions become the same question: how many
multiples of 100 do we pass counting up from the start?

* **Part 1:** count how often the dial lands on 0.
* **Part 2:** count every pass over 0 with `@divFloor(start + distance, 100)`,
  so a long turn like `R1000` is a single division, not a step-by-step loop.
