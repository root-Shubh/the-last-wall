## Headless tests for the main menu (SVTLW-43).
## Run: godot --headless --path game -s res://tests/test_main_menu.gd
extends SceneTree

const TEST_SAVE_PATH: String = "user://save_slot_1.json"

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	var saves: Node = root.get_node("SaveManager")
	var dialogue: DialogueManager = DialogueManager.new()
	root.add_child(dialogue)

	var menu: MainMenu = MainMenu.new()
	menu.game_state = state
	menu.dialogue = dialogue
	menu.saves = saves
	root.add_child(menu)
	menu.build()

	_test_entries(menu)
	_test_continue_follows_save(menu, state, saves)
	_test_new_game_and_character(menu, state, dialogue)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _button(menu: MainMenu, label: String) -> Button:
	for child: Node in menu.get_children():
		for button: Node in child.get_children():
			if button is Button and button.text == label:
				return button
	return null


func _test_entries(menu: MainMenu) -> void:
	print("entries")
	_check(menu.button_labels().size() == 10, "all ten menu entries are listed")
	_check(not menu.is_enabled("Campaign") and _button(menu, "Campaign").disabled, "Campaign is disabled until M5")
	_check(menu.is_enabled("New Game") and menu.is_enabled("Settings") and menu.is_enabled("Credits") and menu.is_enabled("Exit"), "M1 entries are enabled")


func _test_continue_follows_save(menu: MainMenu, state: Node, saves: Node) -> void:
	print("continue")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	_check(not menu.is_enabled("Continue"), "Continue is disabled without a save")
	state.reset()
	state.add_gold(3)
	saves.save_game()
	_check(menu.is_enabled("Continue"), "Continue is enabled once a save exists")
	var continued: Array = [0]
	menu.continue_requested.connect(func() -> void: continued[0] += 1)
	menu._on_pressed("Continue")
	_check(continued[0] == 1, "pressing Continue requests a continue")


func _test_new_game_and_character(menu: MainMenu, state: Node, dialogue: DialogueManager) -> void:
	print("new game and character")
	var asked: Array = [0]
	menu.character_select_requested.connect(func() -> void: asked[0] += 1)
	menu._on_pressed("New Game")
	_check(asked[0] == 1, "New Game asks for a character")
	_check(not menu.start_new_game("robot", "Edric"), "invalid character is refused by the menu")
	var started: Array = []
	menu.new_game_started.connect(func(id: String, name: String) -> void: started.append([id, name]))
	_check(menu.start_new_game("male", "Edric") and started == [["male", "Edric"]], "valid character starts the game")
	_check(state.character_name == "Edric" and dialogue.is_playing(), "the intro starts with the chosen character")
	dialogue.skip()
