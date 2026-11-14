#!/usr/bin/env bash
# Regression tests for tools/check_changelog.sh (SVTLW-102). Each case builds a throwaway repo.
set -u
GATE="$(cd "$(dirname "$0")" && pwd)/check_changelog.sh"
[ -f "$GATE" ] || { echo "gate not found: $GATE"; exit 2; }
fail=0

run_case() {
	local name="$1" expected="$2" files="$3"
	local dir; dir="$(mktemp -d)"
	(
		cd "$dir" || exit 1
		git init -q -b develop .
		git config user.email t@t && git config user.name t
		echo base > base.txt && git add . && git commit -qm base
		git checkout -qb feature
		for file in $files; do mkdir -p "$(dirname "$file")" && echo change > "$file"; done
		git add . && git commit -qm change
		bash "$GATE" develop >/dev/null 2>&1
	)
	local got=$?
	rm -rf "$dir"
	if [ "$got" -eq "$expected" ]; then
		echo "ok   - $name"
	else
		echo "FAIL - $name (expected exit $expected, got $got)"
		fail=1
	fi
}

run_case "game change with no entry fails" 1 "game/systems/x.gd"
run_case "game change with a fragment passes" 0 "game/x.gd changelog.d/SVTLW-1.md"
run_case "game change with CHANGELOG.md edit passes" 0 "game/x.gd CHANGELOG.md"
run_case "docs only also needs an entry" 1 "docs/ROADMAP.md"
run_case "README alone is not an entry for a game change" 1 "game/systems/x.gd changelog.d/README.md"

exit $fail
