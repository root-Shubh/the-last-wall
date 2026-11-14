## Main menu (SVTLW-43). M1 enables Continue, New Game, Settings, Credits and Exit. The other
## entries are listed but disabled until their milestone, so the menu layout is final from day one.
class_name MainMenu
extends CanvasLayer

signal character_select_requested
signal new_game_started(character_id: String, display_name: String)
signal continue_requested
signal settings_requested
signal credits_requested
signal exit_requested

## label -> milestone that enables it. Empty string means enabled in M1.
const ENTRIES: Array[Array] = [
	["Continue", ""],
	["New Game", ""],
	["Campaign", "M5"],
	["Endless Siege", "M5"],
	["Challenges", "M5"],
	["Achievements", "M5"],
	["Statistics", "M5"],
	["Settings", ""],
	["Credits", ""],
	["Exit", ""],
]

var game_state: Node = null
var dialogue: DialogueManager = null
var saves: Node = null
var _buttons: Dictionary = {}


## Builds the buttons. Safe to call more than once.
func build() -> void:
	if not _buttons.is_empty():
		return
	layer = 20
	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(540.0, 180.0)
	column.custom_minimum_size = Vector2(200.0, 0.0)
	add_child(column)
	for entry: Array in ENTRIES:
		var label: String = entry[0]
		var button: Button = Button.new()
		button.text = label
		button.disabled = not is_enabled(label)
		if button.disabled:
			button.tooltip_text = "Coming in %s" % entry[1]
		button.pressed.connect(func() -> void: _on_pressed(label))
		column.add_child(button)
		_buttons[label] = button


func is_enabled(label: String) -> bool:
	for entry: Array in ENTRIES:
		if entry[0] == label:
			if entry[1] != "":
				return false
			if label == "Continue":
				return has_save()
			return true
	return false


func has_save() -> bool:
	return saves != null and saves.has_save()


func button_labels() -> Array[String]:
	var labels: Array[String] = []
	for entry: Array in ENTRIES:
		labels.append(entry[0])
	return labels


## Starts a new game with the chosen character. Returns false if the choice is invalid.
func start_new_game(character_id: String, display_name: String) -> bool:
	if not NewGameFlow.start(game_state, dialogue, character_id, display_name):
		return false
	new_game_started.emit(character_id, display_name)
	return true


func _on_pressed(label: String) -> void:
	match label:
		"Continue":
			continue_requested.emit()
		"New Game":
			character_select_requested.emit()
		"Settings":
			settings_requested.emit()
		"Credits":
			credits_requested.emit()
		"Exit":
			exit_requested.emit()
