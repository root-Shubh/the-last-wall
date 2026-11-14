## Headless tests for archer targeting modes (SVTLW-58).
## Run: godot --headless --path game -s res://tests/test_targeting.gd
extends SceneTree

var _failures: int = 0
var _game_state: Node = null


func _initialize() -> void:
	_test_each_mode_picks_expected()
	_test_range_and_dead_ignored()
	_test_default_archer_unchanged()
	_test_per_unit_mode_change()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _archer_def() -> UnitDefinition:
	return load("res://resources/units/archer.tres")


func _enemy(path: String, pos: Vector2) -> Enemy:
	var definition: EnemyDefinition = load(path)
	var enemy: Enemy = Enemy.new()
	enemy.setup(definition, pos.x, 0.0, pos.y)
	enemy.global_position = pos
	return enemy


func _state() -> Node:
	if _game_state == null:
		_game_state = root.get_node("GameState")
	return _game_state


# Fixed set, archer at origin, range 300.
# infantry (100, 0): closest, 10 max hp.
# brute (150, 0): strongest (40 max hp).
# runner (40, 250): highest wall threat (smallest x), and weakest once its health is set to 1.
func _fixed_set() -> Array:
	var infantry: Enemy = _enemy("res://resources/enemies/undead_infantry.tres", Vector2(100.0, 0.0))
	var brute: Enemy = _enemy("res://resources/enemies/armoured_brute.tres", Vector2(150.0, 0.0))
	var runner: Enemy = _enemy("res://resources/enemies/runner.tres", Vector2(40.0, 250.0))
	runner.health = 1.0
	return [infantry, brute, runner]


func _test_each_mode_picks_expected() -> void:
	print("each mode picks the expected enemy")
	var fixed: Array = _fixed_set()
	var infantry: Enemy = fixed[0]
	var brute: Enemy = fixed[1]
	var runner: Enemy = fixed[2]
	var origin: Vector2 = Vector2.ZERO
	var range_px: float = 300.0
	_check(Targeting.select(Targeting.Mode.CLOSEST, fixed, origin, range_px) == infantry, "closest picks the nearest enemy")
	_check(Targeting.select(Targeting.Mode.STRONGEST, fixed, origin, range_px) == brute, "strongest picks the highest max_health")
	_check(Targeting.select(Targeting.Mode.WEAKEST, fixed, origin, range_px) == runner, "weakest picks the lowest current health")
	_check(Targeting.select(Targeting.Mode.HIGHEST_WALL_THREAT, fixed, origin, range_px) == runner, "wall threat picks the smallest x")
	_check(Targeting.select(Targeting.Mode.PRIORITY_TYPE, fixed, origin, range_px, "armoured_brute") == brute, "priority type picks the chosen definition id")
	_check(Targeting.select(Targeting.Mode.PRIORITY_TYPE, fixed, origin, range_px, "runner") == runner, "priority type works for runner")
	_check(Targeting.select(Targeting.Mode.PRIORITY_TYPE, fixed, origin, range_px, "climber") == null, "priority type returns null when that id is absent")
	_check(Targeting.mode_name(Targeting.Mode.HIGHEST_WALL_THREAT) == "highest_wall_threat", "mode names are stable ids")


func _test_range_and_dead_ignored() -> void:
	print("out-of-range and dead enemies are ignored")
	var far: Enemy = _enemy("res://resources/enemies/climber.tres", Vector2(500.0, 0.0))
	_check(Targeting.select(Targeting.Mode.CLOSEST, [far], Vector2.ZERO, 300.0) == null, "closest ignores an enemy out of range")
	_check(Targeting.select(Targeting.Mode.HIGHEST_WALL_THREAT, [far], Vector2.ZERO, 300.0) == null, "wall threat ignores an enemy out of range")
	_check(Targeting.select(Targeting.Mode.PRIORITY_TYPE, [far], Vector2.ZERO, 300.0, "climber") == null, "priority type ignores an enemy out of range")

	var fixed: Array = _fixed_set()
	var infantry: Enemy = fixed[0]
	var runner: Enemy = fixed[2]
	runner.take_damage(1000.0)
	_check(not runner.alive, "runner is dead after lethal damage")
	_check(Targeting.select(Targeting.Mode.HIGHEST_WALL_THREAT, fixed, Vector2.ZERO, 300.0) == infantry, "dead enemy is skipped for wall threat")
	_check(Targeting.select(Targeting.Mode.WEAKEST, fixed, Vector2.ZERO, 300.0) != runner, "dead enemy is skipped for weakest")
	_check(Targeting.select(Targeting.Mode.CLOSEST, [runner], Vector2.ZERO, 300.0) == null, "a list of only dead enemies gives null")


func _test_default_archer_unchanged() -> void:
	print("default archer behaves as before")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var archer: Archer = Archer.new()
	archer.setup(_archer_def(), Vector2.ZERO, rng)
	_check(archer.targeting_mode == Targeting.Mode.CLOSEST, "archer defaults to closest")
	var near: Enemy = _enemy("res://resources/enemies/undead_infantry.tres", Vector2(100.0, 0.0))
	var far: Enemy = _enemy("res://resources/enemies/armoured_brute.tres", Vector2(250.0, 0.0))
	_check(archer.closest_in_range([far, near]) == near, "closest_in_range still picks the closest")
	_check(archer.select_target([far, near]) == near, "select_target on default mode picks the closest")
	archer.free()


func _test_per_unit_mode_change() -> void:
	print("per-unit mode change takes effect on the next shot")
	_state().reset()
	_state().add_gold(200)
	var manager: UnitManager = UnitManager.new()
	manager.unit_definitions = [_archer_def()]
	manager.population_cap = 5
	manager.state = _state()
	root.add_child(manager)
	var first: Archer = manager.recruit("archer", Vector2.ZERO)
	var second: Archer = manager.recruit("archer", Vector2.ZERO)

	var near: Enemy = _enemy("res://resources/enemies/undead_infantry.tres", Vector2(100.0, 0.0))
	var brute: Enemy = _enemy("res://resources/enemies/armoured_brute.tres", Vector2(150.0, 0.0))
	var enemies: Array = [near, brute]
	var targets: Dictionary = {}
	for archer: Archer in [first, second]:
		archer.fire_requested.connect(func(_o: Vector2, t: Enemy, _d: float) -> void: targets[archer] = t)

	var interval: int = _archer_def().attack_interval_ticks
	for tick: int in range(interval):
		manager.on_tick(tick, enemies)
	_check(targets[first] == near and targets[second] == near, "both archers start on closest")

	manager.set_targeting_mode(Targeting.Mode.STRONGEST, "", first)
	for tick: int in range(interval):
		manager.on_tick(tick, enemies)
	_check(targets[first] == brute, "named unit switches to strongest on its next shot")
	_check(targets[second] == near, "other units keep their mode")

	manager.set_targeting_mode(Targeting.Mode.PRIORITY_TYPE, "undead_infantry")
	for tick: int in range(interval):
		manager.on_tick(tick, enemies)
	_check(targets[first] == near and targets[second] == near, "all-units priority type applies to every archer")
	root.remove_child(manager)
	manager.free()
