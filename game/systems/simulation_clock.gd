## Fixed-step simulation clock (SVTLW-25).
## Combat and waves run on tick_advanced, not on frame time, so pause and speed
## changes never alter the outcome of a given tick sequence.
## Pause stops ticks. Speed scales how many ticks run per real second (1x, 2x, 3x).
class_name SimulationClock
extends Node

signal tick_advanced(tick_index: int)
signal speed_changed(speed: int)
signal paused_changed(paused: bool)

const TICKS_PER_SECOND: float = 10.0
const MIN_SPEED: int = 1
const MAX_SPEED: int = 3
## Caps ticks per frame so one long frame (window drag, load stall) cannot cause a burst.
const MAX_TICKS_PER_FRAME: int = 30

var tick_index: int = 0
var speed: int = MIN_SPEED
var paused: bool = false
var _accumulator: float = 0.0


func _process(delta: float) -> void:
	advance(delta)


## Converts real time into whole ticks. Public so tests can drive the clock without a frame loop.
func advance(delta: float) -> void:
	if paused or delta <= 0.0:
		return
	var step: float = 1.0 / TICKS_PER_SECOND
	_accumulator += delta * float(speed)

	var ticks_this_frame: int = 0
	while _accumulator >= step:
		if ticks_this_frame >= MAX_TICKS_PER_FRAME:
			_accumulator = 0.0
			break
		_accumulator -= step
		tick_index += 1
		ticks_this_frame += 1
		tick_advanced.emit(tick_index)


func set_speed(value: int) -> void:
	var clamped: int = clampi(value, MIN_SPEED, MAX_SPEED)
	if clamped == speed:
		return
	speed = clamped
	speed_changed.emit(speed)


func set_paused(value: bool) -> void:
	if value == paused:
		return
	paused = value
	paused_changed.emit(paused)


func toggle_pause() -> void:
	set_paused(not paused)


func reset() -> void:
	tick_index = 0
	_accumulator = 0.0
