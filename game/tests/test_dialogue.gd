## Headless tests for DialogueManager (SVTLW-40).
## Run: godot --headless --path game -s res://tests/test_dialogue.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_plays_in_order()
	_test_timed_line()
	_test_choice_blocks_until_picked()
	_test_skip()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _line(speaker: String, text: String, duration: float = 0.0, choices: PackedStringArray = PackedStringArray()) -> DialogueLine:
	var line: DialogueLine = DialogueLine.new()
	line.speaker = speaker
	line.text = text
	line.duration_seconds = duration
	line.choices = choices
	return line


func _sequence(id: String, lines: Array[DialogueLine]) -> DialogueSequence:
	var sequence: DialogueSequence = DialogueSequence.new()
	sequence.sequence_id = id
	sequence.lines = lines
	return sequence


func _test_plays_in_order() -> void:
	print("plays in order")
	var manager: DialogueManager = DialogueManager.new()
	var shown: Array = []
	var finished: Array = []
	manager.line_shown.connect(func(speaker: String, text: String, _c: PackedStringArray) -> void: shown.append([speaker, text]))
	manager.sequence_finished.connect(func(id: String) -> void: finished.append(id))
	var lines: Array[DialogueLine] = [_line("Friend", "Try this."), _line("Player", "What is it?")]
	manager.play(_sequence("intro", lines))
	_check(shown.size() == 1 and shown[0] == ["Friend", "Try this."], "first line shows on play")
	manager.advance()
	_check(shown.size() == 2 and shown[1] == ["Player", "What is it?"], "advance shows the next line")
	manager.advance()
	_check(finished == ["intro"] and not manager.is_playing(), "finishing the last line ends the sequence")
	manager.free()


func _test_timed_line() -> void:
	print("timed line")
	var manager: DialogueManager = DialogueManager.new()
	var shown: Array = [0]
	manager.line_shown.connect(func(_s: String, _t: String, _c: PackedStringArray) -> void: shown[0] += 1)
	var lines: Array[DialogueLine] = [_line("System", "SIMULATION ERROR", 2.0), _line("System", "WELCOME")]
	manager.play(_sequence("error", lines))
	manager.update(1.0)
	_check(shown[0] == 1, "timed line holds before its duration")
	manager.update(1.5)
	_check(shown[0] == 2, "timed line advances after its duration")
	manager.free()


func _test_choice_blocks_until_picked() -> void:
	print("choices")
	var manager: DialogueManager = DialogueManager.new()
	var finished: Array = [0]
	manager.sequence_finished.connect(func(_id: String) -> void: finished[0] += 1)
	var options: PackedStringArray = PackedStringArray(["Stay calm", "Panic"])
	var lines: Array[DialogueLine] = [_line("Player", "What now?", 0.0, options), _line("Player", "Right.")]
	manager.play(_sequence("choice", lines))
	manager.update(999.0)
	manager.advance()
	_check(manager.is_playing() and finished[0] == 0, "a choice line ignores timers and advance until picked")
	_check(not manager.pick_choice(5), "an out-of-range choice is refused")
	_check(manager.pick_choice(1) and manager.choices_made.get(0) == 1, "picking a choice records it")
	_check(manager.is_playing() and finished[0] == 0, "picking moves to the next line, sequence still running")
	manager.advance()
	_check(finished[0] == 1 and not manager.is_playing(), "advancing past the last line ends the sequence")
	manager.free()


func _test_skip() -> void:
	print("skip")
	var manager: DialogueManager = DialogueManager.new()
	var finished: Array = [0]
	manager.sequence_finished.connect(func(_id: String) -> void: finished[0] += 1)
	var lines: Array[DialogueLine] = [_line("A", "one"), _line("B", "two"), _line("C", "three")]
	manager.play(_sequence("long", lines))
	manager.skip()
	_check(finished[0] == 1 and not manager.is_playing(), "skip ends the sequence at once")
	manager.free()
