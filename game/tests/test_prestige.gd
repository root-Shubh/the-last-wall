## Headless tests for prestige, Ancient Relics and specialisation paths (SVTLW-73, SVTLW-74).
## Run: godot --headless --path game -s res://tests/test_prestige.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	_test_relic_formula()
	_test_reset(state)
	_test_relic_purchases(state)
	_test_relic_caps(state)
	_test_save_fields(state)
	_test_paths(state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _manager(state: Node) -> PrestigeManager:
	var manager: PrestigeManager = PrestigeManager.new()
	manager.state = state
	root.add_child(manager)
	return manager


func _test_relic_formula() -> void:
	print("relic formula")
	_check(PrestigeManager.relics_for_progress(0, 0) == 0, "wave 0 with no kills gives no relics")
	_check(PrestigeManager.relics_for_progress(19, 10000) == 0, "below wave 20 gives no relics even with many kills")
	_check(PrestigeManager.relics_for_progress(20, 0) == 2, "wave 20 gives 2 relics from the wave")
	_check(PrestigeManager.relics_for_progress(29, 0) == 2, "floor applies to the wave term")
	_check(PrestigeManager.relics_for_progress(50, 1000) == 7, "wave 50 and 1000 kills give 5 + 2 = 7")
	_check(PrestigeManager.relics_for_progress(50, 499) == 5, "kills below 500 add nothing")
	_check(PrestigeManager.relics_for_progress(60, 0) > PrestigeManager.relics_for_progress(40, 0), "relics grow with the wave")
	_check(PrestigeManager.relics_for_progress(40, 2000) > PrestigeManager.relics_for_progress(40, 500), "relics grow with kills")


func _test_reset(state: Node) -> void:
	print("prestige reset")
	state.reset()
	state.set_wave(25)
	state.add_gold(300)
	state.add_material("wood", 40)
	state.set_flag("intro_seen", true)
	state.set_wall_max_health(160)
	state.set_flag("kept", true)
	state.prestige_path = "warlord"
	var manager: PrestigeManager = _manager(state)
	var gained: int = manager.reset_for_prestige({"highest_wave": 25, "total_kills": 600})
	_check(gained == 3, "reset returns the relics gained (2 + 1)")
	_check(state.relics == 3, "relics are added to the count")
	_check(state.prestige_path == "warlord", "reset keeps the chosen path")
	_check(state.prestige_count == 1, "reset counts one prestige")
	_check(state.current_wave == 0, "reset clears the wave")
	_check(state.gold == 0, "reset clears gold")
	_check(state.wood == 0, "reset clears materials")
	_check(state.wall_max_health == GameState.DEFAULT_WALL_MAX_HEALTH, "reset restores the wall")
	_check(not state.has_flag("intro_seen"), "reset clears run flags")
	var early: int = manager.reset_for_prestige({"highest_wave": 12, "total_kills": 900})
	_check(early == 0 and state.relics == 3, "early reset earns nothing and keeps the count")
	_check(state.prestige_count == 2, "early reset still counts as a prestige")
	manager.free()


func _test_relic_purchases(state: Node) -> void:
	print("relic purchases")
	state.reset()
	state.relics = 5
	var manager: PrestigeManager = _manager(state)
	_check(manager.buy_relic("starting_gold") and state.relics == 4, "buying starting gold spends 1 relic")
	_check(manager.relic_level("starting_gold") == 1, "level rises to 1")
	_check(manager.buy_relic("population_slot") and state.relics == 1, "population slot costs 3 relics")
	var refused: String = manager.relic_block_reason("archer_damage")
	_check(refused == "not enough relics", "unaffordable relic is refused with a reason")
	_check(not manager.buy_relic("archer_damage") and state.relics == 1, "refused buy changes no relics")
	_check(manager.relic_level("archer_damage") == 0, "refused buy changes no level")
	_check(not manager.buy_relic("no_such_relic") and state.relics == 1, "unknown relic is refused")
	_check(manager.effect_total("starting_gold") == 50.0, "starting gold effect is 50 per level")
	manager.free()


func _test_relic_caps(state: Node) -> void:
	print("relic level caps")
	state.reset()
	state.relics = 100
	var manager: PrestigeManager = _manager(state)
	for i: int in 3:
		manager.buy_relic("population_slot")
	_check(manager.relic_level("population_slot") == 3, "population slot stops at its max level 3")
	_check(manager.relic_block_reason("population_slot") == "max level reached", "max level blocks further buys")
	_check(not manager.buy_relic("population_slot") and state.relics == 91, "capped buy spends nothing")
	manager.free()


func _test_save_fields(state: Node) -> void:
	print("save fields")
	state.reset()
	state.relics = 7
	state.prestige_count = 2
	state.prestige_path = "scholar"
	state.relic_levels = {"archer_damage": 3}
	var saved: Dictionary = state.to_dict()
	state.reset()
	_check(state.from_dict(saved), "saved state with prestige fields loads")
	_check(state.relics == 7 and state.prestige_count == 2, "relics and prestige count round trip")
	_check(state.prestige_path == "scholar", "path round trips")
	_check(state.relic_levels == {"archer_damage": 3}, "relic levels round trip")
	var old: Dictionary = saved.duplicate()
	for key: String in ["relics", "relic_levels", "prestige_count", "prestige_path"]:
		old.erase(key)
	state.relics = 9
	_check(state.from_dict(old), "save from before prestige still loads")
	_check(state.relics == 0 and state.prestige_count == 0 and state.prestige_path == "", "old save loads prestige defaults")
	var bad: Dictionary = saved.duplicate()
	bad["prestige_path"] = "bogus"
	bad["relics"] = -4
	state.from_dict(bad)
	_check(state.prestige_path == "" and state.relics == 0, "unknown path and negative relics are dropped on load")
	state.reset()


func _test_paths(state: Node) -> void:
	print("specialisation paths")
	var expected: Array[String] = ["warlord", "architect", "merchant", "scholar", "arcanist"]
	for path_id: String in expected:
		var data: PrestigePath = PrestigePath.load_by_id(path_id)
		_check(data != null and data.path_id == path_id, "%s loads" % path_id)
		if data == null:
			continue
		_check(data.bonus_stat != "" and data.bonus_value > 0.0, "%s has a numeric bonus" % path_id)
		_check(data.mechanic_text != "" and not data.mechanic_effects.is_empty(), "%s has a mechanic" % path_id)
		var hook: Dictionary = PrestigePath.hook_for(path_id, data.mechanic_event)
		_check(not hook.is_empty() and hook == data.mechanic_effects, "%s hook fires on its event" % path_id)
		_check(PrestigePath.hook_for(path_id, "no_such_event").is_empty(), "%s hook ignores other events" % path_id)
	_check(PrestigePath.hook_for("unknown_path", "wave_cleared").is_empty(), "hook for an unknown path is empty")
	var manager: PrestigeManager = PrestigeManager.new()
	manager.state = state
	root.add_child(manager)
	state.reset()
	_check(manager.choose_path("merchant") and state.prestige_path == "merchant", "a known path is chosen and stored")
	_check(not manager.choose_path("paladin") and state.prestige_path == "merchant", "an unknown path is refused")
	state.reset()
	manager.free()
