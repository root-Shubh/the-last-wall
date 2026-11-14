# Balance

# Balance

Headless balance simulator (SVTLW-91). The class is `BalanceSim` in `game/systems/balance_sim.gd`. It lives under `game/` because `res://` cannot reach the repo-level `tools/` folder. It is pure: it uses `DamageCalculator` for every hit and reads the unit, enemy and upgrade `.tres` files. Report script: `game/tests/balance_report.gd`.

## Model and limits

- Reference wave: 10 undead infantry, 6 runners, 2 armoured brutes, 2 shield bearers, 2 climbers.
- Builds use archers, crossbowmen and gunners. Upgrade effects apply to archers only, as `battlefield.gd` does.
- Range, shields and targeting are ignored. Crits count at their expected value.
- DPS is the mean per unit against the reference mix. Time to kill is the mean for one enemy.
- Survival assumes each unit group fires only at the wave during its walk window, which overstates kills when groups share the wave. Survival is an optimistic upper bound.
- Wall damage counts one attack per enemy that leaks past the wall.
- Build cost is recruit cost plus the cost of every upgrade level bought.

## Results per build

| Build | DPS vs reference wave | Mean time to kill (s) | Wall damage per wave | Survival | Income per wave | Build cost | DPS per 100 gold |
|---|---|---|---|---|---|---|---|
| archers | 45.68 | 1.69 | 0.0 | 100% | 52.0 | 200 | 22.84 |
| archers_damage | 71.93 | 0.27 | 0.0 | 100% | 52.0 | 463 | 15.54 |
| archers_speed | 81.91 | 0.28 | 0.0 | 100% | 52.0 | 449 | 18.24 |
| crossbow_line | 72.26 | 0.22 | 0.0 | 100% | 52.0 | 355 | 20.36 |
| gunner_battery | 80.94 | 0.19 | 0.0 | 100% | 52.0 | 420 | 19.27 |

Build definitions are in `BalanceSim.standard_builds()`.

## Findings

Flag rules: an upgrade step is flagged when its DPS gain per gold is above 2x the median step. A build is flagged when its DPS per 100 gold is above 1.5x the next best build. An upgrade is flagged when its first level costs more than 2 waves of baseline income.

- No build is flagged. The best build (archers, 22.84) is 1.12x the next best (crossbow line, 20.36).
- No upgrade is flagged as unaffordable. The most expensive first level is Mortar Repairs at 40 gold, against 52 gold of income per wave for the baseline build.
- Upgrade steps flagged for DPS gain per gold (median 0.0348 DPS per gold):
  - archer_damage levels 1 to 4: 0.262, 0.175, 0.117 and 0.078 DPS per gold.
  - archer_attack_speed levels 1 and 3: 0.218 and 0.114 DPS per gold.
- Proposed changes, not applied (story says to list them only):
  - Sharper Arrows (`archer_damage.tres`): consider a higher base cost or a higher cost multiplier, so early levels are less cheap relative to the rest. Test the change in the simulator first.
  - Quick Draw (`archer_attack_speed.tres`): same check.
  - The median is set by the many late, expensive levels. The flags may only show a steep early curve, which can be intended. Confirm with play testing before changing values.

## Open issues

- Survival is 100% for every build, so the reference wave is too easy to tell builds apart. A harder reference wave is needed before survival can guide balance. Using `WaveCatalog` instead of a fixed mix is the likely next step.
- Shield bearers, range and armour penetration on archers are not modelled.
- Nothing here changes balance values. Apply proposals only in a later story.

## Generic balance for playtest (SVTLW-64 to 84 branch)

The numbers in the game are generic defaults chosen for a first playable build, not tuned values:

- Upgrade cost: 25 gold times the current level, for buildings and defence structures.
- Ability cooldowns: Rain of Arrows 300 ticks, Emergency Repair 450, Reinforcement 600, Last Stand 900. Last Stand gives 60 ticks of wall immunity.
- Region 1 objectives: 5 armoured brute kills, wall above half health at each wave end, no unit losses, and the Fallen Kingdom boss.
- The Abomination: 600 health, hits of 12 or more are not reduced, lighter hits take 40 percent. Phases at 70, 40 and 15 percent health.
- Wave 1000 final battle: phases end at 10, 25 and 45 cumulative kills. Overlords arrive every 120 ticks in phases 1 and 3. Overseer interventions switch off a defence slot for 90 ticks every 180 ticks in phases 2 and 3.
- Simulation Exploitation effects: a proposal for where each effect applies (see battlefield.gd). Values come from the research definitions.

Tune these after the first playtest. Record each change here with the playtest notes that led to it.
