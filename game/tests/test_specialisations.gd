## Headless tests for unit specialisations (SVTLW-62).
## Run: godot --headless --path game -s res://tests/test_specialisations.gd
extends SceneTree

const ARCHER_SPECS: Array[String] = ["longbow", "rapid_fire", "fire_arrow"]
const CROSSBOW_SPECS: Array[String] = ["armour_breaker", "repeater", "siege_hunter"]

var _failures: int = 0


func _initialize() -> void:
	_test_all_load()
	_test_second_specialisation_refused()
	_test_wrong_unit_refused()
	_test_applied_values()
	_test_no_specialisation_unchanged()
	_test_no_dominance()
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


## A manager with no gold needed: restore_unit spawns without spending gold.
func _manager() -> UnitManager:
	var manager: UnitManager = UnitManager.new()
	manager.unit_definitions = [_def("archer"), _def("crossbowman")]
	manager.population_cap = 20
	return manager


func _all_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.append_array(ARCHER_SPECS)
	ids.append_array(CROSSBOW_SPECS)
	return ids


func _test_all_load() -> void:
	print("definitions")
	for id: String in _all_ids():
		var spec: SpecialisationDefinition = SpecialisationDefinition.load_by_id(id)
		var unit: String = "archer" if id in ARCHER_SPECS else "crossbowman"
		_check(spec != null and spec.specialisation_id == id and spec.unit_id == unit and spec.weakness != "", "%s loads and names %s" % [id, unit])
	_check(SpecialisationDefinition.load_by_id("nope") == null, "unknown id loads nothing")


func _test_second_specialisation_refused() -> void:
	print("one specialisation per unit")
	var manager: UnitManager = _manager()
	var archer: Archer = manager.restore_unit("archer", Vector2.ZERO)
	_check(manager.set_specialisation(archer, "longbow"), "first specialisation is applied")
	var interval: int = archer.attack_interval_ticks()
	var range_before: float = archer.effective_range()
	_check(not manager.set_specialisation(archer, "rapid_fire"), "second specialisation is refused")
	_check(archer.specialisation_id() == "longbow", "refused second specialisation leaves the first in place")
	_check(archer.attack_interval_ticks() == interval and archer.effective_range() == range_before, "refused second specialisation changes no stats")
	manager.free()


func _test_wrong_unit_refused() -> void:
	print("wrong unit type")
	var manager: UnitManager = _manager()
	var archer: Archer = manager.restore_unit("archer", Vector2.ZERO)
	var crossbow: Archer = manager.restore_unit("crossbowman", Vector2.ZERO)
	_check(not manager.set_specialisation(archer, "repeater"), "crossbow specialisation refused on an archer")
	_check(not manager.set_specialisation(crossbow, "longbow"), "archer specialisation refused on a crossbowman")
	_check(not manager.set_specialisation(null, "longbow"), "null unit is refused")
	_check(not manager.set_specialisation(archer, "nope"), "unknown specialisation is refused")
	_check(archer.specialisation_id() == "" and crossbow.specialisation_id() == "", "refused calls leave both units without a specialisation")
	manager.free()


func _test_applied_values() -> void:
	print("applied values")
	var manager: UnitManager = _manager()
	var crossbow: Archer = manager.restore_unit("crossbowman", Vector2.ZERO)
	var base_interval: int = crossbow.attack_interval_ticks()
	manager.set_specialisation(crossbow, "armour_breaker")
	# 12 ticks at 0.75 attack speed is 16 ticks. Range is 280 x 1.2. Penetration is 2 + 3.
	_check(crossbow.attack_interval_ticks() == 16 and base_interval == 12, "armour breaker interval is 16 ticks (base 12)")
	_check(absf(crossbow.effective_range() - 336.0) < 0.001, "armour breaker range is 336 (base 280)")
	_check(absf(crossbow.effective_penetration() - 5.0) < 0.001, "armour breaker penetration is 5 (base 2)")
	_check(crossbow.damage_multiplier == 1.0, "armour breaker leaves damage unchanged")

	var archer: Archer = manager.restore_unit("archer", Vector2.ZERO)
	manager.set_specialisation(archer, "fire_arrow")
	_check(absf(archer.damage_multiplier - 1.4) < 0.001, "fire arrow damage multiplier is 1.4")
	_check(archer.attack_interval_ticks() == 11, "fire arrow interval is 11 ticks (base 8)")
	manager.set_archer_multipliers(1.1, 1.0)
	_check(absf(archer.damage_multiplier - 1.54) < 0.001, "upgrades stack on top of the specialisation")
	manager.free()


func _test_no_specialisation_unchanged() -> void:
	print("no specialisation")
	var manager: UnitManager = _manager()
	var archer: Archer = manager.restore_unit("archer", Vector2.ZERO)
	_check(archer.attack_interval_ticks() == 8 and archer.effective_range() == 300.0, "unspecialised archer keeps base interval and range")
	_check(archer.effective_penetration() == 0.0 and archer.damage_multiplier == 1.0, "unspecialised archer keeps base penetration and damage")
	_check(_def("archer").attack_interval_ticks == 8 and _def("archer").attack_range == 300.0, "base archer data is not modified")
	manager.free()


## Score for one archer against one enemy: damage per shot after armour, divided by ticks between shots.
## Zero when the enemy is beyond the archer's range. No crits (roll 1.0 with 0 crit chance).
func _score(archer: Archer, armour: float, distance: float) -> float:
	if distance > archer.effective_range():
		return 0.0
	var damage: float = DamageCalculator.calculate(archer.definition.base_damage, archer.damage_multiplier,
		0.0, 1.0, maxf(armour - archer.effective_penetration(), 0.0), 1.0, 1.0)
	return damage / archer.attack_interval_ticks()


## Best specialisation per scenario within one unit family. Scenarios: light swarm, heavy armour, long range.
func _winners(unit_id: String, specs: Array[String], scenarios: Array) -> Array[String]:
	var winners: Array[String] = []
	for scenario: Vector3 in scenarios:
		var best: String = ""
		var best_score: float = 0.0
		var line: String = ""
		for id: String in specs:
			var manager: UnitManager = _manager()
			var archer: Archer = manager.restore_unit(unit_id, Vector2.ZERO)
			manager.set_specialisation(archer, id)
			var score: float = _score(archer, scenario.x, scenario.y)
			line += "%s=%.3f " % [id, score]
			if score > best_score:
				best_score = score
				best = id
			manager.free()
		print("    armour %d at %d px: %s" % [int(scenario.x), int(scenario.y), line.strip_edges()])
		winners.append(best)
	return winners


func _test_no_dominance() -> void:
	print("no dominance (score = damage per tick, in range only)")
	# Vector3(armour, distance, unused). Heavy armour is above each family's base penetration.
	var archer_scenarios: Array = [Vector3(0, 100, 0), Vector3(2, 100, 0), Vector3(0, 400, 0)]
	var crossbow_scenarios: Array = [Vector3(0, 100, 0), Vector3(8, 100, 0), Vector3(0, 300, 0)]
	_check_family("archer", ARCHER_SPECS, archer_scenarios)
	_check_family("crossbowman", CROSSBOW_SPECS, crossbow_scenarios)


func _check_family(unit_id: String, specs: Array[String], scenarios: Array) -> void:
	var winners: Array[String] = _winners(unit_id, specs, scenarios)
	var seen: Dictionary = {}
	for winner: String in winners:
		seen[winner] = true
	for id: String in specs:
		_check(seen.has(id), "%s is best in at least one scenario" % id)
	_check(seen.size() > 1, "no single %s specialisation is best in every scenario" % unit_id)
