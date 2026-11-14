## Headless tests for SimulationClock (SVTLW-25).
## Run: godot --headless --path game -s res://tests/test_simulation_clock.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_base_rate()
	_test_speed_scaling()
	_test_speed_clamp()
	_test_pause_stops_ticks()
	_test_frame_cap()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _new_clock() -> SimulationClock:
	var clock: SimulationClock = SimulationClock.new()
	return clock


func _count_ticks(clock: SimulationClock) -> Array:
	var counter: Array = [0]
	clock.tick_advanced.connect(func(_index: int) -> void: counter[0] += 1)
	return counter


func _test_base_rate() -> void:
	print("base rate")
	var clock: SimulationClock = _new_clock()
	var counter: Array = _count_ticks(clock)
	clock.advance(0.25)
	_check(counter[0] == 2, "0.25s at 1x gives 2 ticks at 10 ticks/s")
	# 0.05s is left over. 0.06s more crosses the 0.1s boundary cleanly.
	# (Exactly 0.05 would sit on the float boundary and may round below one tick.)
	clock.advance(0.06)
	_check(counter[0] == 3, "leftover time carries into the next call")
	_check(clock.tick_index == 3, "tick_index matches ticks emitted")
	clock.free()


func _test_speed_scaling() -> void:
	print("speed")
	var clock: SimulationClock = _new_clock()
	var counter: Array = _count_ticks(clock)
	clock.set_speed(3)
	clock.advance(0.1)
	_check(counter[0] == 3, "0.1s at 3x gives 3 ticks")
	clock.set_speed(2)
	counter[0] = 0
	clock.advance(0.5)
	_check(counter[0] == 10, "0.5s at 2x gives 10 ticks")
	clock.free()


func _test_speed_clamp() -> void:
	print("speed clamp")
	var clock: SimulationClock = _new_clock()
	clock.set_speed(9)
	_check(clock.speed == SimulationClock.MAX_SPEED, "speed clamps to 3")
	clock.set_speed(0)
	_check(clock.speed == SimulationClock.MIN_SPEED, "speed clamps to 1")
	clock.free()


func _test_pause_stops_ticks() -> void:
	print("pause")
	var clock: SimulationClock = _new_clock()
	var counter: Array = _count_ticks(clock)
	clock.set_paused(true)
	clock.advance(5.0)
	_check(counter[0] == 0, "no ticks while paused")
	clock.toggle_pause()
	_check(not clock.paused, "toggle resumes")
	clock.advance(0.1)
	_check(counter[0] == 1, "ticks resume after unpausing")
	clock.free()


func _test_frame_cap() -> void:
	print("frame cap")
	var clock: SimulationClock = _new_clock()
	var counter: Array = _count_ticks(clock)
	clock.set_speed(3)
	clock.advance(100.0)
	_check(counter[0] == SimulationClock.MAX_TICKS_PER_FRAME, "one huge frame is capped at %d ticks" % SimulationClock.MAX_TICKS_PER_FRAME)
	clock.free()
