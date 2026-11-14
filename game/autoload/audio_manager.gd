## Audio buses, volume and sound-event hooks (SVTLW-50). Autoload name: AudioManager.
## Buses: Music, SFX and Voice, all under Master. Volumes are percentages (0 to 100) that map to
## decibels. Sound events are recorded as they fire; real streams are attached in M7 (SVTLW-88).
extends Node

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_VOICE: StringName = &"Voice"

## Sound events the game fires. Each one gets a stream when the audio pass arrives.
const EVENTS: Array[String] = [
	"shot", "hit", "wall_impact", "enemy_death", "reward", "construction", "upgrade", "wave_start", "wave_end",
]

## Every event fired, in order, for tests and for debugging the hooks.
var played_events: Array[String] = []


## Sets a bus volume from a percentage. 0 mutes the bus. Values are clamped to 0 to 100.
func set_bus_percent(bus: StringName, percent: int) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var clamped: int = clampi(percent, 0, 100)
	if clamped == 0:
		AudioServer.set_bus_volume_db(index, -80.0)
	else:
		AudioServer.set_bus_volume_db(index, linear_to_db(clamped / 100.0))


func bus_percent(bus: StringName) -> int:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return 0
	var db: float = AudioServer.get_bus_volume_db(index)
	if db <= -79.0:
		return 0
	return roundi(db_to_linear(db) * 100.0)


## Applies the three saved volumes from a SettingsStore.
func apply_settings(settings: SettingsStore) -> void:
	set_bus_percent(BUS_MUSIC, settings.music_percent)
	set_bus_percent(BUS_SFX, settings.sfx_percent)
	set_bus_percent(BUS_VOICE, settings.voice_percent)


## Records a sound event. Returns false for an unknown event name.
func play_event(event_name: String) -> bool:
	if not EVENTS.has(event_name):
		push_warning("AudioManager: unknown sound event '%s'" % event_name)
		return false
	played_events.append(event_name)
	return true
