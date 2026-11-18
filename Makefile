# Convenience wrapper around zig for aoc-zig.
#
#   make                         - build the aoc_zig executable (zig build)
#   make test                    - run `zig test` on every source file that contains tests
#   make test YEAR=2024          - only test files for one year
#   make run YEAR=2024 DAY=1     - build and run one puzzle
#   make input YEAR=2025 DAY=7   - create src/solvers/2025/data/day07.txt (download or paste;
#                                  see scripts/input.sh for the session cookie, FORCE=1, PASTE=1)
#   make list                    - show the files `make test` will run
#   make clean                   - remove build output
#
# `zig build test` only runs tests reachable from src/main.zig, which misses the
# solver tests, so `make test` runs each file with tests on its own instead.

ZIG      ?= zig
OPTIMIZE ?= Debug
YEAR     ?=
DAY      ?= 1

SRC_DIR  := src
TEST_DIR := $(if $(YEAR),$(SRC_DIR)/solvers/$(YEAR),$(SRC_DIR))

# Kept in a variable so make doesn't try to balance the regex's parentheses.
TEST_RE  := ^\s*test\s*("|\{|[A-Za-z_])
TEST_SRCS = $(sort $(shell grep -rlE --include='*.zig' '$(TEST_RE)' $(TEST_DIR) 2>/dev/null))

.PHONY: all build test run input list clean

all: build

build:
	$(ZIG) build -Doptimize=$(OPTIMIZE)

test:
	@files="$(TEST_SRCS)"; \
	if [ -z "$$files" ]; then echo "No files with tests found in $(TEST_DIR)."; exit 0; fi; \
	failed=""; \
	for f in $$files; do \
		echo "==> $$f"; \
		$(ZIG) test $$f -O $(OPTIMIZE) || failed="$$failed $$f"; \
	done; \
	if [ -n "$$failed" ]; then \
		echo; echo "FAILED:"; for f in $$failed; do echo "  $$f"; done; exit 1; \
	fi; \
	echo; echo "All tests passed."

run:
	$(ZIG) build run -Doptimize=$(OPTIMIZE) -- -y $(or $(YEAR),2024) -d $(DAY)

input:
	@test -n "$(YEAR)" || { echo "usage: make input YEAR=2025 DAY=7"; exit 2; }
	@scripts/input.sh $(YEAR) $(DAY)

list:
	@for f in $(TEST_SRCS); do echo "$$f"; done

clean:
	rm -rf .zig-cache zig-out
