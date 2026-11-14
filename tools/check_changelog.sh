#!/usr/bin/env bash
# Changelog gate (SVTLW-101, SVTLW-102). A change to game code or docs must come with a changelog entry:
# either an edit to CHANGELOG.md, or a new fragment file under changelog.d/ (one per pull request).
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

fragments="$(printf '%s\n' "$changed" | grep -E '^changelog\.d/.+\.md$' | grep -v '^changelog\.d/README\.md$')"
if [ -n "$fragments" ]; then
	echo "A changelog fragment is added under changelog.d/. OK."
	exit 0
fi

echo "FAIL: game or docs changed, but there is no CHANGELOG.md edit and no fragment under changelog.d/."
echo "Add changelog.d/<JIRA-KEY>.md (see changelog.d/README.md)."
exit 1
