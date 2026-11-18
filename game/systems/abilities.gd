## Active abilities (SVTLW-64): Rain of Arrows, Emergency Repair, Reinforcement, Last Stand.
## Pure: tracks unlocks and cooldowns in ticks. The battlefield performs each effect.
class_name Abilities
extends RefCounted

const RAIN_OF_ARROWS: String = "rain_of_arrows"
const EMERGENCY_REPAIR: String = "emergency_repair"
const REINFORCEMENT: String = "reinforcement"
const LAST_STAND: String = "last_stand"

## Each entry: cooldown in ticks and the research id that unlocks it ("" means always available).
const DEFINITIONS: Dictionary = {
	RAIN_OF_ARROWS: {"cooldown_ticks": 300, "unlock_research": "mil_volley_drill"},
	EMERGENCY_REPAIR: {"cooldown_ticks": 450, "unlock_research": "eng_field_repairs"},
	REINFORCEMENT: {"cooldown_ticks": 600, "unlock_research": "log_recruit_drills"},
	LAST_STAND: {"cooldown_ticks": 900, "unlock_research": "eng_masonry"},
}

## Ticks the wall ignores damage during Last Stand.
const LAST_STAND_TICKS: int = 60

var _ready_at: Dictionary = {}


func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in DEFINITIONS:
		ids.append(id)
	return ids


func is_known(id: String) -> bool:
	return DEFINITIONS.has(id)


## Unlocked when no research is needed or the research is done.
func is_unlocked(id: String, researched: Array) -> bool:
	if not is_known(id):
		return false
	var needed: String = DEFINITIONS[id]["unlock_research"]
	return needed == "" or researched.has(needed)


func cooldown_remaining(id: String, tick: int) -> int:
	return maxi(int(_ready_at.get(id, 0)) - tick, 0)


## True when the ability is known, unlocked and off cooldown.
func can_use(id: String, tick: int, researched: Array) -> bool:
	return is_unlocked(id, researched) and cooldown_remaining(id, tick) == 0


## Starts the cooldown and returns true, or returns false and changes nothing when it cannot be used.
func use(id: String, tick: int, researched: Array) -> bool:
	if not can_use(id, tick, researched):
		return false
	_ready_at[id] = tick + int(DEFINITIONS[id]["cooldown_ticks"])
	return true


func reset() -> void:
	_ready_at.clear()


## Cooldown end ticks for saving.
func to_dict() -> Dictionary:
	return {"ready_at": _ready_at.duplicate()}


func from_dict(data: Dictionary) -> void:
	_ready_at = {}
	var raw: Variant = data.get("ready_at", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for key: Variant in raw:
		if typeof(key) == TYPE_STRING and DEFINITIONS.has(key) and (typeof(raw[key]) == TYPE_INT or typeof(raw[key]) == TYPE_FLOAT):
			_ready_at[key] = int(raw[key])


## Why an ability cannot be used right now, for the player. Empty string when it can be used.
func refusal_reason(id: String, tick: int, researched: Array) -> String:
	if not is_known(id):
		return "Unknown ability"
	if not is_unlocked(id, researched):
		var needed: String = DEFINITIONS[id]["unlock_research"]
		return "Locked: research %s first" % needed.replace("_", " ").capitalize()
	var remaining: int = cooldown_remaining(id, tick)
	if remaining > 0:
		return "Ready in %d seconds" % ceili(float(remaining) / 10.0)
	return ""
