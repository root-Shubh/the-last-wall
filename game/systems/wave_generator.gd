## Builds a WaveDefinition for any wave number from a WaveStageTable (SVTLW-59).
## Deterministic: the enemy pick is seeded from the wave number, so the same wave always matches.
## Returns null for a wave outside every stage, which ends the run the same way a catalog does.
class_name WaveGenerator
extends Resource

@export var stage_table: WaveStageTable


func generate(wave_number: int) -> WaveDefinition:
	if stage_table == null:
		return null
	var stage: WaveStage = stage_table.stage_for_wave(wave_number)
	if stage == null:
		return null
	var progress: int = wave_number - stage.first_wave
	var definition: WaveDefinition = WaveDefinition.new()
	definition.wave_number = wave_number
	definition.enemy_type_id = _pick_enemy(stage, wave_number)
	definition.enemy_count = maxi(1, stage.base_count + floori(progress * stage.count_growth))
	definition.spawn_interval_ticks = maxi(
		stage.min_interval_ticks,
		stage.base_interval_ticks - floori(progress * stage.interval_decrease))
	return definition


func _pick_enemy(stage: WaveStage, wave_number: int) -> String:
	if stage.enemy_ids.is_empty():
		return "undead_infantry"
	var total: int = 0
	for weight: int in stage.enemy_weights:
		total += maxi(weight, 0)
	if total <= 0:
		return stage.enemy_ids[0]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = wave_number
	var roll: int = rng.randi_range(0, total - 1)
	for i: int in range(stage.enemy_ids.size()):
		roll -= maxi(stage.enemy_weights[i], 0)
		if roll < 0:
			return stage.enemy_ids[i]
	return stage.enemy_ids[0]
