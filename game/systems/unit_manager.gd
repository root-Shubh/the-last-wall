## Recruits and tracks defenders (SVTLW-32). Recruiting spends gold through GameState and
## needs free population. A fallen unit frees its population slot so it can be replaced.
class_name UnitManager
extends Node2D

signal unit_recruited(archer: Archer)
signal unit_lost(archer: Archer)

@export var unit_definitions: Array[UnitDefinition] = []
@export var population_cap: int = 5
@export var rng_seed: int = 1

var archers: Array[Archer] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _by_id: Dictionary = {}


func _ready() -> void:
	_rng.seed = rng_seed
	_rebuild_index()


func _rebuild_index() -> void:
	_by_id.clear()
	for definition: UnitDefinition in unit_definitions:
		_by_id[definition.unit_id] = definition


## Upgrade multipliers applied to every archer, present and future (SVTLW-39).
var archer_damage_multiplier: float = 1.0
var archer_speed_multiplier: float = 1.0
## Targeting applied to new recruits and to archers when no single unit is named (SVTLW-58).
var default_targeting_mode: int = Targeting.Mode.CLOSEST
var default_priority_id: String = ""


## Sets targeting for one archer when unit is given, otherwise for every archer and future recruits.
func set_targeting_mode(mode: int, priority_id: String = "", unit: Archer = null) -> void:
	if unit != null:
		unit.set_targeting_mode(mode, priority_id)
		return
	default_targeting_mode = mode
	default_priority_id = priority_id
	for archer: Archer in archers:
		archer.set_targeting_mode(mode, priority_id)


func set_archer_multipliers(damage: float, speed: float) -> void:
	archer_damage_multiplier = damage
	archer_speed_multiplier = speed
	for archer: Archer in archers:
		archer.damage_multiplier = damage
		archer.attack_speed_multiplier = speed


func population_used() -> int:
	var used: int = 0
	for archer: Archer in archers:
		used += archer.definition.population_cost
	return used


func can_recruit(unit_id: String) -> bool:
	return _recruit_error(unit_id) == ""


## Empty string when unit_id can be recruited now, otherwise the reason (public wrapper for UI, SVTLW-52).
func recruit_block_reason(unit_id: String) -> String:
	return _recruit_error(unit_id)


## Returns the new unit, or null if recruiting is refused. Reasons are reported by _recruit_error.
func recruit(unit_id: String, at: Vector2) -> Archer:
	var reason: String = _recruit_error(unit_id)
	if reason != "":
		push_warning("UnitManager: cannot recruit '%s': %s" % [unit_id, reason])
		return null
	var definition: UnitDefinition = _by_id[unit_id]
	_state().spend_gold(definition.recruit_cost)
	return _spawn(definition, at)


## Puts a unit back on the field from a save without spending gold (SVTLW-44).
## Population is still checked. Returns null if it does not fit.
func restore_unit(unit_id: String, at: Vector2) -> Archer:
	if _by_id.is_empty():
		_rebuild_index()
	if not _by_id.has(unit_id):
		return null
	var definition: UnitDefinition = _by_id[unit_id]
	if population_used() + definition.population_cost > population_cap:
		return null
	return _spawn(definition, at)


func _spawn(definition: UnitDefinition, at: Vector2) -> Archer:
	var archer: Archer = Archer.new()
	add_child(archer)
	archer.setup(definition, at, _rng)
	archer.damage_multiplier = archer_damage_multiplier
	archer.attack_speed_multiplier = archer_speed_multiplier
	archer.set_targeting_mode(default_targeting_mode, default_priority_id)
	archer.died.connect(_on_archer_died)
	archers.append(archer)
	unit_recruited.emit(archer)
	return archer


func on_tick(tick_index: int, enemies: Array) -> void:
	for archer: Archer in archers.duplicate():
		archer.on_tick(tick_index, enemies)


## Gold source. Set by the owner (the battlefield or a test). Defaults to the GameState autoload.
var state: Node = null


func _state() -> Node:
	if state == null:
		state = get_node_or_null("/root/GameState")
	return state


func _recruit_error(unit_id: String) -> String:
	if _by_id.is_empty():
		_rebuild_index()
	if not _by_id.has(unit_id):
		return "unknown unit"
	var definition: UnitDefinition = _by_id[unit_id]
	if population_used() + definition.population_cost > population_cap:
		return "no population slot free"
	if not _state().can_afford(definition.recruit_cost):
		return "not enough gold"
	return ""


func _on_archer_died(archer: Archer) -> void:
	archers.erase(archer)
	unit_lost.emit(archer)
	archer.queue_free()
