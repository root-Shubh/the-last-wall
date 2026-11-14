## On-screen battle controls (SVTLW-99). Two rows of buttons at the bottom: recruit, waves, buildings,
## abilities, research, prestige and save. Prestige options open in a panel. Each button calls the same
## method a test calls, so the buttons are covered by tests too. Layout fixed for SVTLW-104.
class_name BattleControls
extends CanvasLayer

signal quit_requested

var field: Battlefield = null
var _built: bool = false
const RECRUIT_START_X: float = 190.0
const RECRUIT_STEP_X: float = 30.0
const RECRUIT_Y: float = 300.0
const ROW_A_Y: float = 640.0
const ROW_B_Y: float = 680.0
const PRESTIGE_PANEL_POSITION: Vector2 = Vector2(12.0, 230.0)
const MESSAGE_POSITION: Vector2 = Vector2(12.0, 600.0)

const BUILDING_IDS: Array[String] = ["tower", "archer_platform", "lumber_mill", "quarry", "iron_mine"]
const BUILDING_LABELS: Dictionary = {
	"tower": "Tower",
	"archer_platform": "Archer Pad",
	"lumber_mill": "Lumber",
	"quarry": "Quarry",
	"iron_mine": "Iron",
}
const ABILITY_LABELS: Dictionary = {
	Abilities.RAIN_OF_ARROWS: "Rain",
	Abilities.EMERGENCY_REPAIR: "Repair",
	Abilities.REINFORCEMENT: "Reinforce",
	Abilities.LAST_STAND: "Last Stand",
}
const PRESTIGE_RELICS: Array[String] = ["starting_gold", "archer_damage", "production", "population_slot"]
const RELIC_LABELS: Dictionary = {
	"starting_gold": "Gold",
	"archer_damage": "Archers",
	"production": "Production",
	"population_slot": "Slot",
}
const PRESTIGE_PATHS: Array[String] = ["warlord", "architect", "merchant", "scholar", "arcanist"]

## Label that shows the collapse and ending text (SVTLW-84).
var ending_label: Label = null
## Line for Overseer messages, death lines and achievements.
var message_label: Label = null
var _prestige_panel: VBoxContainer = null
var _prestige_holder: PanelContainer = null
var _game_over_panel: PanelContainer = null


func bind(battlefield: Battlefield) -> void:
	field = battlefield
	build()
	if not field.ending_step.is_connected(show_ending_step):
		field.ending_step.connect(show_ending_step)
	field.overseer_message.connect(show_message)
	field.death_line.connect(show_message)
	field.region_entered.connect(func(region_name: String) -> void: show_message("Region: " + region_name))
	field.notice.connect(show_message)
	field.game_over.connect(show_game_over)
	field.achievement_unlocked.connect(func(achievement_id: String) -> void: show_message("Achievement: " + achievement_id))
	show_region_and_challenge()


## Shows a short line for an Overseer message, a death line or an achievement (SVTLW-67, 68, 78, 79).
func show_message(text: String) -> void:
	if message_label == null:
		message_label = Label.new()
		message_label.position = MESSAGE_POSITION
		add_child(message_label)
	message_label.text = text
	message_label.visible = text != ""


func build() -> void:
	if _built:
		return
	_built = true
	layer = 26
	var row_a: HBoxContainer = HBoxContainer.new()
	row_a.position = Vector2(12.0, ROW_A_Y)
	add_child(row_a)
	_button(row_a, "Recruit", func() -> void: recruit())
	_button(row_a, "Start Wave", func() -> void: start_wave())
	for id: String in BUILDING_IDS:
		_button(row_a, BUILDING_LABELS[id], func() -> void: build_building(id))
	_button(row_a, "Save", func() -> void: save())
	_button(row_a, "Quit", func() -> void: quit_requested.emit())

	var row_b: HBoxContainer = HBoxContainer.new()
	row_b.position = Vector2(12.0, ROW_B_Y)
	add_child(row_b)
	for id: String in Abilities.DEFINITIONS:
		_button(row_b, ABILITY_LABELS[id], func() -> void: use_ability(id))
	_button(row_b, "Wall Up", func() -> void: upgrade_wall())
	_button(row_b, "Research", func() -> void: toggle_research())
	_button(row_b, "Prestige Menu", func() -> void: toggle_prestige_panel())
	_button(row_b, "Challenge", func() -> void: toggle_challenge())

	_build_prestige_panel()
	_build_ending_label()


## Prestige, relic purchases and path choice (SVTLW-73, 74). Hidden until Prestige Menu is pressed.
func _build_prestige_panel() -> void:
	var holder: PanelContainer = PanelContainer.new()
	holder.position = PRESTIGE_PANEL_POSITION
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.11, 0.15, 0.97)
	style.border_color = Color(0.45, 0.4, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	holder.add_theme_stylebox_override("panel", style)
	holder.visible = false
	_prestige_holder = holder
	add_child(holder)
	_prestige_panel = VBoxContainer.new()
	holder.add_child(_prestige_panel)
	_button(_prestige_panel, "Prestige now (resets the run)", func() -> void: prestige())
	for relic_id: String in PRESTIGE_RELICS:
		_button(_prestige_panel, "Buy relic: " + RELIC_LABELS[relic_id], func() -> void: buy_relic(relic_id))
	for path_id: String in PRESTIGE_PATHS:
		_button(_prestige_panel, "Choose path: " + path_id.capitalize(), func() -> void: choose_path(path_id))


func toggle_prestige_panel() -> void:
	if _prestige_holder != null:
		_prestige_holder.visible = not _prestige_holder.visible


func upgrade_wall() -> bool:
	return field != null and field.upgrade_wall()


func toggle_research() -> void:
	if field != null and field.research_panel != null:
		field.research_panel.visible = not field.research_panel.visible


func prestige() -> int:
	if field == null:
		return 0
	var gained: int = field.prestige_now()
	show_message("Prestige: %d relics gained" % gained)
	get_tree().reload_current_scene()
	return gained


func toggle_challenge() -> void:
	if field == null:
		return
	field.set_challenge_mode(not field.game_state.has_flag("challenge_mode"))
	show_message("Challenge mode: " + ("on" if field.game_state.has_flag("challenge_mode") else "off"))


func buy_relic(relic_id: String) -> bool:
	return field != null and field.meta.buy_relic(relic_id)


func choose_path(path_id: String) -> bool:
	return field != null and field.meta.choose_path(path_id)


## Shows this week's challenge (SVTLW-77).
func show_region_and_challenge() -> void:
	if field == null:
		return
	var challenge: ChallengeDefinition = field.meta.current_challenge(int(Time.get_unix_time_from_system()))
	if challenge != null:
		show_message("Challenge this week: " + challenge.display_name)


func _build_ending_label() -> void:
	ending_label = Label.new()
	ending_label.position = Vector2(200.0, 300.0)
	ending_label.visible = false
	add_child(ending_label)


## Uses an ability through the battlefield. False when locked, on cooldown or refused.
func use_ability(ability_id: String) -> bool:
	return field != null and field.use_ability(ability_id)


## Shows one step of the ending. Hidden when the step has no text (a fade).
func show_ending_step(step: Dictionary) -> void:
	if ending_label == null:
		return
	var text: String = str(step.get("text", ""))
	ending_label.text = text
	ending_label.visible = text != ""


## Places a new archer in the next free slot on the fortress. Returns null if refused.
func recruit() -> Archer:
	if field == null:
		return null
	var slot: int = field.units.archers.size()
	return field.recruit_archer(field.recruit_position(slot))


func start_wave() -> bool:
	return field != null and field.start_wave()


## Starts a build on the first free fixed slot through the battlefield. False when refused or no slot is free.
func build_building(building_id: String) -> bool:
	if field == null:
		return false
	return field.build(building_id, field.free_slot())


func save() -> bool:
	if field == null:
		return false
	var saved: bool = field.save_now()
	show_message("Game saved" if saved else "Save failed. Check disk space and try again.")
	return saved


func _button(parent: Node, text: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)


## The wall has fallen. Offers a way back to the menu or out of the game (game-over screen, was missing).
func show_game_over() -> void:
	if _game_over_panel != null:
		return
	_game_over_panel = PanelContainer.new()
	_game_over_panel.position = Vector2(340.0, 230.0)
	_game_over_panel.custom_minimum_size = Vector2(600.0, 240.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.04, 0.97)
	style.border_color = Color(0.7, 0.2, 0.15)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	_game_over_panel.add_theme_stylebox_override("panel", style)
	add_child(_game_over_panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_game_over_panel.add_child(column)
	var title: Label = Label.new()
	title.text = "THE WALL HAS FALLEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))
	column.add_child(title)
	var detail: Label = Label.new()
	detail.text = "Your last save is kept. Return to the menu to continue from it."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(detail)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	_button(row, "Main menu", func() -> void: get_tree().reload_current_scene())
	_button(row, "Quit", func() -> void: quit_requested.emit())
