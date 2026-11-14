## Data for one upgrade (SVTLW-39). Cost, effect, max level and prerequisite all live here.
## Cost at level L is floor(base_cost x cost_multiplier^L). Effect total is level x effect_per_level.
class_name UpgradeDefinition
extends Resource

## Which game value this upgrade changes. UpgradeManager.effect_total() reads it by name.
const EFFECTS: Array[String] = [
	"archer_damage",
	"archer_attack_speed",
	"wall_max_health",
	"repair_rate",
	"gold_per_kill",
]

@export var upgrade_id: String = ""
@export var display_name: String = ""
@export_enum("archer_damage", "archer_attack_speed", "wall_max_health", "repair_rate", "gold_per_kill") var effect: String = "archer_damage"
@export var effect_per_level: float = 0.1
@export var base_cost: int = 20
@export var cost_multiplier: float = 1.5
@export var max_level: int = 5
## Optional upgrade id that must be bought at least once first. Empty means none.
@export var prerequisite_id: String = ""
