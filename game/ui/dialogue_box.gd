## Dialogue box (SVTLW-99, builds on SVTLW-40). Shows the speaker and text of the line the
## DialogueManager is on. Enter or Space advances. Escape skips the whole sequence.
class_name DialogueBox
extends CanvasLayer

var manager: DialogueManager = null
var _speaker: Label
var _text: Label
var _panel: PanelContainer
var _built: bool = false


func build() -> void:
	if _built:
		return
	_built = true
	layer = 25
	_panel = PanelContainer.new()
	_panel.position = Vector2(140.0, 500.0)
	_panel.custom_minimum_size = Vector2(1000.0, 150.0)
	add_child(_panel)
	var column: VBoxContainer = VBoxContainer.new()
	_panel.add_child(column)
	_speaker = Label.new()
	column.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(960.0, 80.0)
	column.add_child(_text)
	var hint: Label = Label.new()
	hint.text = "Enter: next    Esc: skip"
	column.add_child(hint)
	hide()


func bind(dialogue: DialogueManager) -> void:
	build()
	manager = dialogue
	dialogue.line_shown.connect(_on_line)
	dialogue.sequence_finished.connect(func(_id: String) -> void: hide())


func _on_line(speaker: String, text: String, _choices: PackedStringArray) -> void:
	show()
	_speaker.text = speaker
	_text.text = text


func _unhandled_input(event: InputEvent) -> void:
	if manager == null or not manager.is_playing() or not visible:
		return
	if event.is_action_pressed("ui_accept"):
		manager.advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		manager.skip()
		get_viewport().set_input_as_handled()
