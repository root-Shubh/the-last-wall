## One campaign region (SVTLW-80). A region covers a wave range, its enemy mix, its boss and its objective.
## Data lives in resources/regions/*.tres. Wave ranges of different regions must not overlap.
class_name Region
extends Resource

@export var region_id: String = ""
@export var display_name: String = ""
@export var first_wave: int = 1
@export var last_wave: int = 1
## Enemy ids (resources/enemies) that appear in this region's waves.
@export var enemy_ids: PackedStringArray = PackedStringArray()
## Boss id: an overlord id (resources/overlords) or an enemy id (resources/enemies).
@export var boss_id: String = ""
@export_multiline var objective_text: String = ""
