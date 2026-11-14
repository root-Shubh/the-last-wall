## Headless tests for defence structures: towers and archer platforms (SVTLW-54).
## Run: godot --headless --path game -s res://tests/test_defence_structures.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_fires_at_closest_in_range()
	_test_no_fire_out_of_range()
	_test_interval_respected()
	_test_upgrade_raises_damage_and_speed()
	_test_upgrade_at_max_refused()
	_test_visual_scale()
	_test_zero_attack_fields_never_fire()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _enemy(x: float) -> Enemy:
	var definition: EnemyDefinition = EnemyDefinition.new()
	definition.max_health = 100.0
	definition.armour = 0.0
	var enemy: Enemy = Enemy.new()
	enemy.setup(definition, x, 0.0)
	enemy.global_position = Vector2(x, 0.0)
	return enemy


func _structure(id: String) -> DefenceStructure:
	var data: BuildingDefinition = load("res://resources/buildings/%s.tres" % id)
	var structure: DefenceStructure = DefenceStructure.new()
	structure.setup(data, 0, Vector2.ZERO)
	structure.global_position = Vector2.ZERO
	return structure


## Ticks the structure until it fires once or the limit is hit. Returns the tick it fired on, or -1.
func _ticks_until_fire(structure: DefenceStructure, enemies: Array, limit: int) -> int:
	var fired: Array = [-1]
	var handler: Callable = func(_o: Vector2, _t: Enemy, _d: float) -> void:
		if fired[0] == -1:
			fired[0] = 0
	structure.fire_requested.connect(handler)
	for i: int in range(limit):
		structure.on_tick(i, enemies)
		if fired[0] != -1:
			structure.fire_requested.disconnect(handler)
			return i + 1
	structure.fire_requested.disconnect(handler)
	return -1


func _test_fires_at_closest_in_range() -> void:
	print("fires at closest in range")
	var structure: DefenceStructure = _structure("tower")
	var near: Enemy = _enemy(100.0)
	var far: Enemy = _enemy(250.0)
	var targets: Array = []
	structure.fire_requested.connect(func(_o: Vector2, t: Enemy, _d: float) -> void: targets.append(t))
	for i: int in range(10):
		structure.on_tick(i, [far, near])
	_check(targets.size() == 1 and targets[0] == near, "tower shoots the closer of two enemies in range")
	_check(targets.size() == 1 and targets[0].global_position.x == 100.0, "shot is aimed at the closest enemy's position")
	structure.free()


func _test_no_fire_out_of_range() -> void:
	print("no fire out of range")
	var structure: DefenceStructure = _structure("archer_platform")
	var outside: Enemy = _enemy(400.0)
	_check(_ticks_until_fire(structure, [outside], 100) == -1, "archer platform (range 260) never fires at an enemy at 400")
	var dead: Enemy = _enemy(50.0)
	dead.alive = false
	_check(_ticks_until_fire(structure, [dead], 100) == -1, "dead enemy in range is not targeted")
	structure.free()


func _test_interval_respected() -> void:
	print("fire interval respected")
	var structure: DefenceStructure = _structure("tower")
	var enemy: Enemy = _enemy(50.0)
	var shots: Array = []
	structure.fire_requested.connect(func(_o: Vector2, _t: Enemy, _d: float) -> void: shots.append(1))
	for i: int in range(19):
		structure.on_tick(i, [enemy])
	_check(shots.size() == 1, "tower (interval 10) fires once in 19 ticks")
	structure.on_tick(19, [enemy])
	_check(shots.size() == 2, "second shot lands on tick 20")
	structure.free()


func _test_upgrade_raises_damage_and_speed() -> void:
	print("upgrade raises level, damage and speed")
	var structure: DefenceStructure = _structure("tower")
	var enemy: Enemy = _enemy(50.0)
	var before_damage: float = structure.damage_for_level(1)
	var before_interval: int = structure.interval_for_level(1)
	_check(_ticks_until_fire(structure, [enemy], 20) == 10, "level 1 tower fires on tick 10")
	_check(structure.upgrade() and structure.level == 2, "upgrade from 1 to 2 succeeds")
	_check(structure.damage_for_level(2) > before_damage, "level 2 damage is higher than level 1")
	_check(structure.interval_for_level(2) < before_interval, "level 2 interval is shorter than level 1")
	var captured: Array = [0.0]
	structure.fire_requested.connect(func(_o: Vector2, _t: Enemy, d: float) -> void: captured[0] = d)
	_check(_ticks_until_fire(structure, [enemy], 20) == 8, "level 2 tower fires after 8 ticks")
	_check(is_equal_approx(captured[0], 9.0), "level 2 shot damage is 9.0 (6 base x 1.5)")
	structure.free()


func _test_upgrade_at_max_refused() -> void:
	print("upgrade at max refused")
	var structure: DefenceStructure = _structure("tower")
	var changed: Array = [0]
	structure.level_changed.connect(func(_l: int) -> void: changed[0] += 1)
	_check(structure.upgrade() and structure.upgrade(), "tower reaches max level 3")
	_check(not structure.upgrade() and structure.level == 3, "upgrade at max returns false and keeps level 3")
	_check(changed[0] == 2, "level_changed fires only for real upgrades")
	structure.free()


func _test_visual_scale() -> void:
	print("visual scale per level")
	var structure: DefenceStructure = _structure("archer_platform")
	_check(structure.visual_scale_for_level(1) == 1.0, "visual scale is 1.0 at level 1")
	_check(is_equal_approx(structure.visual_scale_for_level(2), 1.25), "visual scale is 1.25 at level 2")
	_check(structure.visual_scale_for_level(3) > structure.visual_scale_for_level(2), "visual scale grows at level 3")
	structure.free()


func _test_zero_attack_fields_never_fire() -> void:
	print("zero attack fields never fire")
	var structure: DefenceStructure = _structure("barracks")
	_check(not structure.is_defence(), "barracks with no attack fields is not a defence")
	var enemy: Enemy = _enemy(10.0)
	_check(_ticks_until_fire(structure, [enemy], 200) == -1, "barracks never fires over 200 ticks")
	_check(not structure.upgrade(), "a non-defence cannot be upgraded")
	structure.free()
