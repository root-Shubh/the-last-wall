## Headless tests for SVTLW-80 to SVTLW-85: regions, factions, overlords and post-game.
## Run: godot --headless --path game -s res://tests/test_regions_factions_overlords.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_region_for_wave()
	_test_region_files_load()
	_test_faction_enemies()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _region_id_for(map: RegionMap, wave: int) -> String:
	var region: Region = map.region_for_wave(wave)
	return region.region_id if region != null else ""


func _test_region_for_wave() -> void:
	print("region map")
	var map: RegionMap = RegionMap.new()
	_check(_region_id_for(map, 1) == "fallen_kingdom", "wave 1 is in fallen_kingdom")
	_check(_region_id_for(map, 51) == "ashen_forest", "wave 51 is in ashen_forest")
	_check(_region_id_for(map, 151) == "iron_wastes", "wave 151 is in iron_wastes")
	_check(_region_id_for(map, 301) == "cursed_highlands", "wave 301 is in cursed_highlands")
	_check(_region_id_for(map, 451) == "dead_capital", "wave 451 is in dead_capital")
	_check(map.region_for_wave(601) == null, "wave above the last region is null")


func _test_region_files_load() -> void:
	print("region files")
	for id: String in ["fallen_kingdom", "ashen_forest", "iron_wastes", "cursed_highlands", "dead_capital"]:
		var region: Region = load("res://resources/regions/%s.tres" % id) as Region
		_check(region != null and region.region_id == id, "%s loads with its region_id" % id)
		_check(region != null and region.objective_text != "" and region.enemy_ids.size() > 0,
			"%s has an objective and an enemy mix" % id)


func _enemy(id: String) -> EnemyDefinition:
	return load("res://resources/enemies/%s.tres" % id) as EnemyDefinition


func _test_faction_enemies() -> void:
	print("faction enemies")
	var mechanics: Dictionary = {
		"corrupted_predator": "swarm", "poison_spitter": "pressure", "regenerator": "pressure",
		"ancient_construct": "wall_breaker", "guardian": "shield_bearer", "flying_machine": "climber",
	}
	for id: String in mechanics:
		var enemy: EnemyDefinition = _enemy(id)
		_check(enemy != null and enemy.enemy_id == id and enemy.role == mechanics[id],
			"%s loads with its id and role" % id)
		_check(enemy != null and enemy.faction in ["corrupted", "ancient_horde"],
			"%s belongs to a faction" % id)
	_check(_enemy("poison_spitter").poison_damage_per_second > 0.0, "poison spitter has a poison mechanic")
	_check(_enemy("regenerator").regen_per_second > 0.0, "regenerator has a regeneration mechanic")
	_check(_enemy("guardian").shield_radius > 0.0, "guardian has a shield mechanic")
	_check(_enemy("flying_machine").bypass_wall_armour, "flying machine ignores wall armour")
	for id: String in ["undead_infantry", "runner", "armoured_brute", "shield_bearer", "climber"]:
		var old: EnemyDefinition = _enemy(id)
		_check(old.faction == "" and old.regen_per_second == 0.0 and old.poison_damage_per_second == 0.0,
			"%s keeps the default faction and mechanic values" % id)
