## Headless tests for construction costs, slots and progress (SVTLW-53).
## Run: godot --headless --path game -s res://tests/test_construction.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	_test_start_and_cost(state)
	_test_refusals(state)
	_test_progress_and_completion(state)
	_test_signals_and_queries(state)
	_test_parallel_builds(state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _manager(state: Node) -> ConstructionManager:
	var manager: ConstructionManager = ConstructionManager.new()
	for id: String in ["tower", "barracks"]:
		manager.definitions.append(load("res://resources/buildings/%s.tres" % id))
	manager.state = state
	manager._rebuild_index()
	root.add_child(manager)
	return manager


func _run_ticks(manager: ConstructionManager, count: int) -> void:
	for i: int in range(count):
		manager.on_tick(i)


func _test_start_and_cost(state: Node) -> void:
	print("start and cost")
	state.reset()
	state.add_gold(200)
	var manager: ConstructionManager = _manager(state)
	_check(manager.start_construction("tower", 0), "start with enough gold succeeds")
	_check(state.gold == 140, "tower costs 60 gold from 200")
	manager.free()


func _test_refusals(state: Node) -> void:
	print("refusals")
	state.reset()
	state.add_gold(70)
	var manager: ConstructionManager = _manager(state)
	_check(not manager.start_construction("barracks", 0) and state.gold == 70, "insufficient gold refuses and spends nothing")
	_check(manager.start_block_reason("barracks", 0) == "not enough gold", "refusal reason names the gold shortfall")
	state.add_gold(100)
	_check(manager.start_construction("tower", 1) and state.gold == 110, "tower starts on slot 1")
	_check(not manager.start_construction("barracks", 1) and state.gold == 110, "occupied slot refuses and spends nothing")
	_check(manager.start_block_reason("barracks", 1) == "slot occupied", "refusal reason names the occupied slot")
	_check(not manager.start_construction("tower", 2), "same building cannot be started twice")
	manager.free()


func _test_progress_and_completion(state: Node) -> void:
	print("progress and completion")
	state.reset()
	state.add_gold(500)
	var manager: ConstructionManager = _manager(state)
	manager.start_construction("tower", 0)
	_run_ticks(manager, 49)
	_check(not manager.is_built("tower") and manager.progress_of("tower") == 49, "after 49 of 50 ticks the tower is not built")
	manager.on_tick(49)
	_check(manager.is_built("tower") and manager.progress_of("tower") == 0, "tower completes exactly at tick 50")
	_check(manager.active.is_empty(), "completed build leaves the active list")
	manager.free()


func _test_signals_and_queries(state: Node) -> void:
	print("signals and queries")
	state.reset()
	state.add_gold(500)
	var manager: ConstructionManager = _manager(state)
	var started: Array = []
	var progress: Array = [0]
	var completed: Array = []
	manager.construction_started.connect(func(id: String, slot: int) -> void: started.append([id, slot]))
	manager.construction_progress.connect(func(_id: String, _slot: int, _p: int, _t: int) -> void: progress[0] += 1)
	manager.construction_completed.connect(func(id: String, slot: int) -> void: completed.append([id, slot]))
	manager.start_construction("barracks", 3)
	_check(started == [["barracks", 3]], "construction_started carries id and slot")
	_run_ticks(manager, 80)
	_check(progress[0] == 80, "construction_progress fires once per tick")
	_check(completed == [["barracks", 3]], "construction_completed fires once with id and slot")
	manager.on_tick(80)
	_check(completed.size() == 1, "completed signal does not fire again after completion")
	_check(manager.is_built("barracks") and manager.slot_of("barracks") == 3, "is_built and slot_of are correct after completion")
	_check(manager.slot_of("tower") == -1 and not manager.is_built("tower"), "unbuilt building reports no slot")
	manager.free()


func _test_parallel_builds(state: Node) -> void:
	print("parallel builds")
	state.reset()
	state.add_gold(500)
	var manager: ConstructionManager = _manager(state)
	_check(manager.start_construction("tower", 0), "first build starts on slot 0")
	_check(manager.start_construction("barracks", 1), "second build starts on slot 1 while the first runs")
	_run_ticks(manager, 50)
	_check(manager.is_built("tower") and not manager.is_built("barracks"), "tower finishes first, barracks still building")
	_run_ticks(manager, 30)
	_check(manager.built_count() == 2 and manager.slot_of("tower") == 0 and manager.slot_of("barracks") == 1, "both finish on their own slots")
	manager.free()
