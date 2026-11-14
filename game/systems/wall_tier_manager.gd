## Owns the wall tier ladder and upgrades (SVTLW-63). Gold goes through the injected state,
## and the wall stats go to the injected WallManager. Health keeps its ratio across an upgrade.
class_name WallTierManager
extends Node

signal tier_changed(tier: int)

const TIER_PATH: String = "res://resources/wall_tiers/wall_tier_%d.tres"
const TIER_COUNT: int = 7

var tiers: Array[WallTier] = []
var current_index: int = 0
var state: Node = null
var wall: WallManager = null


## Loads the seven tier files if needed, starts at tier 1 and applies its stats to the wall.
func bind(state_source: Node, wall_manager: WallManager) -> void:
	state = state_source
	wall = wall_manager
	if tiers.is_empty():
		load_default_tiers()
	current_index = 0
	_apply_stats(tiers[0])


func load_default_tiers() -> void:
	tiers.clear()
	for number: int in range(1, TIER_COUNT + 1):
		tiers.append(load(TIER_PATH % number) as WallTier)


func current_tier() -> WallTier:
	return tiers[current_index]


## Upgrades one tier. Returns false at tier 7, without an injected state, or when gold does not cover it.
func upgrade_tier() -> bool:
	if state == null or wall == null or tiers.is_empty():
		return false
	if current_index >= tiers.size() - 1:
		return false
	var next: WallTier = tiers[current_index + 1]
	var old_max: int = maxi(state.wall_max_health, 1)
	var ratio: float = float(state.wall_health) / float(old_max)
	if not state.spend_gold(next.upgrade_cost):
		return false
	state.set_wall_max_health(next.max_health)
	state.wall_health = roundi(ratio * next.max_health)
	state.wall_health_changed.emit(state.wall_health)
	current_index += 1
	_apply_stats(next)
	tier_changed.emit(next.tier)
	return true


func _apply_stats(tier: WallTier) -> void:
	state.wall_tier = tier.tier
	wall.armour = tier.armour
	wall.repair_per_second = tier.repair_per_second
