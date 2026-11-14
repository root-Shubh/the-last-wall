## Headless tests for SVTLW-80 to SVTLW-85: regions, factions, overlords and post-game.
## Run: godot --headless --path game -s res://tests/test_regions_factions_overlords.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_region_for_wave()
	_test_region_files_load()
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
