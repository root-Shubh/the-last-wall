# Roadmap

Milestones are tracked in Jira project SVTLW. Issue keys are listed below for each milestone. Epics are SVTLW-1 to SVTLW-19.

## Status

| Milestone | Scope | Status |
|---|---|---|
| M1 | Vertical slice | In progress (SVTLW-20 done, SVTLW-21 in review, SVTLW-22 in progress) |
| M2 | Core game | Not started |
| M3 | Progression | Not started |
| M4 | Narrative | Not started |
| M5 | Long-term progression | Not started |
| M6 | Endgame | Not started |
| M7 | Production quality | Not started |
| M8 | Release candidate | Not started |

## M1: Vertical slice (SVTLW-20 to SVTLW-50)

Done when a player can start, play several waves, upgrade, save, quit, reload and continue, with no errors and passing tests.

- Repository and project structure: SVTLW-20 (done), SVTLW-21 (in review), SVTLW-22 (design docs, in progress).
- Core systems, UI, units, enemies, combat, economy, narrative, save and tests: SVTLW-23 to SVTLW-50.
- Milestone report and playtest: SVTLW-48.

## M2 to M8

Each later milestone gets its tasks broken down when it starts, not before. Stories already exist in Jira with the milestone label (`M2` to `M8`), SVTLW-51 to SVTLW-97.

| Milestone | Jira stories |
|---|---|
| M2 Core game | SVTLW-51 to SVTLW-60 |
| M3 Progression | SVTLW-61 to SVTLW-66 |
| M4 Narrative | SVTLW-67 to SVTLW-72 |
| M5 Long-term progression | SVTLW-73 to SVTLW-79 |
| M6 Endgame | SVTLW-80 to SVTLW-85 |
| M7 Production quality | SVTLW-86 to SVTLW-91 |
| M8 Release candidate | SVTLW-92 to SVTLW-97 |

## Process per ticket

1. Branch `feature-SVTLW-<n>` from `develop`.
2. Commit as `SVTLW-<n> #comment <summary>`, and post the same summary to Jira.
3. Open a pull request into `develop` that lists testing and known issues.
4. Merge after review. Release promotion follows develop → qa → staging → release → master.
