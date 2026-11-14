## Headless smoke tests for GameState and SaveManager (SVTLW-23).
## Run: godot --headless --path game -s res://tests/test_autoloads.gd
## Replaced by the GUT suite in SVTLW-46.
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_spend_gold()
	_test_wall_damage_and_repair()
	_test_from_dict_rejects_bad_data()
	_test_save_round_trip()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _state() -> Node:
	return root.get_node("GameState")


func _saves() -> Node:
	return root.get_node("SaveManager")


func _test_spend_gold() -> void:
	print("spend_gold")
	var state: Node = _state()
	state.reset()
	state.add_gold(50)
	_check(state.spend_gold(30), "spend within balance succeeds")
	_check(state.gold == 20, "balance reduced by cost")
	_check(not state.spend_gold(21), "spend over balance fails")
	_check(state.gold == 20, "failed spend leaves balance unchanged")
	_check(not state.spend_gold(-5), "negative cost is rejected")


func _test_wall_damage_and_repair() -> void:
	print("wall health")
	var state: Node = _state()
	state.reset()
	state.damage_wall(40)
	_check(state.wall_health == 60, "damage reduces health")
	state.damage_wall(999)
	_check(state.wall_health == 0, "health floors at zero")
	_check(state.is_wall_destroyed(), "wall destroyed at zero")
	state.repair_wall(500)
	_check(state.wall_health == state.wall_max_health, "repair caps at max health")


func _test_from_dict_rejects_bad_data() -> void:
	print("from_dict validation")
	var state: Node = _state()
	state.reset()
	state.add_gold(7)
	_check(not state.from_dict({"gold": 1}), "missing keys rejected")
	_check(not state.from_dict({"gold": "lots", "wave": 1, "wall_health": 1, "wall_max_health": 1}), "non-numeric rejected")
	_check(not state.from_dict({"gold": -1, "wave": 1, "wall_health": 1, "wall_max_health": 1}), "negative rejected")
	_check(not state.from_dict({"gold": 1, "wave": 1, "wall_health": 5, "wall_max_health": 3}), "health above max rejected")
	_check(state.gold == 7, "rejected data leaves state untouched")


func _test_save_round_trip() -> void:
	print("save round-trip")
	var state: Node = _state()
	var saves: Node = _saves()
	state.reset()
	state.add_gold(123)
	state.set_wave(4)
	state.damage_wall(25)
	_check(saves.save_game(), "save writes successfully")
	_check(saves.has_save(), "save file exists")

	state.reset()
	_check(saves.load_game(), "load succeeds")
	_check(state.gold == 123, "gold restored")
	_check(state.current_wave == 4, "wave restored")
	_check(state.wall_health == 75, "wall health restored")

	# Overwriting an existing save must keep the new data and leave no backup behind.
	state.add_gold(10)
	_check(saves.save_game(), "second save over existing file succeeds")
	state.reset()
	_check(saves.load_game() and state.gold == 133, "second save is the one loaded")
	_check(not FileAccess.file_exists("user://save_slot_1.bak"), "no backup left after success")
