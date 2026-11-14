## Central damage pipeline (SVTLW-35). All damage in the game goes through here.
## Order: base x upgrade multiplier x critical, then armour (floored at zero), then resistance.
## Pure functions with no state, so every rule can be unit tested headlessly.
## M1 uses the physical damage type only. Elemental types come with the Arcane branch (M3).
class_name DamageCalculator
extends RefCounted

enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING, POISON, HOLY }

## Percentage of damage kept after resistance: 0.0 means fully resisted, 1.0 means none.
## Resistance above 1.0 is allowed for vulnerability (e.g. 1.5 takes 50 percent more).
static func calculate(
	base_damage: float,
	upgrade_multiplier: float,
	crit_chance: float,
	crit_multiplier: float,
	armour: float,
	resistance: float,
	roll: float,
) -> float:
	var damage: float = base_damage * maxf(upgrade_multiplier, 0.0)
	if roll < clampf(crit_chance, 0.0, 1.0):
		damage *= maxf(crit_multiplier, 1.0)
	damage = maxf(damage - maxf(armour, 0.0), 0.0)
	damage *= maxf(resistance, 0.0)
	return damage


## Returns true when a roll in [0, 1) lands a critical hit for the given chance.
static func is_critical(crit_chance: float, roll: float) -> bool:
	return roll < clampf(crit_chance, 0.0, 1.0)
