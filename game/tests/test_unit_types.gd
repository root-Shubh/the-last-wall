## Headless tests for defender unit types (SVTLW-51).
## Run: godot --headless --path game -s res://tests/test_unit_types.gd
extends SceneTree

const IDS: Array[String] = ["archer", "crossbowman", "gunner", "spearman", "swordsman"]

var _failures: int = 0


func _initialize() -> void:
	_test_all_load()
	_test_roles_differ()
	_test_penetration()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _def(id: String) -> UnitDefinition:
	return load("res://resources/units/%s.tres" % id)


func _test_all_load() -> void:
	print("definitions")
	for id: String in IDS:
		var d: UnitDefinition = _def(id)
		_check(d != null and d.unit_id == id and d.recruit_cost > 0 and d.max_health > 0.0, "%s loads with stats" % id)


func _test_roles_differ() -> void:
	print("roles")
	var gunner: UnitDefinition = _def("gunner")
	var crossbow: UnitDefinition = _def("crossbowman")
	var archer: UnitDefinition = _def("archer")
	var spear: UnitDefinition = _def("spearman")
	var sword: UnitDefinition = _def("swordsman")
	_check(gunner.base_damage > crossbow.base_damage and crossbow.base_damage > archer.base_damage, "gunner hits hardest, then crossbow, then archer")
	_check(gunner.attack_interval_ticks > archer.attack_interval_ticks, "gunner reloads slower than an archer")
	_check(spear.attack_range < archer.attack_range and sword.attack_range < archer.attack_range, "melee units have short range")
	_check(spear.armour_penetration == 0.0 and crossbow.armour_penetration > 0.0 and gunner.armour_penetration > 0.0, "only the crossbow and gunner penetrate armour")
	_check(spear.max_health > archer.max_health and sword.max_health > spear.max_health, "swordsman is the tankiest, spearman next")


func _test_penetration() -> void:
	print("armour penetration")
	var enemy_def: EnemyDefinition = load("res://resources/enemies/armoured_brute.tres")
	var enemy: Enemy = Enemy.new()
	enemy.setup(enemy_def, 0.0, 0.0)
	enemy.global_position = Vector2(100.0, 0.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3

	var plain: Archer = Archer.new()
	plain.setup(_def("archer"), Vector2(0.0, 0.0), rng)
	var shots: Array = []
	plain.fire_requested.connect(func(_o: Vector2, _t: Enemy, dmg: float) -> void: shots.append(dmg))
	for t: int in range(_def("archer").attack_interval_ticks):
		plain.on_tick(t, [enemy])
	var gunner: Archer = Archer.new()
	gunner.setup(_def("gunner"), Vector2(0.0, 0.0), rng)
	gunner.fire_requested.connect(func(_o: Vector2, _t: Enemy, dmg: float) -> void: shots.append(dmg))
	for t: int in range(_def("gunner").attack_interval_ticks):
		gunner.on_tick(t, [enemy])
	_check(shots.size() == 2, "both units fired once")
	# The brute has 4 armour. The archer loses 4 of its 4 damage, the gunner loses only 1 of its 22.
	_check(shots[0] < shots[1] and shots[0] == 0.0, "armour blocks the archer fully while the gunner gets through")
	plain.free()
	gunner.free()
	enemy.free()
