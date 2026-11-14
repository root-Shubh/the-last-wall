## One permanent relic purchase (SVTLW-73). Bought with relics, kept through prestige resets.
## Total effect is level x effect_per_level. PrestigeManager.effect_total() reads it by effect name.
class_name RelicUpgrade
extends Resource

const EFFECTS: Array[String] = ["starting_gold", "archer_damage", "production", "population_slot"]

@export var relic_id: String = ""
@export var display_name: String = ""
@export_enum("starting_gold", "archer_damage", "production", "population_slot") var effect: String = "starting_gold"
@export var effect_per_level: float = 0.0
## Relics needed for one level.
@export var relic_cost: int = 1
@export var max_level: int = 1


## Loads res://resources/relics/<id>.tres, or returns null if there is no such relic upgrade.
static func load_by_id(id: String) -> RelicUpgrade:
	var path: String = "res://resources/relics/%s.tres" % id
	if id == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as RelicUpgrade
