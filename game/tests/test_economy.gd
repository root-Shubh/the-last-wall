## Headless tests for the wood, stone and iron economy (SVTLW-56).
## Run: godot --headless --path game -s res://tests/test_economy.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	_test_add_spend_refuse(state)
	_test_reset(state)
	_test_save_round_trip(state)
	_test_old_save_loads_zeros(state)
	_test_kill_grants_material(state)
	_test_building_wood_cost(state)
	_test_hud_labels(state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_add_spend_refuse(state: Node) -> void:
	print("add, spend and refuse")
	state.reset()
	state.add_material("wood", 5)
	_check(state.wood == 5, "wood adds")
	_check(state.spend_material("wood", 3) and state.wood == 2, "wood spends within balance")
	_check(not state.spend_material("wood", 3) and state.wood == 2, "wood spend over balance is refused and changes nothing")
	_check(not state.can_afford_material("stone", 1), "stone cannot be afforded at zero")
	state.add_material("iron", 4)
	state.add_material("stone", 0)
	state.add_material("gold", 9)
	_check(state.iron == 4 and state.stone == 0 and state.gold == 0, "zero and unknown materials are ignored")
	_check(not state.spend_material("unknown", 0) and not state.can_afford_material("gold", 0), "unknown material ids are never affordable")
	_check(state.material_amount("iron") == 4, "generic amount lookup reads the balance")


func _test_reset(state: Node) -> void:
	print("reset")
	state.add_material("wood", 7)
	state.add_material("stone", 8)
	state.add_material("iron", 9)
	state.reset()
	_check(state.wood == 0 and state.stone == 0 and state.iron == 0, "reset zeroes wood, stone and iron")


func _test_save_round_trip(state: Node) -> void:
	print("save round trip")
	state.reset()
	state.add_material("wood", 11)
	state.add_material("stone", 22)
	state.add_material("iron", 33)
	var text: String = JSON.stringify(state.to_dict())
	state.reset()
	var parsed: Dictionary = JSON.parse_string(text)
	_check(state.from_dict(parsed), "save with materials loads")
	_check(state.wood == 11 and state.stone == 22 and state.iron == 33, "wood, stone and iron survive the round trip")


func _test_old_save_loads_zeros(state: Node) -> void:
	print("old save")
	state.reset()
	state.add_material("wood", 5)
	var old_save: Dictionary = {"gold": 40, "wave": 2, "wall_health": 90, "wall_max_health": 100}
	_check(state.from_dict(old_save), "save without material fields still loads")
	_check(state.gold == 40 and state.wood == 0 and state.stone == 0 and state.iron == 0, "missing materials load as zero")


func _test_kill_grants_material(state: Node) -> void:
	print("kill reward")
	state.reset()
	var enemy_def: EnemyDefinition = load("res://resources/enemies/undead_infantry.tres").duplicate() as EnemyDefinition
	enemy_def.resource_reward_type = "stone"
	enemy_def.resource_reward_amount = 3
	var enemies: EnemyManager = EnemyManager.new()
	enemies.definitions = [enemy_def]
	root.add_child(enemies)
	var tracker: RewardTracker = RewardTracker.new()
	root.add_child(tracker)
	tracker.bind(enemies, WaveManager.new(), state)
	var gold_before: int = state.gold
	enemies.spawn("undead_infantry").take_damage(1000.0)
	_check(state.stone == 3, "kill grants the enemy's stone reward")
	_check(state.gold == gold_before + enemy_def.gold_reward, "kill still grants gold")
	tracker.free()
	enemies.free()


func _test_building_wood_cost(state: Node) -> void:
	print("building wood cost")
	state.reset()
	state.add_gold(500)
	state.add_material("wood", 10)
	var tower: BuildingDefinition = load("res://resources/buildings/tower.tres").duplicate() as BuildingDefinition
	tower.wood_cost = 25
	var manager: ConstructionManager = ConstructionManager.new()
	manager.definitions = [tower]
	manager.state = state
	root.add_child(manager)
	var gold_before: int = state.gold
	_check(not manager.start_construction("tower", 0), "start refused when wood is short")
	_check(manager.start_block_reason("tower", 0) == "not enough wood", "refusal names the missing wood")
	_check(state.gold == gold_before and state.wood == 10, "refused start spends no gold and no wood")
	state.add_material("wood", 15)
	_check(manager.start_construction("tower", 0), "start succeeds when wood is affordable")
	_check(state.wood == 0 and state.gold == gold_before - tower.build_cost, "wood and gold are both charged")
	manager.free()


func _test_hud_labels(state: Node) -> void:
	print("hud labels")
	state.reset()
	var hud: TopBar = TopBar.new()
	root.add_child(hud)
	hud.bind(state, SimulationClock.new(), WaveManager.new(), WallManager.new())
	state.add_material("wood", 12)
	state.add_material("stone", 4)
	_check(hud._wood_label.text == "Wood 12", "wood label shows the balance")
	_check(hud._stone_label.text == "Stone 4", "stone label shows the balance")
	_check(hud._iron_label.text == "Iron 0", "iron label starts at zero")
	state.spend_material("wood", 2)
	_check(hud._wood_label.text == "Wood 10", "wood label updates on spend")
	hud.free()
