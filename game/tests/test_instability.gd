## Headless tests for simulation instability: milestones, levels, effects, clamping and save data (SVTLW-69).
## Run: godot --headless --path game -s res://tests/test_instability.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_milestones()
	_test_levels()
	_test_effects()
	_test_clamp()
	_test_save()
	_test_malformed()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _at(amount: float) -> SimulationInstability:
	var instability: SimulationInstability = SimulationInstability.new()
	instability.add_amount(amount)
	return instability


func _test_milestones() -> void:
	print("milestones")
	var instability: SimulationInstability = SimulationInstability.new()
	instability.add_milestone("large_kill")
	_check(instability.value == SimulationInstability.MILESTONE_AMOUNTS["large_kill"], "a milestone raises the value by its fixed amount")
	var before: float = instability.value
	instability.add_milestone("not_a_milestone")
	instability.add_milestone(42)
	_check(instability.value == before, "unknown kinds and non-strings change nothing")
	instability.add_milestone("forbidden_tech")
	_check(instability.value > before, "every milestone raises the value")


func _test_levels() -> void:
	print("levels")
	_check(_at(0.0).level() == 0, "zero is calm")
	_check(_at(24.9).level() == 0, "24.9 is still calm")
	_check(_at(25.0).level() == 1, "25 reaches level 1")
	_check(_at(49.99).level() == 1, "49.99 stays at level 1")
	_check(_at(50.0).level() == 2, "50 reaches level 2")
	_check(_at(75.0).level() == 3, "75 reaches level 3")
	_check(_at(99.5).level() == 3, "99.5 stays at level 3")
	_check(_at(100.0).level() == 4, "100 reaches level 4")


func _test_effects() -> void:
	print("effects")
	var calm: Dictionary = SimulationInstability.effects_for_level(0)
	_check(not calm["ui_glitch"] and not calm["enemy_distortion"] and not calm["message_corruption"], "calm has no cosmetic effects")
	_check(SimulationInstability.effects_for_level(1)["ui_glitch"], "level 1 glitches the UI")
	_check(not SimulationInstability.effects_for_level(1)["enemy_distortion"], "level 1 does not distort enemies")
	_check(SimulationInstability.effects_for_level(2)["enemy_distortion"], "level 2 distorts enemies")
	_check(not SimulationInstability.effects_for_level(2)["message_corruption"], "level 2 does not corrupt messages")
	_check(SimulationInstability.effects_for_level(3)["message_corruption"], "level 3 corrupts messages")
	_check(not SimulationInstability.effects_for_level(3)["unlock_collapse"], "level 3 does not unlock collapse")
	_check(SimulationInstability.effects_for_level(4)["unlock_collapse"], "level 4 unlocks collapse")
	_check(SimulationInstability.effects_for_level(-3)["level"] == 0, "negative levels clamp to 0")
	_check(SimulationInstability.effects_for_level(9)["level"] == 4, "levels above 4 clamp to 4")
	_check(SimulationInstability.effects_for_level("bad")["level"] == 0, "non-numeric levels act as 0")
	_check(_at(80.0).current_effects()["message_corruption"], "current_effects follows the current level")


func _test_clamp() -> void:
	print("clamp")
	var instability: SimulationInstability = _at(150.0)
	_check(instability.value == 100.0 and instability.level() == 4, "value clamps at 100")
	instability.add_amount(50.0)
	_check(instability.value == 100.0, "further raises stay at 100")
	instability.add_amount(-20.0)
	instability.add_amount(NAN)
	instability.add_amount(INF)
	instability.add_amount("lots")
	_check(instability.value == 100.0, "negative, NaN, inf and text amounts are ignored")
	instability.reset()
	_check(instability.value == 0.0 and instability.level() == 0, "reset returns to calm")


func _test_save() -> void:
	print("save")
	var original: SimulationInstability = _at(61.5)
	var restored: SimulationInstability = SimulationInstability.new()
	_check(restored.from_dict(original.to_dict()) and restored.value == 61.5, "to_dict and from_dict round trip the value")
	var parsed: Variant = JSON.parse_string(JSON.stringify(original.to_dict()))
	_check(restored.from_dict(parsed) and restored.level() == 2, "JSON text round trip keeps the level")

	var state: Node = root.get_node("GameState")
	state.reset()
	state.instability = 33.25
	var data: Dictionary = state.to_dict()
	state.reset()
	_check(state.from_dict(data) and state.instability == 33.25, "GameState saves and loads instability")
	_check(state.from_dict(_without_instability(data)) and state.instability == 0.0, "saves without instability load as 0")
	state.reset()


func _test_malformed() -> void:
	print("malformed")
	var instability: SimulationInstability = SimulationInstability.new()
	instability.value = 40.0
	_check(instability.from_dict({"value": "lots"}) and instability.value == 0.0, "text value loads as 0")
	_check(instability.from_dict({"value": NAN}) and instability.value == 0.0, "NaN value loads as 0")
	_check(instability.from_dict({"value": -4}) and instability.value == 0.0, "negative value loads as 0")
	_check(instability.from_dict({"value": 500}) and instability.value == 100.0, "oversized value clamps to 100")
	_check(not instability.from_dict("garbage") and instability.value == 0.0, "non-dictionary loads as 0 and reports false")
	_check(instability.from_dict({}) and instability.value == 0.0, "missing value loads as 0")
	var state: Node = root.get_node("GameState")
	var data: Dictionary = state.to_dict()
	data["instability"] = "bad"
	_check(state.from_dict(data) and state.instability == 0.0, "GameState drops a malformed instability field")
	state.reset()


func _without_instability(data: Dictionary) -> Dictionary:
	var copy: Dictionary = data.duplicate()
	copy.erase("instability")
	return copy
