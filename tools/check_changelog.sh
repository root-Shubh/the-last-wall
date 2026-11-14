#!/usr/bin/env bash
# Changelog gate (SVTLW-101). A change to game code or docs must come with a CHANGELOG.md entry.
# Usage: bash tools/check_changelog.sh <base-ref>   e.g. origin/develop
set -u

BASE="${1:-origin/develop}"
changed="$(git diff --name-only "$BASE"...HEAD)"

if ! printf '%s\n' "$changed" | grep -qE '^(game/|docs/)'; then
	echo "No game or docs changes. Changelog entry not required."
	exit 0
fi

if printf '%s\n' "$changed" | grep -qx 'CHANGELOG.md'; then
	echo "CHANGELOG.md is updated. OK."
	exit 0
fi

echo "FAIL: game or docs changed, but CHANGELOG.md has no entry in this change."
exit 1
