# Contributing

## Branches

- `master` only receives releases.
- `develop` is the integration branch.
- Start feature work from `develop` on `feature-SVTLW-<n>`, where `<n>` is the Jira issue number.
- Open a pull request into `develop`. Squash-merge feature branches.
- Promotion order: `develop` -> `qa` -> `staging` -> `release` -> `master`. Promotions use merge commits.
- Only feature branches are deleted after merge. All other branches are protected.

## Commits

Format: `SVTLW-<n> #comment <short summary>`

Example: `SVTLW-20 #comment create repository and initial project structure`

After each commit, post the same summary as a comment on the Jira issue.

## Changelog

Every change to `game/` or `docs/` adds a fragment file `changelog.d/<JIRA-KEY>.md` (see `changelog.d/README.md`). Do not edit `CHANGELOG.md` in a feature branch: that is what made every PR conflict (SVTLW-102).

## Pull requests

Each PR states the Jira key, what changed, how it was tested, and known issues. Visual changes include a screenshot or clip.

## Before merging

- The Godot project opens headless without errors.
- The test suite passes.
- The affected feature has been run in the game.
