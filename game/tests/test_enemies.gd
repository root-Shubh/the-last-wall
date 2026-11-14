## Headless tests for enemy definitions, behaviour and the enemy manager (SVTLW-33, SVTLW-34).
## Run: godot --headless --path game -s res://tests/test_enemies.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_definitions_load()
	_test_walk_speed()
	_test_reach_and_attack()
	_test_death_once()
	_test_manager_spawn_and_removal()
	_test_wave_wiring()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _definition(id: String) -> EnemyDefinition:
	return load("res://resources/enemies/%s.tres" % id)


func _test_definitions_load() -> void:
	print("definitions")
	var ids: Array = ["undead_infantry", "runner", "armoured_brute"]
	var roles: Dictionary = {}
	for id: String in ids:
		var definition: EnemyDefinition = _definition(id)
		_check(definition != null and definition.enemy_id == id, "%s loads" % id)
		if definition != null:
			roles[definition.role] = true
	_check(roles.size() == 3, "the three M1 enemies have three different roles")


func _test_walk_speed() -> void:
	print("walking")
	var enemy: Enemy = Enemy.new()
	enemy.setup(_definition("undead_infantry"), 1000.0, 200.0)
	enemy.on_tick(0)
	# 30 px/s at 10 ticks per second is 3 px per tick.
	_check(absf(enemy.position.x - 997.0) < 0.001, "moves 3 px per tick at 30 px/s")
	enemy.free()


func _test_reach_and_attack() -> void:
	print("reach and attack")
	var enemy: Enemy = Enemy.new()
	var definition: EnemyDefinition = _definition("armoured_brute")
	enemy.setup(definition, 300.0, 200.0)
	var reached: Array = [0]
	var attacks: Array = [0]
	var last_damage: Array = [0.0]
	enemy.reached_wall.connect(func(_e: Enemy) -> void: reached[0] += 1)
	enemy.attacked_wall.connect(func(_e: Enemy, dmg: float) -> void:
		attacks[0] += 1
		last_damage[0] = dmg)

	var ticks: int = 0
	while not enemy.at_wall and ticks < 1000:
		enemy.on_tick(ticks)
		ticks += 1
	_check(reached[0] == 1, "reached_wall emitted exactly once")
	_check(absf(enemy.position.x - 200.0) < 0.001, "stops at the wall line")

	for i: int in range(definition.attack_interval_ticks * 3):
		enemy.on_tick(i)
	_check(attacks[0] == 3, "attacks once per interval while at the wall")
	_check(absf(last_damage[0] - definition.wall_damage) < 0.001, "attack carries the definition's wall damage")
	enemy.free()


func _test_death_once() -> void:
	print("death")
	var enemy: Enemy = Enemy.new()
	enemy.setup(_definition("runner"), 500.0, 200.0)
	var deaths: Array = [0]
	enemy.died.connect(func(_e: Enemy) -> void: deaths[0] += 1)
	enemy.take_damage(4.0)
	_check(enemy.alive and deaths[0] == 0, "survives damage below max health")
	enemy.take_damage(10.0)
	_check(not enemy.alive and deaths[0] == 1, "dies once when health reaches zero")
	enemy.take_damage(10.0)
	_check(deaths[0] == 1, "further damage after death does not emit again")
	enemy.free()


func _test_manager_spawn_and_removal() -> void:
	print("enemy manager")
	var manager: EnemyManager = EnemyManager.new()
	manager.definitions = [_definition("undead_infantry"), _definition("runner")]
	root.add_child(manager)
	var removed: Array = [0]
	manager.enemy_removed.connect(func(_e: Enemy) -> void: removed[0] += 1)

	var enemy: Enemy = manager.spawn("runner")
	_check(enemy != null and manager.living_count() == 1, "spawns a known enemy id")
	_check(manager.spawn("nope") == null, "unknown id returns null")
	enemy.take_damage(1000.0)
	_check(manager.living_count() == 0 and removed[0] == 1, "a dead enemy is removed and reported once")
	root.remove_child(manager)
	manager.free()


func _test_wave_wiring() -> void:
	print("wave to enemy wiring")
	var catalog: WaveCatalog = load("res://resources/waves/m1_catalog.tres")
	var waves: WaveManager = WaveManager.new()
	waves.catalog = catalog
	var manager: EnemyManager = EnemyManager.new()
	manager.definitions = [_definition("undead_infantry"), _definition("runner"), _definition("armoured_brute")]
	root.add_child(manager)
	waves.enemy_spawn_requested.connect(func(id: String) -> void: manager.spawn(id))
	manager.enemy_removed.connect(func(_e: Enemy) -> void: waves.report_enemy_removed())

	waves.start_next_wave()
	var guard: int = 0
	while waves.is_running() and guard < 10000:
		waves.on_tick(guard)
		manager.on_tick(guard)
		for enemy: Enemy in manager.enemies.duplicate():
			if enemy.at_wall:
				enemy.take_damage(1000.0)
		guard += 1
	_check(not waves.is_running() and waves.current_wave == 1, "wave 1 finishes once every enemy is dealt with")
	_check(manager.living_count() == 0, "no enemies left on the battlefield")
	root.remove_child(manager)
	manager.free()
	waves.free()
