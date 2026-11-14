## Hidden simulation instability, 0 to 100 (SVTLW-69). Raised by milestones and data-driven amounts.
## Pure logic: no nodes. Effects are returned as flags for the UI, enemies, messages and unlocks to read.
class_name SimulationInstability
extends RefCounted

const MAX_VALUE: float = 100.0
const MAX_LEVEL: int = 4
## Level n is reached at LEVEL_THRESHOLDS[n - 1]: 25 glitch UI, 50 distort enemies, 75 corrupt messages, 100 collapse-ready.
const LEVEL_THRESHOLDS: Array[float] = [25.0, 50.0, 75.0, 100.0]
const MILESTONE_AMOUNTS: Dictionary = {
	"damage_huge": 8.0,
	"resources_huge": 8.0,
	"large_kill": 5.0,
	"forbidden_tech": 15.0,
	"overwhelm": 10.0,
	"machine_kill": 6.0,
}

var value: float = 0.0


## Raises the value by the fixed amount for a known milestone kind. Unknown kinds and non-strings change nothing.
func add_milestone(kind: Variant) -> void:
	if typeof(kind) != TYPE_STRING or not MILESTONE_AMOUNTS.has(kind):
		return
	add_amount(MILESTONE_AMOUNTS[kind])


## Raises the value by a data-driven amount. Negative, zero, NaN, infinite and non-numeric amounts are ignored.
func add_amount(amount: Variant) -> void:
	var number: float = sanitize_value(amount)
	if number <= 0.0:
		return
	value = clampf(value + number, 0.0, MAX_VALUE)


func reset() -> void:
	value = 0.0


## Current level from 0 (calm) to MAX_LEVEL (collapse-ready).
func level() -> int:
	var result: int = 0
	for index: int in LEVEL_THRESHOLDS.size():
		if value >= LEVEL_THRESHOLDS[index]:
			result = index + 1
	return result


func current_effects() -> Dictionary:
	return effects_for_level(level())


## Cosmetic flags (ui_glitch, enemy_distortion, message_corruption) and the mechanical flag
## unlock_collapse. Each level includes every lower level's effects. Levels are clamped to 0 to MAX_LEVEL.
static func effects_for_level(level_value: Variant) -> Dictionary:
	var lvl: int = 0
	if typeof(level_value) == TYPE_INT or typeof(level_value) == TYPE_FLOAT:
		lvl = clampi(int(clampf(float(level_value), 0.0, float(MAX_LEVEL))), 0, MAX_LEVEL)
	return {
		"level": lvl,
		"ui_glitch": lvl >= 1,
		"enemy_distortion": lvl >= 2,
		"message_corruption": lvl >= 3,
		"unlock_collapse": lvl >= 4,
	}


## Returns a safe stored value: 0 for anything that is not a finite number, otherwise clamped to 0 to 100.
static func sanitize_value(raw: Variant) -> float:
	if typeof(raw) != TYPE_INT and typeof(raw) != TYPE_FLOAT:
		return 0.0
	var number: float = float(raw)
	if is_nan(number) or is_inf(number):
		return 0.0
	return clampf(number, 0.0, MAX_VALUE)


func to_dict() -> Dictionary:
	return {"value": value}


## Loads a dictionary written by to_dict(). A malformed value loads as 0. Returns false for non-dictionaries.
func from_dict(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		value = 0.0
		return false
	var dict: Dictionary = data
	value = sanitize_value(dict.get("value", 0.0))
	return true
