## Pure target selection for archers (SVTLW-58). No scene or state access, so every mode is testable.
## Each mode takes the candidate enemies, the archer's position and range, and returns one Enemy or null.
## Rules shared by all modes: dead or invalid enemies are ignored, and an enemy must be within
## attack_range (distance <= range) to be considered. Ties keep the later candidate, as closest always did.
##   CLOSEST: smallest distance from the archer.
##   STRONGEST: highest definition.max_health.
##   WEAKEST: lowest current health.
##   HIGHEST_WALL_THREAT: smallest global x, i.e. the enemy nearest the wall line (the one about to attack it).
##   PRIORITY_TYPE: only enemies whose definition.enemy_id equals priority_id; closest of those wins.
##     Returns null when no such enemy is in range, so the archer holds fire rather than switching target.
class_name Targeting
extends RefCounted

enum Mode { CLOSEST, STRONGEST, WEAKEST, HIGHEST_WALL_THREAT, PRIORITY_TYPE }


static func mode_name(mode: int) -> String:
	match mode:
		Mode.CLOSEST: return "closest"
		Mode.STRONGEST: return "strongest"
		Mode.WEAKEST: return "weakest"
		Mode.HIGHEST_WALL_THREAT: return "highest_wall_threat"
		Mode.PRIORITY_TYPE: return "priority_type"
	return "unknown"


static func select(mode: int, candidates: Array, origin: Vector2, attack_range: float, priority_id: String = "") -> Enemy:
	var best: Enemy = null
	var best_score: float = INF
	for candidate: Variant in candidates:
		if not is_instance_valid(candidate):
			continue
		var enemy: Enemy = candidate
		if not enemy.alive or enemy.definition == null:
			continue
		var distance: float = origin.distance_to(enemy.global_position)
		if distance > attack_range:
			continue
		var score: float = _score(mode, enemy, distance, priority_id)
		if score == INF:
			continue
		if score <= best_score:
			best = enemy
			best_score = score
	return best


## Lower score wins. INF means the enemy is not eligible for this mode.
static func _score(mode: int, enemy: Enemy, distance: float, priority_id: String) -> float:
	match mode:
		Mode.CLOSEST:
			return distance
		Mode.STRONGEST:
			return -enemy.definition.max_health
		Mode.WEAKEST:
			return enemy.health
		Mode.HIGHEST_WALL_THREAT:
			return enemy.global_position.x
		Mode.PRIORITY_TYPE:
			if enemy.definition.enemy_id != priority_id:
				return INF
			return distance
	return distance
