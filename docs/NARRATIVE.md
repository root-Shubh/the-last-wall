# Narrative

To be written in M1 (opening) and extended in M4.

## Machine countermeasures (SVTLW-72)

Machines are the enemies of the simulation. Each countermeasure has one tactical rule and one counter-play rule. The rules are data in game/resources/enemies/; the damage and reward rules are pure functions on EnemyDefinition.

- **Resource Suppressor.** Rule: it grants no gold on death (gold_reward 0). Counter: it pays nothing, so kill it only when it blocks the wall; it is a tempo drain, not a health threat.
- **Damage Limiter.** Rule: no single hit deals more than 5 damage (hit_cap). Counter: use many small hits or area damage; one heavy hit is wasted, so favour sustained fire over burst.
- **Calculation Guardian.** Rule: a single hit above 200 damage is ignored entirely (immune_above_hit). Counter: split large damage into hits of 200 or less, such as several defenders or repeated attacks.
- **Process Terminator.** Rule: only melee defenders can stop it (melee_counter_only). Counter: spearmen and swordsmen. Archers cannot stop it, as with climbers.
- **Memory Devourer.** Rule: while alive, it disables one research effect (disables_research_while_alive). Counter: kill it quickly, before its disabled effect costs a wave.
- **Recursive Sentinel.** Rule: it spawns nothing, but it recovers 2 health each time it is hit (heal_on_hit), up to its maximum. Counter: deal damage in bursts, not trickles, so it cannot recover between hits.

## Factions

Enemies belong to a faction (`EnemyDefinition.faction`). The original enemies have no faction. Each new faction has one distinct mechanic, and each mechanic is expressed as data on its enemy definition.

### Corrupted (SVTLW-81)

The corruption spreads through living things. It favours fast hunting packs, venom and endurance.

- **Corrupted Predator** (`swarm`): fast pack hunter. Mechanic: speed and numbers, so area damage is the answer.
- **Poison Spitter** (`pressure`): its venom keeps working after the hit. Mechanic: `poison_damage_per_second`.
- **Regenerator** (`pressure`): heals while alive. Mechanic: `regen_per_second`, capped at max health. Focus it down quickly.

### Ancient Horde (SVTLW-81)

The Ancient Horde is the machinery of the old war, still fighting on its last orders. It favours heavy constructs, guardians and flying machines.

- **Ancient Construct** (`wall_breaker`): slow siege engine with heavy wall damage and high armour. Mechanic: armour and slowness; it drops iron on kill.
- **Guardian** (`shield_bearer`): escorts the siege lines. Mechanic: shield radius and fraction, as for the shield bearer.
- **Flying Machine** (`climber`): attacks from the air. Mechanic: `bypass_wall_armour`, so wall armour does not help against it.
- Titans are planned for a later story and are not defined yet.

Battlefield wiring for these mechanics, and their appearance in waves, is not part of SVTLW-81.
