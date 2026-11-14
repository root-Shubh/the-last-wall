## One stage of the data-driven wave generator (SVTLW-59).
## A stage covers waves first_wave to last_wave inclusive. Its numbers are balance data, not code.
class_name WaveStage
extends Resource

@export var stage_name: String = ""
@export var first_wave: int = 1
@export var last_wave: int = 1
## Parallel arrays: enemy_ids[i] is picked with weight enemy_weights[i]. Ids must match resources/enemies/.
@export var enemy_ids: PackedStringArray = PackedStringArray()
@export var enemy_weights: PackedInt32Array = PackedInt32Array()
@export var base_count: int = 5
## Extra enemies per wave after the stage's first wave. Fractions floor down.
@export var count_growth: float = 0.0
@export_range(1, 1000) var base_interval_ticks: int = 20
## Ticks removed from the interval per wave after the first wave of the stage.
@export var interval_decrease: float = 0.0
## The interval never drops below this value.
@export_range(1, 1000) var min_interval_ticks: int = 8
