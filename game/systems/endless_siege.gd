## Endless Siege (SVTLW-76): unlimited escalating waves past the M1 catalog.
## Waves come from WaveGenerator, which reads the "Endless" stage (151 to 100000) in wave_stages.tres.
## Tracks highest_wave and total_kills as run stats. Pure RefCounted: no scene or autoload access.
class_name EndlessSiege
extends RefCounted

const STAGE_TABLE_PATH: String = "res://resources/waves/wave_stages.tres"

var generator: WaveGenerator = null
var highest_wave: int = 0
var total_kills: int = 0


func _init(wave_generator: WaveGenerator = null) -> void:
	if wave_generator != null:
		generator = wave_generator
	else:
		generator = WaveGenerator.new()
		generator.stage_table = load(STAGE_TABLE_PATH) as WaveStageTable


## Returns the definition for a wave number, or null when the generator has no stage for it.
## A returned definition moves highest_wave up when the wave is the furthest reached so far.
func definition_for(wave_number: int) -> WaveDefinition:
	var definition: WaveDefinition = generator.generate(wave_number)
	if definition != null:
		highest_wave = maxi(highest_wave, wave_number)
	return definition


## Adds kills from a finished wave. Negative counts are ignored.
func record_kills(count: int) -> void:
	total_kills += maxi(count, 0)


func reset_stats() -> void:
	highest_wave = 0
	total_kills = 0
