## Headless tests for WallManager: thresholds, armour, repair and destruction (SVTLW-29, SVTLW-30).
## Run: godot --headless --path game -s res://tests/test_wall.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_thresholds()
	_test_armour_and_state_signal()
	_test_repair_and_destruction()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _state() -> Node:
	return root.get_node("GameState")


func _test_thresholds() -> void:
	print("damage state thresholds")
	_check(WallManager.state_for(100, 100) == WallManager.DamageState.INTACT, "full health is intact")
	_check(WallManager.state_for(76, 100) == WallManager.DamageState.INTACT, "above 75 percent is intact")
	_check(WallManager.state_for(75, 100) == WallManager.DamageState.CRACKED, "75 percent cracks")
	_check(WallManager.state_for(50, 100) == WallManager.DamageState.DAMAGED, "50 percent is damaged")
	_check(WallManager.state_for(25, 100) == WallManager.DamageState.CRITICAL, "25 percent is critical")
	_check(WallManager.state_for(1, 100) == WallManager.DamageState.CRITICAL, "1 hp is still critical")
	_check(WallManager.state_for(0, 100) == WallManager.DamageState.DESTROYED, "zero health is destroyed")


func _test_armour_and_state_signal() -> void:
	print("armour and state signal")
	var state: Node = _state()
	state.reset()
	var wall: WallManager = WallManager.new()
	wall.armour = 4.0
	wall.bind(state)
	var changes: Array = []
	wall.damage_state_changed.connect(func(s: WallManager.DamageState) -> void: changes.append(s))
	wall.attack(14.0)
	_check(state.wall_health == 90, "attack is reduced by armour (14 - 4 = 10)")
	_check(wall.current_state() == WallManager.DamageState.INTACT and changes.is_empty(), "no state change above 75 percent")
	wall.attack(20.0)
	_check(state.wall_health == 74 and changes == [WallManager.DamageState.CRACKED], "crossing 75 percent emits CRACKED once")
	wall.free()


func _test_repair_and_destruction() -> void:
	print("repair and destruction")
	var state: Node = _state()
	state.reset()
	var wall: WallManager = WallManager.new()
	wall.armour = 0.0
	wall.repair_per_second = 10.0
	wall.bind(state)
	var destroyed: Array = [0]
	wall.wall_destroyed.connect(func() -> void: destroyed[0] += 1)
	state.damage_wall(50)
	# 10 hp per second is 1 hp per tick. Ten ticks is one real second.
	for tick: int in range(10):
		wall.on_tick(tick)
	_check(state.wall_health == 60, "repair restores health per tick")
	state.damage_wall(1000)
	wall.attack(5.0)
	_check(destroyed[0] == 1 and wall.is_destroyed(), "wall destroyed emitted once")
	wall.on_tick(99)
	_check(state.wall_health == 0, "destroyed wall does not repair")
	wall.free()
