# AOC-ZIG

Advent of Code (AOC) solutions in Zig programming language.

## Solutions

* [2023](./notes/2023/README.md)
* [2024](./notes/2024/README.md)
* [2025](./notes/2025/README.md)

## Usage

Requires Zig 0.17.1. Common tasks go through `make`:

```sh
make                         # build (zig build)
make run YEAR=2025 DAY=3     # run one puzzle
make test                    # run the tests in every solver file
make test YEAR=2025          # only one year's tests
make input YEAR=2025 DAY=7   # create the puzzle input file (see below)
make clean                   # remove build output
```

Add `OPTIMIZE=ReleaseFast` to any of these for an optimized build.

`make test` runs `zig test` on each source file that has tests. `zig build test`
only sees tests reachable from `src/main.zig`, which doesn't include the solvers.

## Puzzle input

Each solver embeds its input from `src/solvers/<year>/data/dayNN.txt`, so that
file has to exist before the day will build. Create it with:

```sh
make input YEAR=2025 DAY=7
```

This downloads the input if it can find your Advent of Code session cookie, and
otherwise asks you to paste the input and finish with Ctrl-D.

### Downloading

Puzzle inputs are different for every account, so downloading needs your
session cookie:

1. Log in at [adventofcode.com](https://adventofcode.com).
2. In your browser's developer tools, find the cookies for `adventofcode.com`
   and copy the value of `session`.
3. Save it in one of these places (the first one found is used):
   * the `AOC_SESSION` environment variable
   * a `.aoc-session` file in the repo root (ignored by git)
   * `~/.config/aoc/session`

```sh
echo 'your-session-cookie' > .aoc-session
make input YEAR=2025 DAY=7
```

The cookie expires after a while. If a download fails, either the puzzle isn't
unlocked yet or the cookie has expired: copy a fresh one, or paste the input
with `PASTE=1`.

Advent of Code asks scripts to identify themselves, so consider setting
`AOC_USER_AGENT`, for example `AOC_USER_AGENT="aoc-zig by you@example.com"`.

### Options

| Variable         | Effect                                              |
| ---------------- | --------------------------------------------------- |
| `FORCE=1`        | Replace an input file that already exists           |
| `PASTE=1`        | Paste the input even when a session cookie is set   |
| `AOC_SESSION`    | Session cookie to download with                     |
| `AOC_USER_AGENT` | User-Agent sent to adventofcode.com                 |

An input that already exists is never downloaded again unless you pass
`FORCE=1`, so running the command twice doesn't send a second request.
Never commit your session cookie: it gives full access to your Advent of Code
account.
