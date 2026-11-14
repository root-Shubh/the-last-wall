## One Challenge mode entry (SVTLW-77): a restriction, a wave multiplier and an enemy composition.
## Balance values live in .tres files under resources/challenges/, never in scripts.
## restriction ids are read by the battlefield when it is wired in, for example "no_archers",
## "wall_max_health_half" or "no_repairs". Unknown ids are data errors the rotation tests catch.
class_name ChallengeDefinition
extends Resource

@export var challenge_id: String = ""
@export var display_name: String = ""
@export var restriction: String = ""
@export_range(0.1, 10.0) var extra_wave_multiplier: float = 1.0
## Enemy type ids the challenge's waves draw from. Ids must match resources/enemies/.
@export var enemy_ids: PackedStringArray = PackedStringArray()
