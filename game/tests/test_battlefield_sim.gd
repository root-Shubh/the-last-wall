## Headless integration test: wave 1 played through the battlefield controller (SVTLW-28, SVTLW-29).
## Run: godot --headless --path game -s res://tests/test_battlefield_sim.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.add_gold(200)

	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	root.add_child(field)
	field.ensure_ready()

	_test_recruit_and_wave(field, state)
	_test_wall_visuals(field, state)
	_test_wall_destruction_ends_game(state)

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_recruit_and_wave(field: Battlefield, state: Node) -> void:
	print("wave 1 played through")
	var archer: Archer = field.recruit_archer(Vector2(200.0, 300.0))
	_check(archer != null and state.gold == 180, "archer recruited and paid for")
	_check(field.start_wave(), "wave 1 starts")

	var guard: int = 0
	while field.waves.is_running() and guard < 5000:
		field.step_ticks(1)
		guard += 1
	_check(not field.waves.is_running() and field.waves.current_wave == 1, "wave 1 completes (%d ticks)" % guard)
	_check(field.rewards.kills == 5, "all 5 infantry killed")
	_check(state.gold == 200, "gold = 180 + 5 kills x 2 + survival bonus 10")
	_check(not field.wall.is_destroyed(), "wall still standing")


func _test_wall_visuals(field: Battlefield, state: Node) -> void:
	print("wall visuals")
	state.reset()
	var wall_rect: ColorRect = field.get_node("Fortress/Wall")
	var cracks: ColorRect = field.get_node("Fortress/Wall/Cracks")
	var warning: ColorRect = field.get_node("Fortress/Wall/CriticalWarning")
	_check(not cracks.visible and not warning.visible, "intact wall shows no cracks or warning")
	state.damage_wall(30)
	_check(cracks.visible and not warning.visible, "cracked wall shows cracks only")
	state.damage_wall(50)
	_check(cracks.visible and warning.visible, "critical wall shows cracks and warning")
	_check(wall_rect.color == Battlefield.WALL_COLOURS[WallManager.DamageState.CRITICAL], "critical wall uses the critical colour")
	state.reset()
	_check(not cracks.visible and not warning.visible, "repair to full clears the visuals")


func _test_wall_destruction_ends_game(state: Node) -> void:
	print("wall destruction")
	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	state.reset()
	root.add_child(field)
	field.ensure_ready()
	var ended: Array = [0]
	field.game_over.connect(func() -> void: ended[0] += 1)
	state.damage_wall(1000)
	_check(ended[0] == 1, "game over emitted when the wall falls")
	_check(field.clock.paused, "clock paused at game over")
	field.step_ticks(10)
	_check(field.clock.tick_index == 0 or field.clock.paused, "no ticks run after game over")
