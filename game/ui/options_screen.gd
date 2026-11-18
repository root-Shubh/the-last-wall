## Settings screen (SVTLW-37, SVTLW-50). Screen shake, damage numbers and the three volume buses.
## Changes apply at once and are saved to user://settings.cfg when Back is pressed.
class_name OptionsScreen
extends CanvasLayer

signal closed

var _built: bool = false
var _settings: SettingsStore = null
var _shake: CheckBox
var _numbers: CheckBox
var _music: HSlider
var _sfx: HSlider
var _voice: HSlider
var _music_value: Label
var _sfx_value: Label
var _voice_value: Label


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

	var title: Label = Label.new()
	title.text = "Settings"
	title.position = Vector2(0.0, 60.0)
	title.size = Vector2(1280.0, 60.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	add_child(title)

	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(420.0, 160.0)
	column.custom_minimum_size = Vector2(440.0, 0.0)
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	_shake = CheckBox.new()
	_shake.text = "Screen shake"
	_shake.toggled.connect(func(on: bool) -> void: _settings.screen_shake_enabled = on)
	column.add_child(_shake)
	_numbers = CheckBox.new()
	_numbers.text = "Damage numbers"
	_numbers.toggled.connect(func(on: bool) -> void: _settings.damage_numbers_enabled = on)
	column.add_child(_numbers)

	var music: Array = _slider_row(column, "Music volume")
	_music = music[0]
	_music_value = music[1]
	var sfx: Array = _slider_row(column, "Effects volume")
	_sfx = sfx[0]
	_sfx_value = sfx[1]
	var voice: Array = _slider_row(column, "Voice volume")
	_voice = voice[0]
	_voice_value = voice[1]

	var back: Button = Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(200.0, 40.0)
	back.pressed.connect(_on_back)
	column.add_child(back)
	visible = false


func _slider_row(parent: Node, label_text: String) -> Array:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(170.0, 0.0)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.custom_minimum_size = Vector2(170.0, 0.0)
	row.add_child(slider)
	var value: Label = Label.new()
	value.custom_minimum_size = Vector2(50.0, 0.0)
	row.add_child(value)
	return [slider, value]


## Loads the saved values into the controls, then shows the screen.
func open(settings: SettingsStore) -> void:
	build()
	_settings = settings
	_settings.load_from()
	_shake.button_pressed = _settings.screen_shake_enabled
	_numbers.button_pressed = _settings.damage_numbers_enabled
	_music.value = _settings.music_percent
	_sfx.value = _settings.sfx_percent
	_voice.value = _settings.voice_percent
	_refresh_values()
	for slider: HSlider in [_music, _sfx, _voice]:
		if not slider.value_changed.is_connected(_on_volume_changed):
			slider.value_changed.connect(_on_volume_changed)
	visible = true


func _on_volume_changed(_value: float) -> void:
	_settings.music_percent = int(_music.value)
	_settings.sfx_percent = int(_sfx.value)
	_settings.voice_percent = int(_voice.value)
	_refresh_values()


func _refresh_values() -> void:
	_music_value.text = "%d%%" % int(_music.value)
	_sfx_value.text = "%d%%" % int(_sfx.value)
	_voice_value.text = "%d%%" % int(_voice.value)


func _on_back() -> void:
	_settings.save_to()
	visible = false
	closed.emit()
