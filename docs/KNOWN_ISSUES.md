# Known Issues

Each issue lists its ID, the milestone it was found in, its status, and the ticket that will fix it.

## Open

| ID | Found in | Issue | Status | Ticket |
|---|---|---|---|---|
| KI-002 | SVTLW-22 | Test framework was not chosen when the design docs were written. | Closed by SVTLW-46: a headless runner and CI workflow. GUT not adopted. | SVTLW-46 |
| KI-003 | SVTLW-21 | The `qa`, `staging` and `release` branches are not covered by the branch ruleset. | Open. Needs owner approval to change the ruleset. | Repository settings |
| KI-004 | SVTLW-29 | Enemies spawned at y=0, so archers never had them in range. | Fixed in SVTLW-29 (lane y=360). Regression covered by `test_battlefield_sim`. | SVTLW-29 |
| KI-005 | SVTLW-40 to 46 | Headless test runs print leak notices at exit ("RIDs leaked", "resources still in use"). Suites still pass. | Open. Tidy-up of test cleanup. | Follow-up |
| KI-006 | SVTLW-50 | Audio events are recorded, not played. The game is silent. | Open. Real streams and music arrive in the audio pass. | SVTLW-88 |
| KI-007 | SVTLW-99 | Placeholder art (coloured blocks) and unstyled menus. | Open. Expected for M1. | SVTLW-86, SVTLW-89 |
| KI-008 | M1 playtest | No human has played the game by eye. Logic is covered by tests; visuals and feel are not. | Open. First playtest before M2. | SVTLW-48 (report) |
| KI-009 | SVTLW-99 | Settings and Credits menu entries have no screens yet. | Open. | SVTLW-89 |
| KI-010 | SVTLW-42 | The on-screen character picker is built, but the name field and buttons are unstyled. | Open. | SVTLW-89 |

## Closed

| ID | Issue | Closed by |
|---|---|---|
| SVTLW-98 | Save deleted before a failed rename retry, losing the valid save. | Fixed in SVTLW-23 (PR #5) with a backup-and-restore step. |
| — | Projectile pool grew on every shot when `_ready` had not run. | Fixed in SVTLW-44 (warm-up on first use). |
| — | Archer targeting used the wrong lane height. | KI-004 above. |
