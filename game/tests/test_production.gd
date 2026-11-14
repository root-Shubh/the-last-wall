## Headless tests for passive production, upgrades and save (SVTLW-55).
## Run: godot --headless --path game -s res://tests/test_production.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	_test_lumber_mill_intervals(state)
	_test_quarry_and_iron_mine(state)
	_test_exposure_is_deterministic(state)
	_test_upgrades(state)
	_test_unregistered_produces_nothing(state)
	_test_save_round_trip(state)
	_test_old_save_has_no_production(state)
	_test_hud_readout(state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


## Builds a manager whose definitions are the three production buildings, with the mill's exposure overridden.
func _manager(state: Node, mill_exposure: float = 0.0) -> ProductionManager:
	var manager: ProductionManager = ProductionManager.new()
	var mill: BuildingDefinition = load("res://resources/buildings/lumber_mill.tres").duplicate() as BuildingDefinition
	mill.exposure_chance_per_interval = mill_exposure
	manager.definitions = [mill]
	for id: String in ["quarry", "iron_mine"]:
		manager.definitions.append(load("res://resources/buildings/%s.tres" % id))
	manager.state = state
	return manager


func _run_ticks(manager: ProductionManager, count: int) -> void:
	for i: int in range(count):
		manager.on_tick(i)


func _test_lumber_mill_intervals(state: Node) -> void:
	print("lumber mill intervals")
	state.reset()
	var manager: ProductionManager = _manager(state)
	_check(manager.register("lumber_mill"), "completed lumber mill registers at level 1")
	_check(not manager.register("lumber_mill"), "registering twice is refused")
	_run_ticks(manager, 9)
	_check(state.wood == 0, "no wood before the first interval")
	manager.on_tick(9)
	_check(state.wood == 4, "lumber mill adds 4 wood at tick 10")
	for i: int in range(10, 19):
		manager.on_tick(i)
	_check(state.wood == 4, "no wood between intervals")
	manager.on_tick(19)
	_check(state.wood == 8, "second interval adds another 4 wood")
	_check(is_equal_approx(manager.production_per_tick_for("wood"), 0.4), "wood rate is 0.4 per tick")
	manager.free()


func _test_quarry_and_iron_mine(state: Node) -> void:
	print("quarry and iron mine")
	state.reset()
	var manager: ProductionManager = _manager(state)
	manager.register("quarry")
	manager.register("iron_mine")
	_run_ticks(manager, 100)
	_check(state.stone == 20, "quarry adds 2 stone per interval with no exposure")
	_check(state.iron >= 40 and state.iron <= 50, "iron mine adds its iron, less any exposure losses")
	_check(state.wood == 0, "quarry and iron mine add no wood")
	_check(is_equal_approx(manager.production_per_tick_for("iron"), 0.5), "iron rate is 0.5 per tick")
	_check(is_equal_approx(manager.production_per_tick_for("stone"), 0.2), "stone rate is 0.2 per tick")
	manager.free()


func _test_exposure_is_deterministic(state: Node) -> void:
	print("exposure")
	state.reset()
	var first: ProductionManager = _manager(state, 0.1)
	first.register("lumber_mill")
	_run_ticks(first, 500)
	var first_wood: int = state.wood
	state.reset()
	var second: ProductionManager = _manager(state, 0.1)
	second.register("lumber_mill")
	_run_ticks(second, 500)
	_check(state.wood == first_wood, "same inputs give the same wood total")
	_check(first_wood < 200 and first_wood > 150, "10% exposure loses some but not most output over 50 intervals")
	state.reset()
	var certain: ProductionManager = _manager(state, 1.0)
	certain.register("lumber_mill")
	_run_ticks(certain, 30)
	_check(state.wood == 9, "certain exposure loses one unit per interval (3 per interval over 3 intervals)")
	first.free()
	second.free()
	certain.free()


func _test_upgrades(state: Node) -> void:
	print("upgrades")
	state.reset()
	var manager: ProductionManager = _manager(state)
	_check(not manager.upgrade("lumber_mill"), "unregistered building cannot be upgraded")
	manager.register("lumber_mill")
	_check(manager.upgrade("lumber_mill") and manager.level_of("lumber_mill") == 2, "upgrade raises level to 2")
	_check(manager.output_per_interval("lumber_mill") == 6, "level 2 output is 4 x 1.5 = 6")
	_check(manager.upgrade("lumber_mill") and manager.output_per_interval("lumber_mill") == 9, "level 3 output is 9")
	_check(not manager.upgrade("lumber_mill") and manager.level_of("lumber_mill") == 3, "upgrade returns false at max level")
	manager.free()


func _test_unregistered_produces_nothing(state: Node) -> void:
	print("unregistered")
	state.reset()
	var manager: ProductionManager = _manager(state)
	_run_ticks(manager, 100)
	_check(state.wood == 0 and state.stone == 0 and state.iron == 0, "production stops for an unregistered building")
	_check(manager.production_per_tick_for("wood") == 0.0, "unregistered building has no rate")
	manager.free()


func _test_save_round_trip(state: Node) -> void:
	print("save round trip")
	state.reset()
	var manager: ProductionManager = _manager(state)
	manager.register("quarry")
	manager.upgrade("quarry")
	var text: String = JSON.stringify(state.to_dict())
	state.reset()
	_check(state.from_dict(JSON.parse_string(text)), "save with production loads")
	_check(state.production_levels == {"quarry": 2}, "production levels survive the round trip")
	manager.state = state
	manager.load_from_state()
	_check(manager.level_of("quarry") == 2, "manager reads restored levels")
	manager.free()


func _test_old_save_has_no_production(state: Node) -> void:
	print("old save")
	state.reset()
	state.production_levels["lumber_mill"] = 1
	var old_save: Dictionary = {"gold": 10, "wave": 1, "wall_health": 100, "wall_max_health": 100}
	_check(state.from_dict(old_save), "save without production field still loads")
	_check(state.production_levels.is_empty(), "missing production loads as none")


func _test_hud_readout(state: Node) -> void:
	print("hud readout")
	state.reset()
	var manager: ProductionManager = _manager(state)
	manager.register("lumber_mill")
	var hud: TopBar = TopBar.new()
	root.add_child(hud)
	hud.bind_production(manager)
	_check(hud._production_label.text == "Prod W 0.4 S 0.0 I 0.0", "HUD shows the per-tick production rates")
	manager.upgrade("lumber_mill")
	_check(hud._production_label.text == "Prod W 0.6 S 0.0 I 0.0", "HUD updates when a building is upgraded")
	hud.free()
	manager.free()
