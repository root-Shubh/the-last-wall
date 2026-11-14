## Credits screen (SVTLW-43). A plain panel with the credits text and a Back button.
class_name CreditsScreen
extends CanvasLayer

signal closed

const CREDITS_TEXT: String = "THE LAST WALL\n\nA fortress defence game.\n\nDesign, code and placeholder art: the development team.\nMusic and sound: placeholder, to be replaced.\n\nThank you for playing."

var _built: bool = false


func build() -> void:
	if _built:
		return
	_built = true
	layer = 30
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.08, 0.09, 0.12, 1.0)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	add_child(backdrop)
	var text: Label = Label.new()
	text.text = CREDITS_TEXT
	text.position = Vector2(340.0, 150.0)
	text.size = Vector2(600.0, 380.0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 22)
	add_child(text)
	var back: Button = Button.new()
	back.text = "Back"
	back.position = Vector2(540.0, 580.0)
	back.custom_minimum_size = Vector2(200.0, 40.0)
	back.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	add_child(back)
	visible = false


func open() -> void:
	build()
	visible = true
