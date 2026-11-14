## Headless tests for kill and wave rewards (SVTLW-27).
## Run: godot --headless --path game -s res://tests/test_rewards.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()

	var enemies: EnemyManager = EnemyManager.new()
	enemies.definitions = [
		load("res://resources/enemies/undead_infantry.tres"),
		load("res://resources/enemies/armoured_brute.tres"),
	]
	root.add_child(enemies)
	var waves: WaveManager = WaveManager.new()
	waves.catalog = load("res://resources/waves/m1_catalog.tres")
	var tracker: RewardTracker = RewardTracker.new()
	root.add_child(tracker)
	tracker.bind(enemies, waves, state)

	_test_kill_reward(enemies, state, tracker)
	_test_wave_bonus(waves, state, tracker)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_kill_reward(enemies: EnemyManager, state: Node, tracker: RewardTracker) -> void:
	print("kill reward")
	var before: int = state.gold
	var infantry: Enemy = enemies.spawn("undead_infantry")
	infantry.take_damage(1000.0)
	_check(state.gold == before + 2, "infantry kill grants its gold reward (2)")
	var brute: Enemy = enemies.spawn("armoured_brute")
	brute.take_damage(1000.0)
	_check(state.gold == before + 8, "brute kill grants its gold reward (6)")
	_check(tracker.kills == 2 and tracker.gold_from_kills == 8, "tracker counts kills and kill gold")


func _test_wave_bonus(waves: WaveManager, state: Node, tracker: RewardTracker) -> void:
	print("wave bonus")
	var before: int = state.gold
	waves.start_next_wave()
	waves.wave_completed.emit(1)
	_check(state.gold == before + 10, "wave 1 grants the survival bonus (10)")
	waves.wave_completed.emit(3)
	_check(state.gold == before + 10 + 30, "wave 3 grants 30")
	_check(tracker.gold_from_waves == 40, "tracker counts wave gold")
