## Headless tests for the contextual side panel and recruitment list (SVTLW-52).
## Run: godot --headless --path game -s res://tests/test_context_panel.gd
extends SceneTree

var _failures: int = 0
var _state: Node
var _units: UnitManager
var _constructions: ConstructionManager
var _panel: ContextPanel


func _initialize() -> void:
	_state = load("res://autoload/game_state.gd").new()
	root.add_child(_state)
	_state.reset()
	_state.add_gold(1000)

	_units = UnitManager.new()
	_units.unit_definitions = [
		load("res://resources/units/archer.tres"),
		load("res://resources/units/spearman.tres"),
	]
	_units.state = _state
	root.add_child(_units)

	_constructions = ConstructionManager.new()
	_constructions.definitions = [load("res://resources/buildings/tower.tres")]

	_panel = ContextPanel.new()
	root.add_child(_panel)
	_panel.bind(_units, _state, _constructions)

	_test_unit_view()
	_test_enemy_view()
	_test_building_view()
	_test_recruitment()
	_test_clear()

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_unit_view() -> void:
	print("unit view")
	var data: UnitDefinition = load("res://resources/units/archer.tres")
	var archer: Archer = _units.recruit("archer", Vector2(200.0, 300.0))
	_check(archer != null, "archer recruited for the view")
	_panel.show_unit(archer)
	_check(_panel.current_view() == "unit" and _panel.is_visible_view("unit"), "unit view is shown")
	var text: String = _panel.unit_stats_text()
	_check(text.contains(data.display_name), "unit view shows the name")
	_check(text.contains("Damage: %s" % data.base_damage), "unit view shows damage")
	_check(text.contains("Attack interval: %d ticks" % data.attack_interval_ticks), "unit view shows interval")
	_check(text.contains("Range: %s" % data.attack_range), "unit view shows range")
	_check(text.contains("Armour penetration: %s" % data.armour_penetration), "unit view shows armour penetration")
	_check(text.contains("Health: %s / %s" % [archer.health, data.max_health]), "unit view shows health")

	_panel.mode_button(Targeting.Mode.STRONGEST).pressed.emit()
	_check(archer.targeting_mode == Targeting.Mode.STRONGEST, "targeting button sets the archer's mode")
	_check(_panel.mode_button(Targeting.Mode.STRONGEST).button_pressed, "chosen mode button stays pressed")
	_check(not _panel.mode_button(Targeting.Mode.CLOSEST).button_pressed, "other mode buttons are released")
	_panel.mode_button(Targeting.Mode.WEAKEST).pressed.emit()
	_check(archer.targeting_mode == Targeting.Mode.WEAKEST, "a second targeting button changes the mode again")


func _test_enemy_view() -> void:
	print("enemy view")
	var data: EnemyDefinition = load("res://resources/enemies/undead_infantry.tres")
	var enemy: Enemy = Enemy.new()
	enemy.setup(data, 0.0, 100.0)
	_panel.show_enemy(enemy)
	_check(_panel.current_view() == "enemy", "enemy view is shown")
	var text: String = _panel.enemy_stats_text()
	_check(text.contains(data.display_name), "enemy view shows the name")
	_check(text.contains("Role: %s" % data.role), "enemy view shows the role")
	_check(text.contains("Gold reward: %d" % data.gold_reward), "enemy view shows the gold reward")
	_check(text.contains("Max health: %s" % data.max_health), "enemy view shows max health")
	enemy.free()


func _test_building_view() -> void:
	print("building view")
	var data: BuildingDefinition = load("res://resources/buildings/tower.tres")
	_panel.show_building(data.building_id)
	_check(_panel.current_view() == "building", "building view is shown")
	var text: String = _panel.building_stats_text()
	_check(text.contains("Cost: %d gold" % data.build_cost), "building view shows the cost")
	_check(text.contains("Build time: %d ticks" % data.build_time_ticks), "building view shows the build time")
	_check(text.contains("Damage: %s" % data.attack_damage), "defence building shows its attack stats")
	_panel.show_building("no_such_building")
	_check(_panel.current_view() == "", "unknown building id hides the panel")


func _test_recruitment() -> void:
	print("recruitment")
	var archer_data: UnitDefinition = load("res://resources/units/archer.tres")
	_panel.select_recruitment()
	_check(_panel.current_view() == "recruit", "recruitment view is shown")
	var button: Button = _panel.recruit_button("archer")
	_check(button != null and button.text.contains(archer_data.display_name), "one button per unit definition, labelled with name")
	_check(button.text.contains("%d gold" % archer_data.recruit_cost), "button shows the recruit cost")

	_state.reset()
	_panel.select_recruitment()
	_check(_panel.recruit_button("archer").disabled, "no gold disables recruiting")
	_check(_panel.recruit_button("archer").tooltip_text == "not enough gold", "disabled button gives the gold reason")

	_state.add_gold(1000)
	_panel.select_recruitment()
	_check(not _panel.recruit_button("archer").disabled, "enough gold enables recruiting")

	var population: int = _units.population_used()
	var saved_cap: int = _units.population_cap
	_units.population_cap = population
	_panel.select_recruitment()
	_check(_panel.recruit_button("archer").disabled, "no population room disables recruiting")
	_check(_panel.recruit_button("archer").tooltip_text == "no population slot free", "disabled button gives the population reason")
	_units.population_cap = saved_cap
	_panel.select_recruitment()

	var gold_before: int = _state.gold
	var count_before: int = _units.archers.size()
	_panel.recruit_button("archer").pressed.emit()
	_check(_units.archers.size() == count_before + 1, "pressing recruit adds one unit")
	_check(_state.gold == gold_before - archer_data.recruit_cost, "pressing recruit charges the recruit cost")


func _test_clear() -> void:
	print("clear")
	_panel.clear()
	_check(_panel.current_view() == "", "clear leaves no view")
	_check(not _panel.is_visible_view("unit") and not _panel.is_visible_view("enemy"), "clear hides unit and enemy views")
	_check(not _panel.is_visible_view("building") and not _panel.is_visible_view("recruit"), "clear hides building and recruit views")
