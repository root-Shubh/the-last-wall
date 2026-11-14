# Roadmap

Milestones are tracked in Jira project SVTLW. Epics are SVTLW-1 to SVTLW-19.

## Status

| Milestone | Scope | Status |
|---|---|---|
| M1 | Vertical slice | Done in code and headless tests. Not yet playtested by eye (see report below). |
| M2 | Core game | Not started |
| M3 | Progression | Not started |
| M4 | Narrative | Not started |
| M5 | Long-term progression | Not started |
| M6 | Endgame | Not started |
| M7 | Production quality | Not started. Includes final art and audio (SVTLW-86 to SVTLW-88). |
| M8 | Release candidate | Not started |

## M1 report (SVTLW-48)

**What M1 contains.** A player can press Play, pick a character and name, watch the opening intro, recruit archers, start waves, see wall damage and resources on the top bar, buy upgrades through the battlefield systems, save and reload, and quit. Waves 1 to 10 come from data.

**Tests run.** 20 headless suites, 265 checks, all passing on Godot 4.7.2. The suites run in CI on every pull request (`.github/workflows/tests.yml`), and the workflow passed on the M1 pull requests.

**Not verified.** No human has played the game by eye. The checks confirm logic, layout values and signal behaviour, not how the game looks or feels. The first real playtest is the next step, before M2 begins.

**Known gaps for M1 (not blockers for the logic, but visible to a player).**
- All art is coloured blocks (placeholder, per `docs/ART_STANDARDS.md`).
- Audio is recorded as events only. No sound plays yet (SVTLW-88).
- Menus, picker and dialogue box are unstyled.
- Settings and Credits menu entries emit signals with no screens behind them.
- Balance numbers (gold, costs, enemy stats) are first-pass values.

**Milestone verdict.** M1 is complete as a code deliverable. It is not complete as a playable, polished slice until the playtest above has been done and its findings have been logged.

## M1 tickets

- SVTLW-20 to SVTLW-50 are Done, except SVTLW-48, which is this report.
- SVTLW-98 (save overwrite bug) and SVTLW-99 (launchable game) are Done.

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

## Release checklist

Run through this list for every release candidate (M8 onwards). Tick each box with the evidence in the release notes.

- [ ] Build exports on a clean machine: `tools/build_windows.ps1` produces `build/TheLastWall.exe`, and it runs with no Godot install present.
- [ ] All test suites pass on Windows, Linux and macOS (`tools/run_tests.sh` in CI).
- [ ] Save migrations pass: every older save version loads and upgrades without loss.
- [ ] Performance numbers recorded in `docs/PERFORMANCE.md` at 100, 250, 500 and 1000 enemies.
- [ ] Steam flag off by default: the Steam feature is disabled in the default build settings.
- [ ] Credits and licences complete: every asset is listed in `assets/CREDITS.md` with source and licence.
- [ ] Version bumped: `config/version` in `game/project.godot` matches the release tag.
- [ ] Changelog compiled from `changelog.d/`: fragments are moved into `CHANGELOG.md` and the fragments are removed.

## Process per ticket

1. Branch `feature-SVTLW-<n>` from `develop`.
2. Commit as `SVTLW-<n> #comment <summary>`, and post the same summary to Jira.
3. Open a pull request into `develop` that lists testing and known issues.
4. Merge after CI passes. Release promotion follows develop → qa → staging → release → master.
