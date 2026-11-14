## Headless launch test (SVTLW-99): the real entry scene, menu to battlefield, using the same
## methods the buttons call. Run: godot --headless --path game -s res://tests/test_launch.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.game_state = root.get_node("GameState")
	main.save_manager = root.get_node("SaveManager")
	root.add_child(main)
	main.ensure_started()

	print("menu")
	_check(main.menu != null and main.menu.button_labels().size() == 10, "main menu is built with its ten entries")
	_check(main.picker != null and not main.picker.visible, "character picker starts hidden")
	main._show_picker()
	_check(main.picker.visible, "New Game opens the character picker")

	print("character picker")
	var confirmed: Array = [0]
	main.picker.confirmed.connect(func(_id: String, _name: String) -> void: confirmed[0] += 1)
	main.picker._name_edit.text = "   "
	main.picker._choose("male")
	_check(confirmed[0] == 0 and main.picker._error.text != "", "a blank name is refused and an error is shown")
	_check(main.battlefield == null, "a refused name does not start the game")

	print("new game and intro")
	main.menu.start_new_game("female", "Ayla")
	_check(main.dialogue.is_playing(), "the intro plays on New Game")
	_check(main.battlefield == null, "the battlefield waits for the intro")
	main.dialogue.skip()
	_check(main.battlefield != null, "the battlefield opens when the intro ends")

	print("battle controls")
	var controls: BattleControls = main.battle_controls
	var archer: Archer = controls.recruit()
	_check(archer != null and main.battlefield.units.archers.size() == 1, "Recruit Archer adds an archer on the fortress")
	_check(controls.start_wave(), "Start Wave starts wave 1")
	main.battlefield.step_ticks(30)
	_check(main.battlefield.clock.tick_index > 0, "time advances once a wave runs")
	_check(controls.save(), "Save writes the game")

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)
