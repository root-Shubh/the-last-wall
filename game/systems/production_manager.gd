## Passive production from completed buildings (SVTLW-55). Each production interval adds output through GameState.
## Upgrades raise the level and multiply output. Gold for upgrades is spent by the caller, not here.
## Register a building from ConstructionManager.construction_completed. The levels are mirrored into
## GameState.production_levels so they save with the game.
class_name ProductionManager
extends Node

signal rates_changed(wood: float, stone: float, iron: float)
## Emitted when a building hands out resources, so the battle can show the gain (feedback).
signal produced(building_id: String, resource: String, amount: int)

const LEVEL_MULTIPLIER: float = 1.5

@export var definitions: Array[BuildingDefinition] = []
## Injected state node (GameState in the game, a fresh node in tests).
var state: Node = null
var _by_id: Dictionary = {}


func _rebuild_index() -> void:
	_by_id.clear()
	for definition: BuildingDefinition in definitions:
		_by_id[definition.building_id] = definition


func definition(building_id: String) -> BuildingDefinition:
	if _by_id.is_empty():
		_rebuild_index()
	return _by_id.get(building_id, null)


## Adds a completed production building at level 1. Returns false for non-production or already registered buildings.
func register(building_id: String) -> bool:
	var data: BuildingDefinition = definition(building_id)
	if data == null or data.production_resource == "" or data.production_per_interval <= 0 or data.production_interval_ticks <= 0:
		return false
	if is_registered(building_id):
		return false
	state.production_levels[building_id] = 1
	_emit_rates()
	return true


func is_registered(building_id: String) -> bool:
	return state.production_levels.has(building_id)


func level_of(building_id: String) -> int:
	return int(state.production_levels.get(building_id, 0))


## Raises the level by one and multiplies output. Returns false when not registered or already at max level.
func upgrade(building_id: String) -> bool:
	if not is_registered(building_id):
		return false
	var data: BuildingDefinition = definition(building_id)
	if level_of(building_id) >= maxi(data.max_level, 1):
		return false
	state.production_levels[building_id] = level_of(building_id) + 1
	_emit_rates()
	return true


## Units of output one interval produces at the building's current level, before exposure.
func output_per_interval(building_id: String) -> int:
	var data: BuildingDefinition = definition(building_id)
	if data == null or not is_registered(building_id):
		return 0
	return int(floor(data.production_per_interval * pow(LEVEL_MULTIPLIER, level_of(building_id) - 1)))


## Sum of output per tick for one resource across registered buildings, for the HUD and tests.
func production_per_tick_for(resource: String) -> float:
	var total: float = 0.0
	for building_id: String in state.production_levels:
		var data: BuildingDefinition = definition(building_id)
		if data != null and data.production_resource == resource:
			total += float(output_per_interval(building_id)) / float(data.production_interval_ticks)
	return total


## Rebuilds the registered list from GameState after a load.
func load_from_state() -> void:
	_emit_rates()


## Runs one tick. Every production_interval_ticks each registered building adds its output.
func on_tick(tick_index: int) -> void:
	var ticks_done: int = tick_index + 1
	for building_id: String in state.production_levels.keys():
		var data: BuildingDefinition = definition(building_id)
		if data == null or ticks_done % data.production_interval_ticks != 0:
			continue
		var interval_index: int = ticks_done / data.production_interval_ticks
		var amount: int = output_per_interval(building_id)
		if _is_exposed(building_id, interval_index, data.exposure_chance_per_interval):
			amount -= 1
		state.add_material(data.production_resource, amount)
		if amount > 0:
			produced.emit(building_id, data.production_resource, amount)


## Deterministic roll: the same building and interval always give the same answer.
func _is_exposed(building_id: String, interval_index: int, chance: float) -> bool:
	if chance <= 0.0:
		return false
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = ("%s:%d" % [building_id, interval_index]).hash()
	return rng.randf() < chance


func _emit_rates() -> void:
	rates_changed.emit(production_per_tick_for("wood"), production_per_tick_for("stone"), production_per_tick_for("iron"))
