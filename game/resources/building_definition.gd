## Data for one building (SVTLW-53). Build cost is paid in gold up front; build time is in simulation ticks.
class_name BuildingDefinition
extends Resource

@export var building_id: String = ""
@export var display_name: String = ""
@export var build_cost: int = 50
@export var build_time_ticks: int = 50
## Highest upgrade level (SVTLW-54). 0 means the default of 3. Construction itself does not read it.
@export var max_level: int = 1
## Slot index this building must be placed on. -1 means any free construction slot.
@export var required_slot: int = -1
## Defence fields (SVTLW-54). All zero means the building is not a defence and never fires.
@export var attack_damage: float = 0.0
@export var attack_interval_ticks: int = 0
## World pixels.
@export var attack_range: float = 0.0
