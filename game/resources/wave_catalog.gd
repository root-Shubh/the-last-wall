## Ordered list of wave definitions for a campaign run (SVTLW-26).
## M1 uses one catalog file for waves 1 to 10. The data-driven generator arrives in M2 (SVTLW-60).
class_name WaveCatalog
extends Resource

@export var waves: Array[WaveDefinition] = []


## Returns the definition for a wave number, or null when the catalog has none.
func get_wave(wave_number: int) -> WaveDefinition:
	for definition: WaveDefinition in waves:
		if definition.wave_number == wave_number:
			return definition
	return null
