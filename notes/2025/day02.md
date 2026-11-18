# Day 2: Gift Shop

Each ID in a range is written out as digits into a small buffer on the stack,
then checked for a repeating pattern: the digits "have period `k`" when every
digit equals the one `k` places before it.

* **Part 1:** even length, and the period is half the length.
* **Part 2:** some period from 1 up to half the length divides the length.

Checking every ID one by one is fast enough here (about a second in Debug).
