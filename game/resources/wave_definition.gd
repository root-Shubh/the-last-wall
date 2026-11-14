## Data for one wave: which enemy type, how many, and how often they spawn (SVTLW-26).
## Balance values live in .tres files under resources/waves/, never in scripts.
class_name WaveDefinition
extends Resource

@export var wave_number: int = 1
@export var enemy_type_id: String = "undead_infantry"
@export var enemy_count: int = 5
## Ticks between spawns. At 10 ticks per second, 10 ticks is one enemy per second at 1x.
@export_range(1, 1000) var spawn_interval_ticks: int = 10
