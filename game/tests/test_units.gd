## Headless tests for archers, recruitment and population (SVTLW-31, SVTLW-32).
## Run: godot --headless --path game -s res://tests/test_units.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_targeting_and_fire()
	_test_recruit_cost_and_population()
	_test_fallen_unit_frees_slot()
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


func _enemy(x: float) -> Enemy:
	var definition: EnemyDefinition = load("res://resources/enemies/undead_infantry.tres")
	var enemy: Enemy = Enemy.new()
	enemy.setup(definition, x, 0.0)
	enemy.global_position = Vector2(x, 0.0)
	return enemy


var _game_state: Node = null


func _state() -> Node:
	if _game_state == null:
		_game_state = root.get_node("GameState")
	return _game_state


func _set_gold(amount: int) -> void:
	_state().reset()
	_state().add_gold(amount)


func _new_manager(cap: int) -> UnitManager:
	var manager: UnitManager = UnitManager.new()
	manager.unit_definitions = [_archer_def()]
	manager.population_cap = cap
	manager.state = _state()
	return manager


func _test_targeting_and_fire() -> void:
	print("targeting and fire")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var archer: Archer = Archer.new()
	archer.setup(_archer_def(), Vector2(0.0, 0.0), rng)
	var near: Enemy = _enemy(100.0)
	var far: Enemy = _enemy(250.0)
	var out_of_range: Enemy = _enemy(900.0)
	_check(archer.closest_in_range([far, near, out_of_range]) == near, "targets the closest enemy in range")
	_check(archer.closest_in_range([out_of_range]) == null, "ignores enemies out of range")

	var shots: Array = []
	archer.fire_requested.connect(func(_o: Vector2, t: Enemy, d: float) -> void: shots.append([t, d]))
	for tick: int in range(_archer_def().attack_interval_ticks):
		archer.on_tick(tick, [near])
	_check(shots.size() == 1 and shots[0][0] == near, "fires once per attack interval at the closest target")
	_check(shots[0][1] >= 0.0, "damage is computed through DamageCalculator")
	archer.free()


func _test_recruit_cost_and_population() -> void:
	print("recruit cost and population")
	_set_gold(45)
	var manager: UnitManager = _new_manager(2)
	root.add_child(manager)

	var first: Archer = manager.recruit("archer", Vector2(0.0, 0.0))
	_check(first != null and _state().gold == 25, "recruit spends the recruit cost")
	var second: Archer = manager.recruit("archer", Vector2(0.0, 0.0))
	_check(second != null and _state().gold == 5, "second recruit spends again")
	_check(manager.recruit("archer", Vector2(0.0, 0.0)) == null, "recruit refused when gold is short")
	_check(_state().gold == 5, "refused recruit does not spend gold")

	_set_gold(500)
	_check(manager.recruit("archer", Vector2(0.0, 0.0)) == null, "recruit refused when population is full")
	_check(manager.population_used() == 2, "population used counts recruited units")
	root.remove_child(manager)
	manager.free()


func _test_fallen_unit_frees_slot() -> void:
	print("fallen unit frees a slot")
	_set_gold(100)
	var manager: UnitManager = _new_manager(1)
	root.add_child(manager)
	var archer: Archer = manager.recruit("archer", Vector2(0.0, 0.0))
	archer.take_damage(1000.0)
	_check(manager.population_used() == 0, "a fallen archer frees its population slot")
	_check(manager.recruit("archer", Vector2(0.0, 0.0)) != null, "a replacement can be recruited into the freed slot")
	root.remove_child(manager)
	manager.free()
