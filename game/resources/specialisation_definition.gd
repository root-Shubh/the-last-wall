## One specialisation for an archer or crossbowman (SVTLW-62). Each one trades a bonus against a cost.
## A unit holds at most one. Multipliers are applied by Archer.apply_specialisation; base unit data is untouched.
class_name SpecialisationDefinition
extends Resource

@export var specialisation_id: String = ""
@export var display_name: String = ""
## "archer" or "crossbowman".
@export var unit_id: String = ""
@export var damage_multiplier: float = 1.0
## Above 1.0 is faster, which means a shorter interval between shots.
@export var attack_speed_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
## Added to the unit's base armour penetration.
@export var armour_penetration_bonus: float = 0.0
## Plain-text cost of this choice, shown to the player later.
@export_multiline var weakness: String = ""
## Element tag such as "fire". Recorded only; no behaviour in this story.
@export var damage_type_note: String = ""


## Loads res://resources/specialisations/<id>.tres, or returns null if there is no such specialisation.
static func load_by_id(id: String) -> SpecialisationDefinition:
	var path: String = "res://resources/specialisations/%s.tres" % id
	if id == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as SpecialisationDefinition
