#!/usr/bin/env bash
# Runs every headless test suite in game/tests and exits non-zero if any suite fails (SVTLW-46).
# Usage: GODOT=/path/to/godot bash tools/run_tests.sh
# A suite fails when its process exits non-zero, when it prints SCRIPT ERROR, or when it prints no RESULT line.
set -u

GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/game"

# Build the global class cache so class_name types resolve in -s runs.
"$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1 || true

total=0
failed=0
for test_file in "$PROJECT"/tests/test_*.gd; do
	name="$(basename "$test_file" .gd)"
	total=$((total + 1))
	output="$("$GODOT" --headless --path "$PROJECT" -s "res://tests/$name.gd" 2>&1)"
	code=$?
	result="$(printf '%s\n' "$output" | grep -E '^RESULT:' | tail -1)"
	if [ "$code" -ne 0 ] || [ -z "$result" ] || printf '%s\n' "$output" | grep -q 'SCRIPT ERROR'; then
		failed=$((failed + 1))
		echo "FAIL  $name  ${result:-no RESULT line}"
		printf '%s\n' "$output" | grep -E 'SCRIPT ERROR|FAIL ' | head -5
	else
		echo "PASS  $name  ${result#RESULT: }"
	fi
done

echo "---"
echo "$((total - failed)) of $total suites passed"
[ "$failed" -eq 0 ]
