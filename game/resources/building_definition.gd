## Data for one building (SVTLW-53). Build cost is paid in gold up front; build time is in simulation ticks.
class_name BuildingDefinition
extends Resource

@export var building_id: String = ""
@export var display_name: String = ""
@export var build_cost: int = 50
## Optional material costs (SVTLW-56). All are checked before any cost is spent.
@export var wood_cost: int = 0
@export var stone_cost: int = 0
@export var iron_cost: int = 0
@export var build_time_ticks: int = 50
## Reserved for the upgrade/level story. Construction itself does not read it.
@export var max_level: int = 1
## Slot index this building must be placed on. -1 means any free construction slot.
@export var required_slot: int = -1
