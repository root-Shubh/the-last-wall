## Lifetime counters for achievements and the stats screen (SVTLW-78).
## Counters only grow and never go below zero. Save data is optional: old saves load as zeros.
class_name StatsTracker
extends RefCounted

var total_kills: int = 0
var waves_survived: int = 0
var resources_earned: int = 0
var damage_dealt: int = 0
var damage_received: int = 0
var deaths: int = 0
var playtime_seconds: float = 0.0
var highest_wave: int = 0
var highest_damage_hit: int = 0


func record_kill() -> void:
	total_kills += 1


## Counts a survived wave and keeps the highest wave number reached.
func record_wave_survived(wave: int) -> void:
	waves_survived += 1
	highest_wave = maxi(highest_wave, maxi(wave, 0))


func record_resources(amount: int) -> void:
	resources_earned += maxi(amount, 0)


func record_damage_dealt(amount: int) -> void:
	damage_dealt += maxi(amount, 0)


func record_damage_received(amount: int) -> void:
	damage_received += maxi(amount, 0)


func record_death() -> void:
	deaths += 1


## Adds to playtime. Negative and non-finite values are ignored.
func add_playtime(seconds: float) -> void:
	if is_finite(seconds) and seconds > 0.0:
		playtime_seconds += seconds


## Records one damage hit, keeping the largest single hit.
func record_hit(amount: int) -> void:
	highest_damage_hit = maxi(highest_damage_hit, maxi(amount, 0))


func to_dict() -> Dictionary:
	return {
		"total_kills": total_kills,
		"waves_survived": waves_survived,
		"resources_earned": resources_earned,
		"damage_dealt": damage_dealt,
		"damage_received": damage_received,
		"deaths": deaths,
		"playtime_seconds": playtime_seconds,
		"highest_wave": highest_wave,
		"highest_damage_hit": highest_damage_hit,
	}


## Loads counters from a save. Missing or invalid values become zero. Never fails.
func from_dict(data: Variant) -> void:
	reset()
	if typeof(data) != TYPE_DICTIONARY:
		return
	total_kills = _whole(data, "total_kills")
	waves_survived = _whole(data, "waves_survived")
	resources_earned = _whole(data, "resources_earned")
	damage_dealt = _whole(data, "damage_dealt")
	damage_received = _whole(data, "damage_received")
	deaths = _whole(data, "deaths")
	highest_wave = _whole(data, "highest_wave")
	highest_damage_hit = _whole(data, "highest_damage_hit")
	var playtime: Variant = data.get("playtime_seconds", 0.0)
	if (typeof(playtime) == TYPE_FLOAT or typeof(playtime) == TYPE_INT) and is_finite(float(playtime)) and float(playtime) >= 0.0:
		playtime_seconds = float(playtime)


func reset() -> void:
	total_kills = 0
	waves_survived = 0
	resources_earned = 0
	damage_dealt = 0
	damage_received = 0
	deaths = 0
	playtime_seconds = 0.0
	highest_wave = 0
	highest_damage_hit = 0


func _whole(data: Dictionary, key: String) -> int:
	var value: Variant = data.get(key, 0)
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0
	var number: float = float(value)
	if number < 0.0 or not is_equal_approx(number, floor(number)) or number > 9.0e15:
		return 0
	return int(number)
