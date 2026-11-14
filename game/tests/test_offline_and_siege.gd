## Headless tests for offline progress (SVTLW-75), Endless Siege (SVTLW-76) and challenges (SVTLW-77).
## Run: godot --headless --path game -s res://tests/test_offline_and_siege.gd
extends SceneTree

var _failures: int = 0
const CAP: int = OfflineProgress.DEFAULT_CAP_SECONDS
var _rates: Dictionary = {"wood": 0.5, "stone": 0.2, "iron": 0.0}


func _initialize() -> void:
	_test_offline_disabled()
	_test_offline_rate_times_ticks()
	_test_offline_cap()
	_test_offline_negative_elapsed()
	_test_offline_clock_changes()
	_test_offline_summary()
	_test_offline_game_state_defaults()
	_test_endless_siege()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_offline_disabled() -> void:
	var result: Dictionary = OfflineProgress.compute(_rates, 3600, CAP, false)
	var gained: Dictionary = result["gained"]
	_check(int(gained["wood"]) == 0 and int(gained["stone"]) == 0 and int(gained["iron"]) == 0, "offline gain is zero when disabled")
	_check(int(result["seconds_used"]) == 0, "disabled absence uses no seconds")


func _test_offline_rate_times_ticks() -> void:
	# 100 seconds is 1000 ticks; wood 0.5 per tick gives 500, stone 0.2 gives 200.
	var result: Dictionary = OfflineProgress.compute(_rates, 100, CAP, true)
	var gained: Dictionary = result["gained"]
	_check(int(gained["wood"]) == 500, "wood gain equals rate times ticks (500)")
	_check(int(gained["stone"]) == 200, "stone gain equals rate times ticks (200)")
	_check(int(result["seconds_used"]) == 100, "seconds used equals elapsed when under the cap")
	var floored: Dictionary = OfflineProgress.compute({"wood": 0.33}, 1, CAP, true)
	_check(int(floored["gained"]["wood"]) == 3, "fractional gain floors (0.33 * 10 ticks = 3)")


func _test_offline_cap() -> void:
	var ten_hours: Dictionary = OfflineProgress.compute(_rates, 10 * 3600, CAP, true)
	var at_cap: Dictionary = OfflineProgress.compute(_rates, CAP, CAP, true)
	_check(ten_hours["gained"] == at_cap["gained"], "a 10 hour absence gives the same as the cap")
	_check(int(ten_hours["seconds_used"]) == CAP, "seconds used is clamped to the cap")
	_check(int(at_cap["gained"]["wood"]) == int(floor(0.5 * CAP * 10)), "capped wood equals 0.5 * cap ticks")


func _test_offline_negative_elapsed() -> void:
	var result: Dictionary = OfflineProgress.compute(_rates, -500, CAP, true)
	_check(int(result["gained"]["wood"]) == 0 and int(result["seconds_used"]) == 0, "negative elapsed gives zero")


func _test_offline_clock_changes() -> void:
	var now: int = 1_800_000_000
	_check(OfflineProgress.elapsed_since(0, now) == 0, "no recorded save time gives zero elapsed")
	_check(OfflineProgress.elapsed_since(now, now - 3600) < 0, "clock moved back gives negative elapsed")
	var backwards: Dictionary = OfflineProgress.compute(_rates, OfflineProgress.elapsed_since(now, now - 3600), CAP, true)
	_check(int(backwards["gained"]["wood"]) == 0, "clock moved back earns nothing")
	var jump: Dictionary = OfflineProgress.compute(_rates, OfflineProgress.elapsed_since(now - 90 * 86400, now), CAP, true)
	_check(int(jump["seconds_used"]) == CAP, "a 90 day clock jump is capped at 8 hours")


func _test_offline_summary() -> void:
	var text: String = OfflineProgress.format_summary(OfflineProgress.compute(_rates, 3600, CAP, true))
	_check(text.contains("wood") and text.contains("stone") and text.contains("iron"), "summary names each resource")
	_check(text.contains("+18000 wood"), "summary shows the wood gain (3600 s is 36000 ticks at 0.5)")
	var disabled: String = OfflineProgress.format_summary(OfflineProgress.compute(_rates, 3600, CAP, false))
	_check(disabled.contains("+0 wood"), "summary for a disabled result shows zero gains")


func _test_offline_game_state_defaults() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	_check(state.last_saved_unix == 0 and state.offline_enabled == true, "GameState defaults: last_saved_unix 0, offline_enabled true")
	var data: Dictionary = state.to_dict()
	_check(data.has("last_saved_unix") and data.has("offline_enabled"), "GameState saves offline fields")
	state.last_saved_unix = 1234
	state.offline_enabled = false
	var copy: Dictionary = state.to_dict()
	state.reset()
	_check(state.from_dict(copy) and state.last_saved_unix == 1234 and state.offline_enabled == false, "offline fields round-trip through save data")
	state.reset()


func _test_endless_siege() -> void:
	var siege: EndlessSiege = EndlessSiege.new()
	_check(siege.highest_wave == 0 and siege.total_kills == 0, "endless siege starts with zeroed stats")
	var wave_151: WaveDefinition = siege.definition_for(151)
	_check(wave_151 != null and wave_151.wave_number == 151, "endless siege returns a definition for wave 151")
	_check(siege.definition_for(200) != null, "endless siege returns a definition for wave 200")
	var wave_1000: WaveDefinition = siege.definition_for(1000)
	_check(wave_1000 != null and wave_1000.enemy_count > 36, "wave 1000 is larger than the Endless start")
	_check(siege.highest_wave == 1000, "highest_wave moves to the furthest wave reached")
	siege.definition_for(500)
	_check(siege.highest_wave == 1000, "highest_wave never moves backwards")
	siege.record_kills(25)
	siege.record_kills(-4)
	_check(siege.total_kills == 25, "total_kills adds kills and ignores negative counts")
	var bad: int = 0
	for wave: int in range(151, 1201):
		var definition: WaveDefinition = siege.definition_for(wave)
		if definition == null or definition.enemy_count < 1 or definition.spawn_interval_ticks < 6:
			bad += 1
	_check(bad == 0, "waves 151 to 1200 all have valid data")
	_check(siege.definition_for(100001) == null, "waves past the Endless stage end (no data error)")
