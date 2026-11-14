## Headless tests for audio buses, volume settings and sound-event hooks (SVTLW-50).
## Run: godot --headless --path game -s res://tests/test_audio.gd
extends SceneTree

const TEST_PATH: String = "user://test_audio_settings.cfg"

var _failures: int = 0


func _initialize() -> void:
	var audio: Node = root.get_node("AudioManager")
	var state: Node = root.get_node("GameState")
	_test_buses_exist()
	_test_bus_volume(audio)
	_test_settings_volumes(audio)
	_test_events(audio)
	_test_battlefield_fires_events(audio, state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_buses_exist() -> void:
	print("buses")
	for bus: StringName in [&"Master", &"Music", &"SFX", &"Voice"]:
		_check(AudioServer.get_bus_index(bus) >= 0, "bus %s exists" % bus)


func _test_bus_volume(audio: Node) -> void:
	print("bus volume")
	audio.set_bus_percent(audio.BUS_MUSIC, 50)
	_check(audio.bus_percent(audio.BUS_MUSIC) == 50, "music at 50 percent reads back as 50")
	audio.set_bus_percent(audio.BUS_SFX, 0)
	_check(audio.bus_percent(audio.BUS_SFX) == 0, "0 percent mutes the bus")
	audio.set_bus_percent(audio.BUS_VOICE, 150)
	_check(audio.bus_percent(audio.BUS_VOICE) == 100, "values above 100 clamp to 100")
	audio.set_bus_percent(audio.BUS_VOICE, -5)
	_check(audio.bus_percent(audio.BUS_VOICE) == 0, "negative values clamp to 0")


func _test_settings_volumes(audio: Node) -> void:
	print("settings volumes")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var store: SettingsStore = SettingsStore.new()
	store.music_percent = 30
	store.sfx_percent = 60
	store.voice_percent = 90
	_check(store.save_to(TEST_PATH), "volumes save")
	var loaded: SettingsStore = SettingsStore.new()
	_check(loaded.load_from(TEST_PATH) and loaded.music_percent == 30 and loaded.voice_percent == 90, "volumes load back")
	audio.apply_settings(loaded)
	_check(audio.bus_percent(audio.BUS_MUSIC) == 30 and audio.bus_percent(audio.BUS_SFX) == 60, "saved volumes reach the buses")


func _test_events(audio: Node) -> void:
	print("sound events")
	audio.played_events.clear()
	_check(audio.play_event("shot") and audio.played_events == ["shot"], "a known event is recorded")
	_check(not audio.play_event("made_up_sound") and audio.played_events.size() == 1, "an unknown event is refused")


func _test_battlefield_fires_events(audio: Node, state: Node) -> void:
	print("battlefield fires events")
	state.reset()
	state.add_gold(200)
	audio.played_events.clear()
	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	field.audio = audio
	field.save_manager = root.get_node("SaveManager")
	root.add_child(field)
	field.ensure_ready()
	field.recruit_archer(Vector2(200.0, 300.0))
	field.start_wave()
	var guard: int = 0
	while field.waves.is_running() and guard < 5000:
		field.step_ticks(1)
		guard += 1
	var heard: Array = audio.played_events
	_check(heard.has("wave_start") and heard.has("wave_end"), "wave start and end fire")
	_check(heard.has("shot") and heard.has("hit"), "shots and hits fire")
	_check(heard.has("reward"), "rewards fire")
	field.get_parent().remove_child(field)
	field.free()
