## One prestige specialisation path (SVTLW-74). Each path has a numeric bonus and a non-numerical mechanic.
## The mechanic is data: mechanic_event names the game event and mechanic_effects says what changes.
## The battlefield asks PrestigePath.hook_for(path_id, event) later. Nothing here touches the scene.
class_name PrestigePath
extends Resource

@export var path_id: String = ""
@export var display_name: String = ""
## Numeric bonus: a game value name (see UpgradeManager.effect_total) and its size.
@export var bonus_stat: String = ""
@export var bonus_value: float = 0.0
## Plain-text description of the mechanic, shown to the player later.
@export_multiline var mechanic_text: String = ""
## Game event that triggers the mechanic, such as "wave_cleared".
@export var mechanic_event: String = ""
## Effects applied when the event fires, such as {"gold": 40}.
@export var mechanic_effects: Dictionary = {}


## Loads res://resources/prestige_paths/<id>.tres, or returns null if there is no such path.
static func load_by_id(id: String) -> PrestigePath:
	var path: String = "res://resources/prestige_paths/%s.tres" % id
	if id == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as PrestigePath


## Effects the path's mechanic adds for one game event. Empty when the path is unknown or the event does not match.
static func hook_for(path_id: String, event: String) -> Dictionary:
	var data: PrestigePath = load_by_id(path_id)
	if data == null or data.mechanic_event != event:
		return {}
	return data.mechanic_effects.duplicate()
