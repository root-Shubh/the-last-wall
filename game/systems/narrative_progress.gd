## Story acts 1 to 3 (SVTLW-68). Acts are stored as GameState flags so they save with the game.
## Trigger checks are pure functions over a stats dictionary built by the caller.
class_name NarrativeProgress
extends RefCounted

const MAX_ACT: int = 3
const ACT_FLAG_PREFIX: String = "act_unlocked_"
## Trigger per act. Act 1 is always active. Act 2 needs wave 20. Act 3 needs 50 deaths and act 2.
const ACT_TRIGGERS: Dictionary = {
	2: {"stat": "wave", "value": 20},
	3: {"stat": "deaths", "value": 50},
}
## Data hooks for each act, read by battlefield code later. Cumulative: act 3 keeps act 2's effects.
const ACT_EFFECTS: Dictionary = {
	1: {},
	2: {"freeze_enemies_chance": 0.05, "glitch_counters": true},
	3: {"freeze_enemies_chance": 0.05, "glitch_counters": true, "reveal_truth": true},
}

var _state: Node


func _init(state: Node) -> void:
	_state = state


func is_act_unlocked(act: int) -> bool:
	if act <= 1:
		return true
	return _state.has_flag(ACT_FLAG_PREFIX + str(act))


## The highest unlocked act, from 1 to MAX_ACT.
func current_act() -> int:
	for act: int in range(MAX_ACT, 0, -1):
		if is_act_unlocked(act):
			return act
	return 1


## True when the stats meet the act's trigger. Act 1 has no trigger, so this is false for it.
static func trigger_met(act: int, stats: Dictionary) -> bool:
	if not ACT_TRIGGERS.has(act):
		return false
	var trigger: Dictionary = ACT_TRIGGERS[act]
	return int(stats.get(trigger["stat"], 0)) >= int(trigger["value"])


## Unlocks the next act when its trigger is met. Only the act right after the current one can
## unlock, so act 3 always requires act 2. Returns the act unlocked by this call, or 0.
func try_advance(stats: Dictionary) -> int:
	var next: int = current_act() + 1
	if next > MAX_ACT or not trigger_met(next, stats):
		return 0
	_state.set_flag(ACT_FLAG_PREFIX + str(next), true)
	return next


## Effects active in an act, as data. Returns a copy, so callers cannot change the table.
static func effects_for_act(act: int) -> Dictionary:
	var clamped: int = clampi(act, 1, MAX_ACT)
	return ACT_EFFECTS[clamped].duplicate()
