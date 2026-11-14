## Plays dialogue sequences (SVTLW-40). Timed lines advance from update(delta). Lines with
## choices wait for pick_choice(). skip() finishes the sequence at once.
## The UI layer listens to line_shown and draws the box; this node holds no drawing code.
class_name DialogueManager
extends Node

signal line_shown(speaker: String, text: String, choices: PackedStringArray)
signal sequence_finished(sequence_id: String)
## Choice index picked for each choice line, keyed by line index. Used for story flags.
var choices_made: Dictionary = {}

var _sequence: DialogueSequence = null
var _index: int = -1
var _timer: float = 0.0
var _waiting_for_choice: bool = false


func is_playing() -> bool:
	return _sequence != null


func play(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.lines.is_empty():
		return
	_sequence = sequence
	_index = -1
	choices_made.clear()
	_advance_line()


## Moves to the next line. Ignored while waiting for a choice.
func advance() -> void:
	if not is_playing() or _waiting_for_choice:
		return
	_advance_line()


## Records the player's pick and continues. Returns false if no choice was waiting.
func pick_choice(choice_index: int) -> bool:
	if not _waiting_for_choice:
		return false
	var line: DialogueLine = _sequence.lines[_index]
	if choice_index < 0 or choice_index >= line.choices.size():
		return false
	choices_made[_index] = choice_index
	_waiting_for_choice = false
	_advance_line()
	return true


## Ends the current sequence immediately.
func skip() -> void:
	if not is_playing():
		return
	_finish()


## Counts down timed lines. Call every frame with the frame time.
func update(delta: float) -> void:
	if not is_playing() or _waiting_for_choice:
		return
	var line: DialogueLine = _sequence.lines[_index]
	if line.duration_seconds <= 0.0:
		return
	_timer -= delta
	if _timer <= 0.0:
		_advance_line()


func _process(delta: float) -> void:
	update(delta)


func _advance_line() -> void:
	_index += 1
	if _index >= _sequence.lines.size():
		_finish()
		return
	var line: DialogueLine = _sequence.lines[_index]
	_timer = line.duration_seconds
	_waiting_for_choice = line.choices.size() > 0
	line_shown.emit(line.speaker, line.text, line.choices)


func _finish() -> void:
	var finished_id: String = _sequence.sequence_id
	_sequence = null
	_index = -1
	_waiting_for_choice = false
	sequence_finished.emit(finished_id)
