## Headless integration test: M2 systems wired into the live battlefield (SVTLW-100).
## Run: godot --headless --path game -s res://tests/test_m2_integration.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	_test_tower_builds_and_fires(state)
	_test_lumber_mill_adds_wood(state)
	_test_generator_drives_waves(state)
	_test_unarmoured_wall_damage(state)
	_test_upgrade_refused_at_max(state)

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _field(state: Node) -> Battlefield:
	state.reset()
	state.add_gold(1000)
	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	root.add_child(field)
	field.ensure_ready()
	return field


## Ticks until the condition holds or the limit is reached. Returns the ticks run.
func _tick_until(field: Battlefield, done: Callable, limit: int) -> int:
	var ticks: int = 0
	while not done.call() and ticks < limit:
		field.step_ticks(1)
		ticks += 1
	return ticks


func _test_tower_builds_and_fires(state: Node) -> void:
	print("tower builds and fires")
	var field: Battlefield = _field(state)
	_check(field.build("tower", 0) and state.gold == 940, "tower build starts and spends 60 gold")
	var built: int = _tick_until(field, func() -> bool: return field.constructions.is_built("tower"), 200)
	_check(field.constructions.is_built("tower") and built >= 50, "tower completes after its build time (%d ticks)" % built)
	var enemy: Enemy = field.enemies.spawn("undead_infantry")
	var fired: int = _tick_until(field, func() -> bool: return enemy.health < enemy.definition.max_health, 2000)
	_check(enemy.health < enemy.definition.max_health, "tower fires at the spawned enemy (%d ticks)" % fired)
	field.free()


func _test_lumber_mill_adds_wood(state: Node) -> void:
	print("lumber mill")
	var field: Battlefield = _field(state)
	var wood_before: int = state.wood
	_check(field.build("lumber_mill", field.free_slot()), "lumber mill build starts on a free slot")
	_tick_until(field, func() -> bool: return field.constructions.is_built("lumber_mill"), 200)
	_check(field.production.is_registered("lumber_mill"), "completed lumber mill is registered for production")
	field.step_ticks(40)
	_check(state.wood > wood_before, "wood rises after production intervals (%d -> %d)" % [wood_before, state.wood])
	field.free()


func _test_generator_drives_waves(state: Node) -> void:
	print("generator drives waves")
	var field: Battlefield = _field(state)
	var expected: WaveDefinition = field.waves.generator.generate(1) if field.waves.generator != null else null
	_check(expected != null, "battlefield waves use a generator that returns wave 1")
	var spawned: Array[String] = []
	field.waves.enemy_spawn_requested.connect(func(id: String) -> void: spawned.append(id))
	_check(field.start_wave() and field.waves.current_wave == 1, "wave 1 starts")
	_tick_until(field, func() -> bool: return not field.waves.is_running(), 5000)
	_check(expected != null and spawned.size() == expected.enemy_count, "wave 1 spawns the generator's enemy count")
	var all_match: bool = expected != null and spawned.all(func(id: String) -> bool: return id == expected.enemy_type_id)
	_check(all_match and not spawned.is_empty(), "wave 1 enemy type matches the generator")
	field.free()


func _test_unarmoured_wall_damage(state: Node) -> void:
	print("unarmoured wall damage")
	var field: Battlefield = _field(state)
	var start: int = state.wall_health
	field.enemies.wall_attacked_unarmoured.emit(10.0)
	_check(state.wall_health == start - 10, "unarmoured attack takes full damage (no armour)")
	field.enemies.wall_attacked.emit(10.0)
	_check(state.wall_health == start - 19, "armoured attack still loses armour (10 - 1 = 9)")
	field.free()


func _test_upgrade_refused_at_max(state: Node) -> void:
	print("upgrades")
	var field: Battlefield = _field(state)
	_check(not field.upgrade_building("tower") and state.gold == 1000, "upgrade of an unbuilt tower is refused with no spend")
	field.build("tower", 0)
	_tick_until(field, func() -> bool: return field.constructions.is_built("tower"), 200)
	var gold: int = state.gold
	_check(field.upgrade_building("tower") and state.gold == gold - 25, "first upgrade is charged 25 gold")
	_check(field.upgrade_building("tower") and state.gold == gold - 75, "second upgrade is charged 50 gold")
	_check(not field.upgrade_building("tower") and state.gold == gold - 75, "upgrade at max level is refused with no spend")
	field.free()
