## Pure area-damage helpers for explosions (SVTLW-60). No state, no nodes.
class_name AreaDamage
extends RefCounted


## Damage from an explosion at a distance from its centre. Full damage at the centre, falling off
## linearly to zero at the radius. Zero at or beyond the radius, and for a non-positive radius.
static func area_damage_falloff(distance: float, radius: float, base_damage: float) -> float:
	if radius <= 0.0 or distance >= radius:
		return 0.0
	var clamped_distance: float = maxf(distance, 0.0)
	return base_damage * (1.0 - clamped_distance / radius)
