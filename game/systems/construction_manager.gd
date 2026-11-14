## Owns building construction: cost check, slot occupancy and tick-driven progress (SVTLW-53).
## Gold is spent through the state node only once a start is accepted, so a refused start spends nothing.
## Completed buildings stay on their slot. Effects of finished buildings come in later stories.
class_name ConstructionManager
extends Node

signal construction_started(building_id: String, slot: int)
signal construction_progress(building_id: String, slot: int, progress: int, build_time: int)
signal construction_completed(building_id: String, slot: int)

@export var definitions: Array[BuildingDefinition] = []

var state: Node = null
## Each entry: {"building_id": String, "slot": int, "progress": int}. Unfinished builds only.
var active: Array[Dictionary] = []
var _completed: Dictionary = {}   # building_id -> slot
var _slot_owner: Dictionary = {}  # slot -> building_id (active or completed)
var _by_id: Dictionary = {}


func _ready() -> void:
	_rebuild_index()


func _rebuild_index() -> void:
	_by_id.clear()
	for definition: BuildingDefinition in definitions:
		_by_id[definition.building_id] = definition


func definition(building_id: String) -> BuildingDefinition:
	if _by_id.is_empty():
		_rebuild_index()
	return _by_id.get(building_id, null)


## Empty string when the building can be started on this slot now. Otherwise the reason it cannot.
func start_block_reason(building_id: String, slot: int) -> String:
	var data: BuildingDefinition = definition(building_id)
	if data == null:
		return "unknown building"
	if _completed.has(building_id) or _is_active(building_id):
		return "already under construction"
	if slot < 0:
		return "invalid slot"
	if data.required_slot >= 0 and slot != data.required_slot:
		return "requires slot %d" % data.required_slot
	if _slot_owner.has(slot):
		return "slot occupied"
	if not _gold().can_afford(data.build_cost):
		return "not enough gold"
	var material_costs: Dictionary = {"wood": data.wood_cost, "stone": data.stone_cost, "iron": data.iron_cost}
	for material: String in GameState.MATERIAL_IDS:
		if not _gold().can_afford_material(material, material_costs[material]):
			return "not enough %s" % material
	return ""


## Starts a build on a free slot. Returns false and changes nothing if it is refused.
func start_construction(building_id: String, slot: int) -> bool:
	if start_block_reason(building_id, slot) != "":
		return false
	var data: BuildingDefinition = definition(building_id)
	# The start check covers every cost, so these spends cannot fail once it has passed.
	_gold().spend_gold(data.build_cost)
	_gold().spend_material("wood", data.wood_cost)
	_gold().spend_material("stone", data.stone_cost)
	_gold().spend_material("iron", data.iron_cost)
	active.append({"building_id": building_id, "slot": slot, "progress": 0})
	_slot_owner[slot] = building_id
	construction_started.emit(building_id, slot)
	return true


## Advances every active build by one tick. A build that reaches its build time completes.
func on_tick(_tick_index: int) -> void:
	for entry: Dictionary in active.duplicate():
		var building_id: String = entry["building_id"]
		var slot: int = entry["slot"]
		var data: BuildingDefinition = definition(building_id)
		entry["progress"] = int(entry["progress"]) + 1
		construction_progress.emit(building_id, slot, entry["progress"], data.build_time_ticks)
		if entry["progress"] >= data.build_time_ticks:
			active.erase(entry)
			_completed[building_id] = slot
			construction_completed.emit(building_id, slot)


func is_built(building_id: String) -> bool:
	return _completed.has(building_id)


## Slot a building was placed on, finished or still under construction. -1 if none.
func slot_of(building_id: String) -> int:
	if _completed.has(building_id):
		return int(_completed[building_id])
	for entry: Dictionary in active:
		if entry["building_id"] == building_id:
			return int(entry["slot"])
	return -1


func built_count() -> int:
	return _completed.size()


func progress_of(building_id: String) -> int:
	for entry: Dictionary in active:
		if entry["building_id"] == building_id:
			return int(entry["progress"])
	return 0


func _is_active(building_id: String) -> bool:
	for entry: Dictionary in active:
		if entry["building_id"] == building_id:
			return true
	return false


func _gold() -> Node:
	return state
