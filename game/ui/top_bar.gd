## Top bar HUD (SVTLW-28). Shows gold, wood, stone, iron, research points, current wave,
## wall health and game speed, and provides pause and 1x, 2x, 3x controls.
## Wood, stone, iron and research are placeholders until M2 adds their production.
class_name TopBar
extends CanvasLayer

const PLACEHOLDER: String = "--"

var _gold_label: Label
var _wood_label: Label
var _stone_label: Label
var _iron_label: Label
var _research_label: Label
var _wave_label: Label
var _wall_label: Label
var _speed_label: Label
var _clock: SimulationClock = null
var _built: bool = false


## Builds the labels and buttons once. Safe to call more than once.
func build() -> void:
	if _built:
		return
	_built = true
	layer = 10
	var bar: HBoxContainer = HBoxContainer.new()
	bar.position = Vector2(12.0, 8.0)
	bar.size = Vector2(1256.0, 32.0)
	add_child(bar)

	_gold_label = _label(bar, "Gold 0")
	_wood_label = _label(bar, "Wood %s" % PLACEHOLDER)
	_stone_label = _label(bar, "Stone %s" % PLACEHOLDER)
	_iron_label = _label(bar, "Iron %s" % PLACEHOLDER)
	_research_label = _label(bar, "Research %s" % PLACEHOLDER)
	_wave_label = _label(bar, "Wave 0")
	_wall_label = _label(bar, "Wall --")
	_speed_label = _label(bar, "Speed 1x")

	_button(bar, "Pause", func() -> void: toggle_pause())
	_button(bar, "1x", func() -> void: set_speed(1))
	_button(bar, "2x", func() -> void: set_speed(2))
	_button(bar, "3x", func() -> void: set_speed(3))


## Connects to the game systems. Call after build() so the labels exist.
func bind(game_state: Node, clock: SimulationClock, waves: WaveManager, wall: WallManager) -> void:
	build()
	_clock = clock
	game_state.resources_changed.connect(func(gold: int) -> void: _gold_label.text = "Gold %d" % gold)
	game_state.wall_health_changed.connect(func(health: int) -> void:
		_wall_label.text = "Wall %d / %d" % [health, game_state.wall_max_health])
	waves.wave_started.connect(func(number: int) -> void: _wave_label.text = "Wave %d" % number)
	clock.speed_changed.connect(func(_s: int) -> void: _refresh_speed())
	clock.paused_changed.connect(func(_p: bool) -> void: _refresh_speed())
	_gold_label.text = "Gold %d" % game_state.gold
	_wall_label.text = "Wall %d / %d" % [game_state.wall_health, game_state.wall_max_health]
	_refresh_speed()


func set_speed(value: int) -> void:
	if _clock == null:
		return
	_clock.set_speed(value)
	_clock.set_paused(false)


func toggle_pause() -> void:
	if _clock == null:
		return
	_clock.toggle_pause()


func speed_text() -> String:
	return _speed_label.text


func _refresh_speed() -> void:
	if _clock == null:
		return
	_speed_label.text = "Paused" if _clock.paused else "Speed %dx" % _clock.speed


func _label(parent: Node, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(110.0, 0.0)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
