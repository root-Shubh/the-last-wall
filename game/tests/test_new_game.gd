## Headless tests for character selection, the opening intro and save compatibility (SVTLW-41, SVTLW-42).
## Run: godot --headless --path game -s res://tests/test_new_game.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	var dialogue: DialogueManager = DialogueManager.new()
	root.add_child(dialogue)
	_test_character_rules(state)
	_test_new_game_intro(state, dialogue)
	_test_save_compatibility(state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_character_rules(state: Node) -> void:
	print("character rules")
	_check(state.is_valid_character("male", "Edric"), "male with a name is valid")
	_check(state.is_valid_character("female", "  Ayla  "), "names are trimmed before the check")
	_check(not state.is_valid_character("robot", "Edric"), "unknown character id is refused")
	_check(not state.is_valid_character("male", "   "), "blank name is refused")
	_check(not state.is_valid_character("male", "A".repeat(17)), "name over 16 characters is refused")
	_check(state.is_valid_character("male", "A".repeat(16)), "16 characters is allowed")


func _test_new_game_intro(state: Node, dialogue: DialogueManager) -> void:
	print("new game and intro")
	state.reset()
	state.add_gold(77)
	_check(not NewGameFlow.start(state, dialogue, "robot", "Edric"), "invalid start is refused")
	_check(state.gold == 77 and not dialogue.is_playing(), "refused start changes nothing")

	_check(NewGameFlow.start(state, dialogue, "female", "Ayla"), "valid start succeeds")
	_check(state.character_id == "female" and state.character_name == "Ayla", "character is stored")
	_check(dialogue.is_playing(), "the opening intro starts")
	dialogue.skip()
	_check(state.has_flag("intro_seen"), "skipping the intro sets intro_seen")

	_check(NewGameFlow.start(state, dialogue, "male", "Edric"), "a second New Game starts")
	_check(dialogue.is_playing(), "the intro plays again on a new game")
	dialogue.skip()


func _test_save_compatibility(state: Node) -> void:
	print("save compatibility")
	state.reset()
	state.set_character("male", "Edric")
	state.set_flag("intro_seen", true)
	state.add_gold(12)
	var saved: Dictionary = state.to_dict()

	state.reset()
	_check(state.from_dict(saved), "save with character and flags loads")
	_check(state.character_name == "Edric" and state.has_flag("intro_seen") and state.gold == 12, "character, flags and gold restored")

	var old_save: Dictionary = {"gold": 5, "wave": 2, "wall_health": 90, "wall_max_health": 100}
	state.reset()
	_check(state.from_dict(old_save), "save from before SVTLW-41 still loads")
	_check(state.character_id == "" and state.flags.is_empty(), "missing character and flags default to empty")

	var bad_flags: Dictionary = old_save.duplicate()
	bad_flags["flags"] = {"intro_seen": "yes"}
	state.reset()
	state.from_dict(bad_flags)
	_check(not state.has_flag("intro_seen"), "non-boolean flag values are dropped")
