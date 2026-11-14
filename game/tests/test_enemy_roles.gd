## Headless tests for SVTLW-57 enemy roles: shield bearers, climbers and their data.
## Run: godot --headless --path game -s res://tests/test_enemy_roles.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_new_definitions_load()
	_test_shield_reduces_nearby_ally()
	_test_shield_stops_when_bearer_dies()
	_test_climber_walks_unslowed_and_bypasses_armour()
	_test_climber_counter_is_melee()
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


func _manager() -> EnemyManager:
	var manager: EnemyManager = EnemyManager.new()
	manager.definitions = [
		_definition("undead_infantry"), _definition("shield_bearer"), _definition("climber"),
	]
	root.add_child(manager)
	return manager


func _test_new_definitions_load() -> void:
	print("new definitions")
	for id: String in ["shield_bearer", "climber"]:
		var definition: EnemyDefinition = _definition(id)
		_check(definition != null and definition.enemy_id == id, "%s loads with its enemy_id" % id)
		_check(definition != null and definition.gold_reward > 0, "%s has a gold reward" % id)
	var bearer: EnemyDefinition = _definition("shield_bearer")
	_check(bearer.role == "shield_bearer" and bearer.shield_radius > 0.0 and bearer.shield_fraction > 0.0,
		"shield bearer is data-driven with a radius and fraction")
	var climber: EnemyDefinition = _definition("climber")
	_check(climber.role == "climber" and climber.bypass_wall_armour and climber.melee_counter_only,
		"climber is data-driven with wall bypass and melee counter")


func _test_shield_reduces_nearby_ally() -> void:
	print("shield bearer")
	var manager: EnemyManager = _manager()
	var bearer: Enemy = manager.spawn("shield_bearer")
	var near: Enemy = manager.spawn("undead_infantry")
	var far: Enemy = manager.spawn("undead_infantry")
	bearer.position = Vector2(600.0, 360.0)
	near.position = Vector2(640.0, 360.0)
	far.position = Vector2(900.0, 360.0)

	var near_dealt: float = manager.damage_enemy(near, 10.0)
	var far_dealt: float = manager.damage_enemy(far, 10.0)
	_check(absf(near_dealt - 5.0) < 0.001 and absf(near.health - (near.definition.max_health - 5.0)) < 0.001,
		"ally inside the shield radius takes half damage")
	_check(absf(far_dealt - 10.0) < 0.001, "ally outside the shield radius takes full damage")
	_check(absf(bearer.health - bearer.definition.max_health) < 0.001 and manager.shield_fraction_for(bearer) == 0.0,
		"bearer does not shield itself")
	root.remove_child(manager)
	manager.free()


func _test_shield_stops_when_bearer_dies() -> void:
	print("shield ends with the bearer")
	var manager: EnemyManager = _manager()
	var bearer: Enemy = manager.spawn("shield_bearer")
	var ally: Enemy = manager.spawn("undead_infantry")
	bearer.position = Vector2(600.0, 360.0)
	ally.position = Vector2(620.0, 360.0)
	bearer.take_damage(1000.0)
	_check(not bearer.alive and manager.living_count() == 1, "bearer is removed when it dies")
	_check(manager.shield_fraction_for(ally) == 0.0, "no shield once the bearer is dead")
	var dealt: float = manager.damage_enemy(ally, 10.0)
	_check(absf(dealt - 10.0) < 0.001, "ally takes full damage after the bearer dies")
	root.remove_child(manager)
	manager.free()


func _test_climber_walks_unslowed_and_bypasses_armour() -> void:
	print("climber")
	var manager: EnemyManager = _manager()
	var wall_hits: Array = [0.0]
	var unarmoured_hits: Array = [0.0]
	manager.wall_attacked.connect(func(d: float) -> void: wall_hits[0] += d)
	manager.wall_attacked_unarmoured.connect(func(d: float) -> void: unarmoured_hits[0] += d)

	var climber: Enemy = manager.spawn("climber")
	# 1180 to 230 is 950 px at 45 px/s, 4.5 px per tick: 212 ticks, with no wall slowdown.
	var ticks: int = 0
	while not climber.at_wall and ticks < 1000:
		manager.on_tick(ticks)
		ticks += 1
	_check(ticks <= 212, "climber reaches the wall at its full speed (%d ticks)" % ticks)

	var interval: int = climber.definition.attack_interval_ticks
	for i: int in range(interval):
		manager.on_tick(i)
	_check(absf(unarmoured_hits[0] - climber.definition.wall_damage) < 0.001,
		"climber's wall hit goes through the armour-bypass signal")
	_check(wall_hits[0] == 0.0, "climber's wall hit does not use the armoured path")

	var pressure: Enemy = manager.spawn("undead_infantry")
	for i: int in range(500):
		manager.on_tick(i)
	_check(wall_hits[0] > 0.0, "a normal enemy's wall hit still uses the armoured path")
	root.remove_child(manager)
	manager.free()


func _test_climber_counter_is_melee() -> void:
	print("climber counter")
	var climber: Enemy = Enemy.new()
	climber.setup(_definition("climber"), 500.0, 200.0)
	_check(climber.can_be_stopped_by("spearman"), "a spearman can stop a climber")
	_check(climber.can_be_stopped_by("swordsman"), "a swordsman can stop a climber")
	_check(not climber.can_be_stopped_by("archer"), "an archer cannot stop a climber")
	climber.free()

	var infantry: Enemy = Enemy.new()
	infantry.setup(_definition("undead_infantry"), 500.0, 200.0)
	_check(infantry.can_be_stopped_by("archer"), "an archer can stop an ordinary enemy")
	infantry.free()
