# Changelog fragments

Each pull request adds one file here instead of editing `CHANGELOG.md`, so pull requests never conflict on the changelog.

- File name: the Jira key, for example `SVTLW-62.md`.
- Content: one or more bullet lines, each starting with `- `, in the form `- <what changed> (SVTLW-62).`
- Section: start the file with a heading `### Added`, `### Changed` or `### Fixed`.

The changelog gate (`tools/check_changelog.sh`) passes a pull request that changes `game/` or `docs/` only if it adds a fragment here or edits `CHANGELOG.md` directly. At release time the fragments are collected into `CHANGELOG.md`.
