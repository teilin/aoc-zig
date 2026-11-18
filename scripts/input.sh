#!/usr/bin/env bash
# Create the puzzle input file for one day: src/solvers/<year>/data/dayNN.txt
#
#   scripts/input.sh <year> <day>
#
# Downloads the input when an Advent of Code session cookie is available,
# otherwise asks you to paste it (finish with Ctrl-D).
#
# Session cookie, first one found wins:
#   1. $AOC_SESSION
#   2. .aoc-session in the repo root (git-ignored)
#   3. ~/.config/aoc/session
# Get it from your browser's cookies for adventofcode.com (the "session" value).
#
# Environment:
#   FORCE=1          overwrite an existing input file
#   PASTE=1          skip downloading and paste the input instead
#   AOC_USER_AGENT   User-Agent sent to adventofcode.com. AoC asks automated
#                    tools to identify themselves, e.g. "aoc-zig by you@example.com"

set -euo pipefail

year="${1:-}"
day="${2:-}"
if ! [[ "$year" =~ ^[0-9]{4}$ && "$day" =~ ^[0-9]{1,2}$ ]] || (( 10#$day < 1 || 10#$day > 25 )); then
    echo "usage: $0 <year> <day>   (e.g. $0 2025 7)" >&2
    exit 2
fi
day=$((10#$day))

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dir="$root/src/solvers/$year/data"
file="$dir/$(printf 'day%02d.txt' "$day")"
rel="${file#"$root"/}"

if [[ -s "$file" && "${FORCE:-}" != 1 ]]; then
    echo "$rel already exists (use FORCE=1 to replace it)."
    exit 0
fi

session="${AOC_SESSION:-}"
for f in "$root/.aoc-session" "${XDG_CONFIG_HOME:-$HOME/.config}/aoc/session"; do
    [[ -z "$session" && -r "$f" ]] && session="$(tr -d ' \t\r\n' < "$f")"
done

mkdir -p "$dir"
tmp="$(mktemp "$dir/.input.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

if [[ -n "$session" && "${PASTE:-}" != 1 ]]; then
    url="https://adventofcode.com/$year/day/$day/input"
    echo "Downloading $url"
    # The cookie goes in through stdin so it never shows up in the process list.
    if ! printf 'Cookie: session=%s\n' "$session" | curl --fail --silent --show-error \
        --user-agent "${AOC_USER_AGENT:-aoc-zig input script}" \
        --header @- --output "$tmp" "$url"; then
        echo "Download failed. The puzzle may not be unlocked yet, or the session cookie has expired." >&2
        echo "Run again with PASTE=1 to paste the input instead." >&2
        exit 1
    fi
else
    if [[ -t 0 ]]; then
        [[ -z "$session" ]] && echo "No AoC session cookie found, so paste the input instead (see $0 for how to download)."
        echo "Paste the input for $year day $day, then press Ctrl-D on an empty line:"
    fi
    cat > "$tmp"
fi

if [[ ! -s "$tmp" ]] || ! grep -q '[^[:space:]]' "$tmp"; then
    echo "No input received, nothing written." >&2
    exit 1
fi
# Make sure the file ends with exactly one newline, like a downloaded input.
[[ -n "$(tail -c1 "$tmp")" ]] && echo >> "$tmp"

mv "$tmp" "$file"
trap - EXIT
echo "Wrote $rel ($(wc -l < "$file") lines)"
