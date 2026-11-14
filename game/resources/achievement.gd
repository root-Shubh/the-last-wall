## Data for one achievement (SVTLW-78). The stat name picks the value that is compared with the threshold.
class_name Achievement
extends Resource

@export var achievement_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export_enum("total_kills", "highest_wave", "damage_dealt", "deaths", "wall_tier") var stat: String = "total_kills"
@export var threshold: int = 1
