## Wave 1000 and the final Overseer battle (SVTLW-83). Pure phase logic. Each phase ends on a
## kill target. Each phase brings a mechanic: Overlord attacks, then Overseer interventions that
## switch off one defence slot at a time, then both together.
class_name FinalBattle
extends RefCounted

const FINAL_WAVE: int = 1000
const OVERLORD_ID: String = "overlord"
## Cumulative kills that finish each phase. The last entry ends the battle.
const PHASE_KILL_TARGETS: Array[int] = [10, 25, 45]
## Ticks between Overlord spawns in phases 1 and 3.
const OVERLORD_INTERVAL_TICKS: int = 120
## Ticks between Overseer interventions in phases 2 and 3.
const INTERVENTION_INTERVAL_TICKS: int = 180
## Ticks a switched-off slot stays disabled.
const INTERVENTION_LENGTH_TICKS: int = 90

var active: bool = false
var victory: bool = false
var phase: int = 0
var kills: int = 0
var overlords_spawned: int = 0
var interventions: int = 0
## Slot number -> tick at which it comes back on.
var disabled_until: Dictionary = {}
var _tick_count: int = 0
var _last_overlord_tick: int = 0
var _last_intervention_tick: int = 0


static func is_final_wave(wave_number: int) -> bool:
	return wave_number == FINAL_WAVE


func begin() -> bool:
	if active or victory:
		return false
	active = true
	phase = 1
	_tick_count = 0
	_last_overlord_tick = 0
	_last_intervention_tick = 0
	return true


## Counts a kill. Enemies that are not Overlords count toward the phase. Overlord kills count too.
func record_kill(_enemy_id: String) -> void:
	if not active:
		return
	kills += 1
	while active and kills >= PHASE_KILL_TARGETS[phase - 1]:
		if phase == PHASE_KILL_TARGETS.size():
			active = false
			victory = true
			disabled_until.clear()
			return
		phase += 1


## Advances one tick. Returns the events raised this tick: "overlord" or "intervention".
func on_tick(slot_count: int) -> Array[String]:
	var events: Array[String] = []
	if not active:
		return events
	_tick_count += 1
	for slot: Variant in disabled_until.keys():
		if _tick_count >= int(disabled_until[slot]):
			disabled_until.erase(slot)
	if phase == 1 or phase == 3:
		if _tick_count - _last_overlord_tick >= OVERLORD_INTERVAL_TICKS:
			_last_overlord_tick = _tick_count
			overlords_spawned += 1
			events.append("overlord")
	if (phase == 2 or phase == 3) and slot_count > 0:
		if _tick_count - _last_intervention_tick >= INTERVENTION_INTERVAL_TICKS:
			_last_intervention_tick = _tick_count
			var slot: int = _tick_count % slot_count
			disabled_until[slot] = _tick_count + INTERVENTION_LENGTH_TICKS
			interventions += 1
			events.append("intervention")
	return events


func slot_disabled(slot: int) -> bool:
	return disabled_until.has(slot)


func to_dict() -> Dictionary:
	return {
		"active": active,
		"victory": victory,
		"phase": phase,
		"kills": kills,
		"overlords_spawned": overlords_spawned,
		"interventions": interventions,
		"disabled_until": disabled_until.duplicate(),
		"tick_count": _tick_count,
		"last_overlord_tick": _last_overlord_tick,
		"last_intervention_tick": _last_intervention_tick,
	}


func from_dict(data: Dictionary) -> void:
	active = bool(data.get("active", false))
	victory = bool(data.get("victory", false))
	phase = clampi(int(data.get("phase", 0)), 0, PHASE_KILL_TARGETS.size())
	kills = maxi(int(data.get("kills", 0)), 0)
	overlords_spawned = maxi(int(data.get("overlords_spawned", 0)), 0)
	interventions = maxi(int(data.get("interventions", 0)), 0)
	disabled_until = {}
	var raw: Variant = data.get("disabled_until", {})
	if typeof(raw) == TYPE_DICTIONARY:
		for key: Variant in raw:
			disabled_until[int(key)] = int(raw[key])
	_tick_count = maxi(int(data.get("tick_count", 0)), 0)
	_last_overlord_tick = int(data.get("last_overlord_tick", 0))
	_last_intervention_tick = int(data.get("last_intervention_tick", 0))
