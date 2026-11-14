## Headless tests for Overseer messages and story acts (SVTLW-67, SVTLW-68).
## Run: godot --headless --path game -s res://tests/test_narrative.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_messages_fire_once()
	_test_no_fire_below_threshold()
	_test_overseer_files_load()
	_test_act_2_unlocks_and_saves()
	_test_act_3_requires_act_2()
	_test_act_effects_and_dialogue()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


## A fresh GameState instance keeps tests isolated from the autoload.
func _state() -> Node:
	return load("res://autoload/game_state.gd").new()


func _message(id: String, text: String, kind: String, value: int) -> OverseerMessage:
	var message: OverseerMessage = OverseerMessage.new()
	message.message_id = id
	message.text = text
	message.trigger_kind = kind
	message.trigger_value = value
	return message


func _test_messages_fire_once() -> void:
	print("messages fire exactly once")
	var state: Node = _state()
	var list: Array[OverseerMessage] = [_message("m_wave", "Wave ten.", "wave_reached", 10)]
	var messenger: OverseerMessenger = OverseerMessenger.new(state, list)
	var signalled: Array = []
	messenger.message_ready.connect(func(text: String) -> void: signalled.append(text))
	var stats: Dictionary = {"wave": 12}
	var first: Array[String] = messenger.check(stats)
	var second: Array[String] = messenger.check(stats)
	var third: Array[String] = messenger.check({"wave": 40})
	_check(first.size() == 1 and first[0] == "Wave ten.", "met trigger returns its text once")
	_check(second.is_empty() and third.is_empty(), "repeated checks return nothing")
	_check(signalled.size() == 1, "message_ready emits once")
	_check(messenger.has_fired("m_wave") and state.has_flag("overseer_fired_m_wave"), "fired id is stored as a flag")
	state.free()


func _test_no_fire_below_threshold() -> void:
	print("messages wait for their threshold")
	var state: Node = _state()
	var list: Array[OverseerMessage] = [
		_message("m_deaths", "Ten lost.", "deaths", 10),
		_message("m_damage", "Big hits.", "damage_dealt_total", 1000),
		_message("m_bad", "Unknown.", "nonsense", 0),
	]
	var messenger: OverseerMessenger = OverseerMessenger.new(state, list)
	_check(messenger.check({"deaths": 9, "total_damage": 999}).is_empty(), "nothing fires below thresholds")
	_check(messenger.check({"deaths": 10, "total_damage": 999}).size() == 1, "only the met message fires")
	_check(not OverseerMessenger.is_met(list[2], {}), "unknown trigger kind never fires")
	state.free()


func _test_overseer_files_load() -> void:
	print("overseer messages load")
	var messages: Array[OverseerMessage] = OverseerMessenger.load_all()
	_check(messages.size() >= 8, "at least 8 overseer messages load")
	var all_have_text: bool = true
	var ids: Dictionary = {}
	for message: OverseerMessage in messages:
		if message.text.strip_edges().is_empty() or message.message_id.is_empty():
			all_have_text = false
		ids[message.message_id] = true
	_check(all_have_text, "every overseer message has an id and text")
	_check(ids.size() == messages.size(), "overseer message ids are unique")


func _test_act_2_unlocks_and_saves() -> void:
	print("act 2 unlocks at its trigger and saves as a flag")
	var state: Node = _state()
	var progress: NarrativeProgress = NarrativeProgress.new(state)
	_check(progress.try_advance({"wave": 19}) == 0 and progress.current_act() == 1, "act 2 stays locked below wave 20")
	_check(progress.try_advance({"wave": 20}) == 2 and progress.current_act() == 2, "act 2 unlocks at wave 20")
	_check(state.has_flag("act_unlocked_2"), "act 2 is saved as a flag")
	var restored: Node = _state()
	restored.from_dict(state.to_dict())
	_check(NarrativeProgress.new(restored).current_act() == 2, "act 2 survives a save and load")
	state.free()
	restored.free()


func _test_act_3_requires_act_2() -> void:
	print("act 3 requires act 2")
	var state: Node = _state()
	var progress: NarrativeProgress = NarrativeProgress.new(state)
	_check(progress.try_advance({"deaths": 60, "wave": 5}) == 0, "act 3 does not unlock before act 2")
	_check(not state.has_flag("act_unlocked_3"), "no act 3 flag without act 2")
	progress.try_advance({"wave": 20})
	_check(progress.try_advance({"deaths": 50}) == 3 and progress.current_act() == 3, "act 3 unlocks after act 2 at 50 deaths")
	state.free()


func _test_act_effects_and_dialogue() -> void:
	print("act effects and dialogue")
	_check(NarrativeProgress.effects_for_act(1).is_empty(), "act 1 has no effect hooks")
	var act_2: Dictionary = NarrativeProgress.effects_for_act(2)
	_check(is_equal_approx(float(act_2["freeze_enemies_chance"]), 0.05) and act_2["glitch_counters"] == true, "act 2 lists freeze and glitch hooks")
	_check(NarrativeProgress.effects_for_act(3).has("reveal_truth"), "act 3 lists the truth hook")
	for act: int in [1, 2, 3]:
		var sequence: DialogueSequence = load("res://resources/dialogue/act_%d.tres" % act)
		var speakers_ok: bool = sequence != null and not sequence.lines.is_empty()
		for line: DialogueLine in sequence.lines if sequence != null else []:
			speakers_ok = speakers_ok and (line.speaker == "OVERSEER" or line.speaker == "SYSTEM")
		_check(speakers_ok and sequence.sequence_id == "act_%d" % act, "act %d dialogue loads with OVERSEER or SYSTEM lines" % act)
