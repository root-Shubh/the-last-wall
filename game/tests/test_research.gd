## Headless tests for the research tree data, rules, persistence and panel (SVTLW-61).
## Run: godot --headless --path game -s res://tests/test_research.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	_test_data()
	_test_prerequisites(state)
	_test_exclusive(state)
	_test_persistence(state)
	_test_panel(state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _manager(state: Node) -> ResearchManager:
	var manager: ResearchManager = ResearchManager.new()
	root.add_child(manager)
	manager.bind(state)
	return manager


func _test_data() -> void:
	print("research data")
	var manager: ResearchManager = _manager(root.get_node("GameState"))
	var counts: Dictionary = {}
	var ids: Dictionary = {}
	for data: ResearchDefinition in manager.definitions:
		ids[data.research_id] = true
		counts[data.branch] = int(counts.get(data.branch, 0)) + 1
	for branch: String in ResearchDefinition.BRANCHES:
		_check(int(counts.get(branch, 0)) >= 3, "%s has at least three nodes" % branch)
	_check(ids.size() >= 15 and counts.size() == 5, "fifteen nodes across five branches")
	var all_prereqs_exist: bool = true
	for data: ResearchDefinition in manager.definitions:
		for prerequisite: String in data.prerequisites:
			all_prereqs_exist = all_prereqs_exist and ids.has(prerequisite)
		for other: String in data.exclusive_with:
			all_prereqs_exist = all_prereqs_exist and ids.has(other)
	_check(all_prereqs_exist, "every prerequisite and exclusion id exists")
	manager.free()


func _test_prerequisites(state: Node) -> void:
	print("prerequisites")
	state.reset()
	var manager: ResearchManager = _manager(state)
	manager.add_points(100)
	_check(manager.can_research("mil_armour_piercing") == "requires mil_sharpened_arrows", "unmet prerequisite gives a reason")
	_check(not manager.research("mil_armour_piercing"), "node with unmet prerequisites is refused")
	_check(manager.research_points == 100 and not manager.is_researched("mil_armour_piercing"), "refusal spends nothing")
	_check(manager.research("mil_sharpened_arrows") and manager.research_points == 90, "met prerequisites: researched and charged 10")
	_check(manager.research("mil_armour_piercing") and manager.research_points == 65, "next node charged 25")
	manager.free()


func _test_exclusive(state: Node) -> void:
	print("exclusive pairs")
	state.reset()
	var manager: ResearchManager = _manager(state)
	manager.add_points(50)
	_check(manager.research("mil_sharpened_arrows"), "first of the pair is researched")
	_check(manager.can_research("mil_volley_drill").begins_with("exclusive with"), "second of the pair gives an exclusive reason")
	_check(not manager.research("mil_volley_drill") and manager.research_points == 40, "second of the pair is refused and spends nothing")
	manager.free()


func _test_persistence(state: Node) -> void:
	print("persistence")
	state.reset()
	var manager: ResearchManager = _manager(state)
	manager.add_points(100)
	manager.research("mil_sharpened_arrows")
	var data: Dictionary = state.to_dict()
	_check(data["research"]["points"] == 90, "to_dict stores research points")
	state.reset()
	_check(state.from_dict(data), "saved data loads")
	var reloaded: ResearchManager = _manager(state)
	_check(reloaded.research_points == 90 and reloaded.is_researched("mil_sharpened_arrows"), "points and researched ids survive a save and load")
	var old_save: Dictionary = data.duplicate()
	old_save.erase("research")
	state.reset()
	_check(state.from_dict(old_save), "old save without research still loads")
	_check(state.research.get("points", -1) == 0, "old save loads with zero research points")
	reloaded.bind(state)
	_check(reloaded.research_points == 0 and not reloaded.is_researched("mil_sharpened_arrows"), "manager reads zero from an old save")
	reloaded.free()
	manager.free()


func _test_panel(state: Node) -> void:
	print("research panel")
	state.reset()
	var manager: ResearchManager = _manager(state)
	var panel: ResearchPanel = ResearchPanel.new()
	root.add_child(panel)
	panel.bind(manager)
	var button: Button = panel.button_for("mil_elite_guard")
	_check(button != null and button.disabled, "refused node button is disabled")
	_check(button != null and button.tooltip_text == "requires mil_armour_piercing", "disabled button shows the reason in its tooltip")
	manager.add_points(100)
	manager.research("mil_sharpened_arrows")
	button = panel.button_for("mil_armour_piercing")
	_check(button != null and not button.disabled, "affordable node with met prerequisites is enabled")
	button.pressed.emit()
	_check(manager.is_researched("mil_armour_piercing"), "pressing a button calls research()")
	_check(not panel.button_for("mil_elite_guard").disabled, "panel enables the next node once its prerequisite is researched")
	panel.free()
	manager.free()
