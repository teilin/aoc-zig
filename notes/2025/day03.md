# Day 3: Lobby

One function, `maxJoltage(bank, count)`, solves both parts (2 batteries for
part 1, 12 for part 2).

Greedy: pick the digits from left to right. For each one, take the largest digit
that still leaves enough batteries after it to finish the number, and on a tie
take the leftmost, so more batteries are left for later. A bigger digit earlier
always beats anything that could come after it, so this is optimal.
