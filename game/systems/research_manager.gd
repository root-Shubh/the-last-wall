## Owns the research tree and research points (SVTLW-61).
## Research points and researched ids are persisted through GameState.research (optional save field).
## Refused research changes nothing. Effects are not applied here; later code reads the definitions.
class_name ResearchManager
extends Node

signal research_completed(research_id: String)
signal points_changed(points: int)

const DEFINITIONS_DIR: String = "res://resources/research/"

var definitions: Array[ResearchDefinition] = []
var research_points: int = 0
var state: Node = null
var _researched: Dictionary = {}  # research_id -> true
var _by_id: Dictionary = {}


## Loads every .tres ResearchDefinition in the folder. Exported builds may list them as .remap files.
func load_definitions(dir_path: String) -> void:
	definitions.clear()
	for file_name: String in DirAccess.get_files_at(dir_path):
		var path: String = dir_path + file_name.replace(".remap", "")
		if not path.ends_with(".tres"):
			continue
		var data: Resource = load(path)
		if data is ResearchDefinition:
			definitions.append(data)
	definitions.sort_custom(func(a: ResearchDefinition, b: ResearchDefinition) -> bool: return a.research_id < b.research_id)
	_rebuild_index()


func _rebuild_index() -> void:
	_by_id.clear()
	for definition: ResearchDefinition in definitions:
		_by_id[definition.research_id] = definition


## Injects GameState and restores points and researched ids from it.
## Also loads the default research tree when no definitions were set. Does not rely on _ready.
func bind(game_state: Node) -> void:
	state = game_state
	if definitions.is_empty():
		load_definitions(DEFINITIONS_DIR)
	load_from_state()


func load_from_state() -> void:
	_researched.clear()
	research_points = 0
	if state == null:
		return
	var saved: Dictionary = state.research
	research_points = int(saved.get("points", 0))
	for id: Variant in saved.get("researched", []):
		_researched[str(id)] = true
	points_changed.emit(research_points)


func definition(research_id: String) -> ResearchDefinition:
	return _by_id.get(research_id, null)


func is_researched(research_id: String) -> bool:
	return _researched.has(research_id)


func researched_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: Variant in _researched:
		ids.append(str(id))
	ids.sort()
	return ids


func add_points(amount: int) -> void:
	if amount <= 0:
		return
	research_points += amount
	_save()
	points_changed.emit(research_points)


## Returns true and deducts the points only when the balance covers the amount.
func spend_points(amount: int) -> bool:
	if amount < 0 or amount > research_points:
		return false
	research_points -= amount
	_save()
	points_changed.emit(research_points)
	return true


## Empty string when the node can be researched now. Otherwise the reason it cannot.
func can_research(research_id: String) -> String:
	var data: ResearchDefinition = definition(research_id)
	if data == null:
		return "unknown research"
	if is_researched(research_id):
		return "already researched"
	for prerequisite: String in data.prerequisites:
		if not is_researched(prerequisite):
			return "requires %s" % prerequisite
	for other: String in data.exclusive_with:
		if is_researched(other):
			return "exclusive with %s" % other
	for done: String in researched_ids():
		if definition(done).exclusive_with.has(research_id):
			return "exclusive with %s" % done
	if research_points < data.cost_rp:
		return "not enough research points"
	return ""


## Researches one node. Returns false and changes nothing if it is refused.
func research(research_id: String) -> bool:
	if can_research(research_id) != "":
		return false
	research_points -= definition(research_id).cost_rp
	_researched[research_id] = true
	_save()
	points_changed.emit(research_points)
	research_completed.emit(research_id)
	return true


func _save() -> void:
	if state == null:
		return
	state.research = {"points": research_points, "researched": researched_ids()}
