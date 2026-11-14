## Entry scene for The Last Wall (SVTLW-99). Runs the whole flow:
## main menu -> character picker -> opening intro -> battlefield, or Continue -> battlefield with the save.
## Press Play in Godot to start. Everything the player needs is on screen; no code calls are needed.
extends Node2D

const BATTLEFIELD_SCENE: String = "res://scenes/battlefield.tscn"

var menu: MainMenu = null
var picker: CharacterSelect = null
var dialogue: DialogueManager = null
var dialogue_box: DialogueBox = null
var battlefield: Battlefield = null
var battle_controls: BattleControls = null
## Autoloads, injected by tests. In the game they are looked up when the scene starts.
var game_state: Node = null
var save_manager: Node = null
var _started: bool = false


func _ready() -> void:
	ensure_started()


## Builds the menus once. Safe to call more than once. Tests call it directly.
func ensure_started() -> void:
	if _started:
		return
	_started = true
	if game_state == null:
		game_state = get_node_or_null("/root/GameState")
	if save_manager == null:
		save_manager = get_node_or_null("/root/SaveManager")
	var state: Node = game_state
	var saves: Node = save_manager

	dialogue = DialogueManager.new()
	add_child(dialogue)
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	dialogue_box.bind(dialogue)

	menu = MainMenu.new()
	menu.game_state = state
	menu.dialogue = dialogue
	menu.saves = saves
	add_child(menu)
	menu.build()
	menu.character_select_requested.connect(_show_picker)
	menu.new_game_started.connect(_on_new_game_started)
	menu.continue_requested.connect(_on_continue)
	menu.exit_requested.connect(func() -> void: get_tree().quit())

	picker = CharacterSelect.new()
	picker.game_state = state
	add_child(picker)
	picker.build()
	picker.confirmed.connect(func(id: String, display_name: String) -> void: menu.start_new_game(id, display_name))
	picker.cancelled.connect(func() -> void: picker.hide())


func _show_picker() -> void:
	picker.show()


## The intro plays first when a new game starts. The battlefield opens when the intro ends.
func _on_new_game_started(_character_id: String, _display_name: String) -> void:
	picker.hide()
	if dialogue.is_playing():
		dialogue.sequence_finished.connect(func(_id: String) -> void: _enter_battlefield(false), CONNECT_ONE_SHOT)
	else:
		_enter_battlefield(false)


func _on_continue() -> void:
	if save_manager.load_game():
		_enter_battlefield(true)


func _enter_battlefield(restore: bool) -> void:
	if battlefield != null:
		return
	menu.queue_free()
	battlefield = load(BATTLEFIELD_SCENE).instantiate()
	battlefield.game_state = game_state
	battlefield.save_manager = save_manager
	battlefield.audio = get_node_or_null("/root/AudioManager")
	add_child(battlefield)
	battlefield.ensure_ready()
	if restore:
		battlefield.restore_from_save()

	battle_controls = BattleControls.new()
	add_child(battle_controls)
	battle_controls.bind(battlefield)
	battle_controls.quit_requested.connect(func() -> void: get_tree().quit())
