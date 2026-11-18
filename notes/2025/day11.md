# Day 11: Reactor

Device names are 3 lowercase letters, so each maps straight to a number below
26³. The graph is a flat array of slices into the input, no hash map.

* **Part 1:** `paths(n) = sum of paths(m) over n's outputs`, `paths(out) = 1`,
  cached per device. A loop would mean infinitely many paths, so it is
  reported as an error instead.
* **Part 2:** with no loops, a path meets `dac` and `fft` in one of two
  orders, and each order splits into three independent legs whose counts
  multiply:

  `svr→dac × dac→fft × fft→out + svr→fft × fft→dac × dac→out`
