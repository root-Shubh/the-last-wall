## Data for one defensive unit type (SVTLW-31, SVTLW-32). Balance lives in .tres files.
class_name UnitDefinition
extends Resource

@export var unit_id: String = ""
@export var display_name: String = ""
@export var max_health: float = 20.0
@export var base_damage: float = 4.0
@export var armour: float = 0.0
@export_range(1, 1000) var attack_interval_ticks: int = 8
## World pixels.
@export var attack_range: float = 300.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
@export var recruit_cost: int = 20
## Population slots this unit occupies.
@export var population_cost: int = 1
## Reduces the target armour by this much when the unit hits (SVTLW-51).
@export var armour_penetration: float = 0.0
