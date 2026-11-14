## Stage table for WaveGenerator: an ordered list of WaveStage resources (SVTLW-59).
## Data lives in resources/waves/wave_stages.tres. Stages must not overlap.
class_name WaveStageTable
extends Resource

@export var stages: Array[WaveStage] = []


## Returns the stage that covers a wave number, or null when no stage does.
func stage_for_wave(wave_number: int) -> WaveStage:
	for stage: WaveStage in stages:
		if wave_number >= stage.first_wave and wave_number <= stage.last_wave:
			return stage
	return null
