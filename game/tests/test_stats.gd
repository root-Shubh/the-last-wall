## Headless tests for stats, achievements and the stats screen (SVTLW-78).
## Run: godot --headless --path game -s res://tests/test_stats.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_counters()
	_test_achievements()
	_test_save_round_trip()
	_test_malformed_stats()
	_test_screen_labels()
	_test_death_lines()

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_counters() -> void:
	print("counters")
	var stats: StatsTracker = StatsTracker.new()
	stats.record_kill()
	stats.record_kill()
	stats.record_wave_survived(7)
	stats.record_resources(40)
	stats.record_damage_dealt(120)
	stats.record_damage_received(15)
	stats.record_death()
	stats.add_playtime(90.5)
	stats.record_hit(55)
	_check(stats.total_kills == 2, "kills count up")
	_check(stats.waves_survived == 1 and stats.highest_wave == 7, "waves survived and highest wave recorded")
	_check(stats.resources_earned == 40 and stats.damage_dealt == 120 and stats.damage_received == 15, "resources and damage recorded")
	_check(stats.deaths == 1 and absf(stats.playtime_seconds - 90.5) < 0.0001, "deaths and playtime recorded")
	_check(stats.highest_damage_hit == 55, "largest hit recorded")

	stats.record_resources(-30)
	stats.record_damage_dealt(-5)
	stats.record_wave_survived(-3)
	stats.add_playtime(-10.0)
	stats.add_playtime(NAN)
	stats.record_hit(-9)
	_check(stats.resources_earned == 40 and stats.damage_dealt == 120, "negative amounts change nothing")
	_check(stats.highest_wave == 7 and absf(stats.playtime_seconds - 90.5) < 0.0001, "negative wave and playtime ignored")
	_check(stats.highest_damage_hit == 55, "negative hit ignored")


func _test_achievements() -> void:
	print("achievements")
	var stats: StatsTracker = StatsTracker.new()
	var achievements: Achievements = Achievements.new()
	_check(achievements.definitions.size() >= 10, "at least ten achievements are defined")
	_check(achievements.check(stats, 1).is_empty(), "nothing unlocks at the start")

	stats.record_wave_survived(100)
	var first: Array[String] = achievements.check(stats, 1)
	_check(first.has("wave_25") and first.has("wave_100"), "wave 100 unlocks the wave achievements")
	_check(not first.has("wave_500"), "wave 500 stays locked at wave 100")
	_check(achievements.check(stats, 1).is_empty(), "repeated check returns nothing new")

	for _i: int in 1000:
		stats.record_kill()
	_check(achievements.check(stats, 1).has("kills_1000"), "1000 kills unlock once")
	_check(achievements.check(stats, 1).is_empty(), "kill achievement does not repeat")
	_check(achievements.check(stats, 7).has("wall_tier_7"), "wall tier 7 unlocks from the tier value")
	_check(achievements.is_unlocked("wall_tier_7"), "unlocked state is kept")


func _test_save_round_trip() -> void:
	print("save round trip")
	var state: Node = root.get_node("GameState")
	state.reset()
	state.stats.record_kill()
	state.stats.record_kill()
	state.stats.record_wave_survived(25)
	state.stats.add_playtime(12.0)
	state.achievements.check(state.stats, 1)
	var text: String = JSON.stringify(state.to_dict())
	state.reset()
	_check(state.stats.total_kills == 0 and state.achievements.unlocked.is_empty(), "reset clears stats and achievements")
	_check(state.from_dict(JSON.parse_string(text)), "save with stats loads")
	_check(state.stats.total_kills == 2 and state.stats.highest_wave == 25, "stats restored from save")
	_check(state.achievements.is_unlocked("wave_25"), "unlocked achievements restored from save")
	_check(not state.achievements.is_unlocked("wave_100"), "locked achievements stay locked after load")


func _test_malformed_stats() -> void:
	print("malformed stats")
	var state: Node = root.get_node("GameState")
	var base: Dictionary = {"gold": 5, "wave": 1, "wall_health": 10, "wall_max_health": 10}
	var bad: Dictionary = base.duplicate()
	bad["stats"] = {"total_kills": -4, "deaths": "many", "damage_dealt": 2.5, "playtime_seconds": -1.0, "waves_survived": 3}
	bad["achievements"] = [42, "kills_1000", "not_an_achievement", "wave_25", "wave_25"]
	_check(state.from_dict(bad), "save with malformed stats still loads")
	_check(state.stats.total_kills == 0 and state.stats.deaths == 0, "invalid counters load as zero")
	_check(state.stats.damage_dealt == 0 and state.stats.playtime_seconds == 0.0, "fractional and negative values load as zero")
	_check(state.stats.waves_survived == 3, "valid counters are kept")
	_check(state.achievements.unlocked_ids() == ["kills_1000", "wave_25"], "only valid, unique achievement ids load")

	var no_stats: Dictionary = base.duplicate()
	no_stats["stats"] = "broken"
	_check(state.from_dict(no_stats) and state.stats.total_kills == 0, "non-dictionary stats load as zeros")


func _test_screen_labels() -> void:
	print("stats screen")
	var stats: StatsTracker = StatsTracker.new()
	var achievements: Achievements = Achievements.new()
	for _i: int in 1234:
		stats.record_kill()
	achievements.check(stats, 1)
	var screen: StatsScreen = StatsScreen.new()
	screen.build(stats, achievements)
	var texts: Array[String] = screen.get_label_texts()
	_check(texts.has("Total kills: 1234"), "screen shows the kill count")
	_check(texts.any(func(text: String) -> bool: return text.begins_with("[Unlocked] Thousand Fallen")), "screen lists unlocked achievements")
	_check(texts.any(func(text: String) -> bool: return text.begins_with("[Locked] Statistically Unusual")), "screen lists locked achievements")
	_check(StatsScreen.format_playtime(3725.0) == "1:02:05", "playtime formats as hours, minutes and seconds")
	screen.free()


func _test_death_lines() -> void:
	print("death counter")
	var stats: StatsTracker = StatsTracker.new()
	var deaths: DeathCounter = DeathCounter.new(stats)
	var fired: Dictionary = {}
	for count: int in range(1, 348):
		for line: String in deaths.on_death():
			fired[count] = line
	_check(fired.size() == 4, "exactly four death lines fire across 347 deaths")
	_check(fired.get(1, "") == DeathCounter.LINES[1], "first death fires the early line")
	_check(fired.get(10, "") == DeathCounter.LINES[10], "tenth death fires the later line")
	_check(fired.get(100, "") == DeathCounter.LINES[100], "hundredth death fires the 100 line")
	_check(fired.get(347, "") == "YOU HAVE FAILED 347 TIMES. WHY DO YOU CONTINUE?", "347th death fires the final line")
	_check(stats.deaths == 347, "death total is kept in StatsTracker")
	_check(deaths.on_death().is_empty(), "a line does not fire again after its threshold")
