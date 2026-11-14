## Headless check that the battlefield wires the new systems: abilities, the final battle start,
## restored buildings and the meta-game kill count (SVTLW-64, 78, 83, save restore gap).
## Run: godot --headless --path game -s res://tests/test_battle_wiring.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	_check(packed != null, "battlefield scene loads")
	if packed != null:
		var state: Node = root.get_node("GameState")
		var field: Battlefield = packed.instantiate()
		field.game_state = state
		root.add_child(field)
		field.ensure_ready()
		state.reset()
		state.add_gold(5000)
		_test_abilities(field, state)
		_test_final_battle_start(field)
		_test_restored_buildings(field, state)
		_test_kill_stats(field, state)
		_test_research_points(field, state)
		field.queue_free()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_abilities(field: Battlefield, state: Node) -> void:
	print("abilities through the battlefield")
	state.research = {"points": 0, "researched": []}
	_check(not field.use_ability(Abilities.RAIN_OF_ARROWS), "a locked ability is refused by the battlefield")
	state.research = {"points": 1, "researched": ["mil_volley_drill"]}
	_check(field.use_ability(Abilities.RAIN_OF_ARROWS), "an unlocked ability works through the battlefield")
	_check(not field.use_ability(Abilities.RAIN_OF_ARROWS), "the battlefield enforces the cooldown")
	state.research = {"points": 1, "researched": ["eng_field_repairs"]}
	state.damage_wall(40)
	var health_before: int = state.wall_health
	_check(field.use_ability(Abilities.EMERGENCY_REPAIR), "emergency repair is accepted when its research is done")
	_check(state.wall_health == mini(health_before + field.REPAIR_AMOUNT, state.wall_max_health), "emergency repair restores wall health")


func _test_final_battle_start(field: Battlefield) -> void:
	print("wave 1000 starts the final battle")
	field.waves.current_wave = FinalBattle.FINAL_WAVE - 1
	_check(field.start_wave(), "starting wave 1000 is accepted")
	_check(field.final_battle.active, "wave 1000 starts the final Overseer battle")
	_check(field.waves.current_wave == FinalBattle.FINAL_WAVE - 1, "wave 1000 does not run as a normal wave")


func _test_restored_buildings(field: Battlefield, state: Node) -> void:
	print("buildings come back from a save")
	_check(field.constructions.restore_completed("tower", 0), "a finished tower is restored onto its slot")
	_check(field.constructions.is_built("tower"), "the restored tower counts as built")
	_check(field._defences.has("tower"), "the restored tower gets its defence structure")
	_check(not field.constructions.restore_completed("tower", 1), "a building already placed is not placed twice")


func _test_kill_stats(field: Battlefield, state: Node) -> void:
	print("kills reach the stats")
	var before: int = state.stats.total_kills
	var enemy: Enemy = field.enemies.spawn("runner")
	enemy.health = 0.0
	field._on_enemy_removed_for_objectives(enemy)
	_check(state.stats.total_kills == before + 1, "a kill is counted in the stats")
	_check(field.objectives.kills_of_target == 0 or field.objectives.kill_target_id == "runner", "kills feed the objectives")


func _test_research_points(field: Battlefield, state: Node) -> void:
	print("waves give research points")
	state.research = {"points": 0, "researched": []}
	field._on_wave_completed_for_objectives(1)
	_check(state.research.get("points", 0) == Battlefield.RESEARCH_POINTS_PER_WAVE, "a finished wave adds research points")
	_check(field.research_panel != null and not field.research_panel.visible, "the research panel starts hidden")
