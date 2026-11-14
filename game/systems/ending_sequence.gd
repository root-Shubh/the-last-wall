## The collapse and the real-world ending (SVTLW-84). Plays once after the final battle, then sets
## the canonical ending flag. Pure: the caller shows each line and fades the screen.
class_name EndingSequence
extends RefCounted

const FLAG_CANONICAL: String = "canonical_ending"

## Each step: text to show, style ("message", "fade", "title", "scene", "credits"), ticks to hold.
const STEPS: Array[Dictionary] = [
	{"text": "Structural integrity: failing", "style": "message", "ticks": 60},
	{"text": "Memory sectors releasing", "style": "message", "ticks": 60},
	{"text": "Overseer: this simulation is complete", "style": "message", "ticks": 90},
	{"text": "", "style": "fade", "ticks": 60},
	{"text": "SIMULATION TERMINATED", "style": "title", "ticks": 120},
	{"text": "", "style": "fade", "ticks": 60},
	{"text": "A kitchen. A friend asks if you fell asleep at the desk.", "style": "scene", "ticks": 150},
	{"text": "One minute had passed.", "style": "scene", "ticks": 120},
	{"text": "The Last Wall", "style": "credits", "ticks": 180},
]

var _index: int = -1
var _hold_remaining: int = 0
var _playing: bool = false
var _finished: bool = false


## Starts the sequence. Returns false, and plays nothing, when the ending has already been seen.
func start(already_seen: bool) -> bool:
	if already_seen or _playing or _finished:
		return false
	_playing = true
	_index = 0
	_hold_remaining = int(STEPS[0]["ticks"])
	return true


## Current step as a dictionary, or an empty dictionary when nothing is playing.
func current_step() -> Dictionary:
	if not _playing:
		return {}
	return STEPS[_index]


## Advances one tick. Returns true when the whole sequence has just finished.
func on_tick() -> bool:
	if not _playing:
		return false
	_hold_remaining -= 1
	if _hold_remaining > 0:
		return false
	_index += 1
	if _index >= STEPS.size():
		_playing = false
		_finished = true
		_index = STEPS.size() - 1
		return true
	_hold_remaining = int(STEPS[_index]["ticks"])
	return false


func is_playing() -> bool:
	return _playing


func is_finished() -> bool:
	return _finished
