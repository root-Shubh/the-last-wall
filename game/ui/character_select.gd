## Character picker (SVTLW-99, builds on SVTLW-42). Name field plus male and female buttons.
## Validation is GameState.is_valid_character, so the screen and the logic cannot disagree.
class_name CharacterSelect
extends CanvasLayer

signal confirmed(character_id: String, display_name: String)
signal cancelled

var game_state: Node = null
var _name_edit: LineEdit
var _error: Label
var _built: bool = false


func build() -> void:
	if _built:
		return
	_built = true
	layer = 30
	var panel: VBoxContainer = VBoxContainer.new()
	panel.position = Vector2(440.0, 200.0)
	panel.custom_minimum_size = Vector2(400.0, 0.0)
	add_child(panel)

	var title: Label = Label.new()
	title.text = "Choose your commander"
	panel.add_child(title)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Name (1 to 16 characters)"
	_name_edit.max_length = GameState.NAME_MAX_LENGTH if game_state == null else game_state.NAME_MAX_LENGTH
	panel.add_child(_name_edit)

	var male: Button = Button.new()
	male.text = "Male commander"
	male.pressed.connect(func() -> void: _choose("male"))
	panel.add_child(male)

	var female: Button = Button.new()
	female.text = "Female commander"
	female.pressed.connect(func() -> void: _choose("female"))
	panel.add_child(female)

	var back: Button = Button.new()
	back.text = "Back"
	back.pressed.connect(func() -> void: cancelled.emit())
	panel.add_child(back)

	_error = Label.new()
	panel.add_child(_error)
	hide()


func _choose(character_id: String) -> void:
	var display_name: String = _name_edit.text
	if game_state == null or not game_state.is_valid_character(character_id, display_name):
		_error.text = "Enter a name of 1 to 16 characters."
		return
	_error.text = ""
	confirmed.emit(character_id, display_name.strip_edges())


func name_text() -> String:
	return _name_edit.text
