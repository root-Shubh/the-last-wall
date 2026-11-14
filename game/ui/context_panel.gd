## Contextual side panel (SVTLW-52). A strip on the right of the screen that shows one view at a time:
## a unit, an enemy, a building, or the recruitment list. It never covers the battlefield with a full-screen menu.
## Dependencies are injected through bind(). Click-to-select is not built here; callers use show_* and select_*.
class_name ContextPanel
extends CanvasLayer

const PANEL_POSITION: Vector2 = Vector2(1008.0, 48.0)
const PANEL_WIDTH: float = 260.0
const PANEL_HEIGHT: float = 620.0
## Recruit slot layout, same as BattleControls so both place units in the same spots.
const RECRUIT_START_X: float = 190.0
const RECRUIT_STEP_X: float = 30.0
const RECRUIT_Y: float = 300.0

var units: UnitManager = null
var state: Node = null
var constructions: ConstructionManager = null

var _panel: PanelContainer
var _unit_box: VBoxContainer
var _enemy_box: VBoxContainer
var _building_box: VBoxContainer
var _recruit_box: VBoxContainer
var _unit_stats: Label
var _enemy_stats: Label
var _building_stats: Label
var _recruit_gold: Label
var _mode_buttons: Dictionary = {}     # Targeting.Mode -> Button
var _recruit_buttons: Dictionary = {}  # unit_id -> Button
var _archer: Archer = null
var _enemy: Enemy = null
var _view: String = ""
var _built: bool = false


## Injects the systems the panel reads and writes. Builds the layout on first use.
func bind(unit_manager: UnitManager, game_state: Node, construction: ConstructionManager) -> void:
	build()
	units = unit_manager
	state = game_state
	constructions = construction
	if units != null:
		units.unit_recruited.connect(func(_a: Archer) -> void: _refresh_recruit())
		units.unit_lost.connect(func(_a: Archer) -> void: _refresh_recruit())
		_rebuild_recruit_buttons()
	if state != null:
		state.resources_changed.connect(func(_g: int) -> void: _refresh_recruit())
	_refresh_recruit()


func build() -> void:
	if _built:
		return
	_built = true
	layer = 12
	_panel = PanelContainer.new()
	_panel.position = PANEL_POSITION
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	add_child(_panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(PANEL_WIDTH - 16.0, 0.0)
	_panel.add_child(column)

	_unit_box = _section(column)
	_unit_stats = _text(_unit_box)
	_text(_unit_box, "Targeting")
	for mode: int in Targeting.Mode.values():
		var button: Button = Button.new()
		button.text = Targeting.mode_name(mode)
		button.toggle_mode = true
		button.pressed.connect(func() -> void: _on_mode_pressed(mode))
		_unit_box.add_child(button)
		_mode_buttons[mode] = button

	_enemy_box = _section(column)
	_enemy_stats = _text(_enemy_box)

	_building_box = _section(column)
	_building_stats = _text(_building_box)

	_recruit_box = _section(column)
	_text(_recruit_box, "Recruit")
	_recruit_gold = _text(_recruit_box)

	clear()


## Shows the unit view for one archer. Targeting buttons write through UnitManager.
func show_unit(archer: Archer) -> void:
	build()
	if archer == null or archer.definition == null:
		clear()
		return
	_archer = archer
	_view = "unit"
	_show_only(_unit_box)
	_refresh_unit()


## Shows the enemy view for one enemy: role, health, armour, speed and gold reward.
func show_enemy(enemy: Enemy) -> void:
	build()
	if enemy == null or enemy.definition == null:
		clear()
		return
	_enemy = enemy
	_view = "enemy"
	_show_only(_enemy_box)
	var data: EnemyDefinition = enemy.definition
	_enemy_stats.text = "%s\nRole: %s\nMax health: %s\nArmour: %s\nSpeed: %s\nGold reward: %d" % [
		data.display_name, data.role, data.max_health, data.armour, data.move_speed, data.gold_reward]


## Shows the building view. Attack lines appear only for defences.
func show_building(building_id: String) -> void:
	build()
	var data: BuildingDefinition = constructions.definition(building_id) if constructions != null else null
	if data == null:
		clear()
		return
	_view = "building"
	_show_only(_building_box)
	var text: String = "%s\nCost: %d gold\nBuild time: %d ticks" % [data.display_name, data.build_cost, data.build_time_ticks]
	if data.attack_damage > 0.0:
		text += "\nDamage: %s\nAttack interval: %d ticks\nRange: %s" % [
			data.attack_damage, data.attack_interval_ticks, data.attack_range]
	_building_stats.text = text


## Shows the recruitment list (one button per unit definition).
func select_recruitment() -> void:
	build()
	_view = "recruit"
	_show_only(_recruit_box)
	_refresh_recruit()


## Hides the panel and every view.
func clear() -> void:
	build()
	_view = ""
	_archer = null
	_enemy = null
	_show_only(null)


## Name of the visible view: "unit", "enemy", "building", "recruit" or "" when hidden.
func current_view() -> String:
	return _view


func is_visible_view(view: String) -> bool:
	return _view == view and _panel.visible


func unit_stats_text() -> String:
	return _unit_stats.text


func enemy_stats_text() -> String:
	return _enemy_stats.text


func building_stats_text() -> String:
	return _building_stats.text


func mode_button(mode: int) -> Button:
	return _mode_buttons.get(mode, null)


func recruit_button(unit_id: String) -> Button:
	return _recruit_buttons.get(unit_id, null)


## Recruits one unit through UnitManager.recruit in the next free slot, as BattleControls does.
## Returns the new archer, or null when refused.
func recruit_unit(unit_id: String) -> Archer:
	if units == null:
		return null
	var slot: int = units.archers.size()
	var archer: Archer = units.recruit(unit_id, Vector2(RECRUIT_START_X + RECRUIT_STEP_X * slot, RECRUIT_Y))
	_refresh_recruit()
	return archer


func _on_mode_pressed(mode: int) -> void:
	if _archer == null or units == null:
		return
	units.set_targeting_mode(mode, "", _archer)
	_refresh_unit()


func _refresh_unit() -> void:
	if _archer == null or not is_instance_valid(_archer) or _archer.definition == null:
		return
	var data: UnitDefinition = _archer.definition
	_unit_stats.text = "%s\nHealth: %s / %s\nDamage: %s\nAttack interval: %d ticks\nRange: %s\nArmour penetration: %s" % [
		data.display_name, _archer.health, data.max_health, data.base_damage,
		data.attack_interval_ticks, data.attack_range, data.armour_penetration]
	for mode: int in _mode_buttons:
		var button: Button = _mode_buttons[mode]
		button.button_pressed = mode == _archer.targeting_mode


func _refresh_recruit() -> void:
	if state != null:
		_recruit_gold.text = "Gold: %d" % state.gold
	for unit_id: String in _recruit_buttons:
		var button: Button = _recruit_buttons[unit_id]
		var reason: String = units.recruit_block_reason(unit_id) if units != null else "no unit manager"
		button.disabled = reason != ""
		button.tooltip_text = reason


func _rebuild_recruit_buttons() -> void:
	for child: Node in _recruit_box.get_children():
		if child is Button:
			child.queue_free()
	_recruit_buttons.clear()
	for definition: UnitDefinition in units.unit_definitions:
		var button: Button = Button.new()
		button.text = "%s  (%d gold, %d pop)" % [definition.display_name, definition.recruit_cost, definition.population_cost]
		button.pressed.connect(func() -> void: recruit_unit(definition.unit_id))
		_recruit_box.add_child(button)
		_recruit_buttons[definition.unit_id] = button
	_refresh_recruit()


func _show_only(box: Control) -> void:
	for section: Control in [_unit_box, _enemy_box, _building_box, _recruit_box]:
		section.visible = section == box
	_panel.visible = box != null


func _section(parent: Node) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.visible = false
	parent.add_child(box)
	return box


func _text(parent: Node, title: String = "") -> Label:
	var label: Label = Label.new()
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(PANEL_WIDTH - 24.0, 0.0)
	parent.add_child(label)
	return label
