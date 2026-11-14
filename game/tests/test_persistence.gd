## Headless tests for battlefield save and load and autosave (SVTLW-44, SVTLW-45).
## Run: godot --headless --path game -s res://tests/test_persistence.gd
extends SceneTree

const SAVE_FILE: String = "user://save_slot_1.json"

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	var saves: Node = root.get_node("SaveManager")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))

	_test_save_and_restore(state, saves)
	_test_autosave_at_wave_end(state, saves)

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _battlefield(state: Node, saves: Node) -> Battlefield:
	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	field.save_manager = saves
	root.add_child(field)
	field.ensure_ready()
	return field


func _test_save_and_restore(state: Node, saves: Node) -> void:
	print("save and restore")
	state.reset()
	state.add_gold(300)
	var field: Battlefield = _battlefield(state, saves)
	field.recruit_archer(Vector2(200.0, 300.0))
	field.recruit_archer(Vector2(190.0, 280.0))
	field.buy_upgrade("archer_damage")
	field.start_wave()
	field.step_ticks(60)
	var gold_before: int = state.gold
	var archers_before: int = field.units.archers.size()
	_check(field.save_now(), "save writes the battlefield part")

	field.get_parent().remove_child(field)
	field.free()
	state.reset()
	_check(saves.load_game(), "load restores game state")
	_check(state.gold == gold_before, "gold restored")

	var restored: Battlefield = _battlefield(state, saves)
	_check(restored.restore_from_save(), "battlefield restores from the save")
	_check(restored.waves.current_wave == 1, "wave number restored")
	_check(restored.upgrades.level("archer_damage") == 1, "upgrade level restored")
	_check(restored.units.archers.size() == archers_before, "archers restored (%d)" % archers_before)
	_check(absf(restored.units.archer_damage_multiplier - 1.1) < 0.0001, "upgrade effect re-applied after restore")
	restored.get_parent().remove_child(restored)
	restored.free()


func _test_autosave_at_wave_end(state: Node, saves: Node) -> void:
	print("autosave at wave end")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
	state.reset()
	state.add_gold(100)
	var field: Battlefield = _battlefield(state, saves)
	field.recruit_archer(Vector2(200.0, 300.0))
	field.start_wave()
	var guard: int = 0
	while field.waves.is_running() and guard < 5000:
		field.step_ticks(1)
		guard += 1
	_check(not field.waves.is_running(), "wave 1 completes")
	_check(saves.has_save(), "a save exists after the wave ended")
	state.reset()
	saves.load_game()
	_check(saves.last_extra.get("battlefield", {}).get("wave", -1) == 1, "the autosave holds the completed wave number")
	field.get_parent().remove_child(field)
	field.free()
