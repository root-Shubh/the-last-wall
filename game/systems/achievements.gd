## Achievement definitions and unlock state (SVTLW-78). Each id unlocks once and stays unlocked.
class_name Achievements
extends RefCounted

const DEFINITION_PATHS: Array[String] = [
	"res://resources/achievements/kills_1000.tres",
	"res://resources/achievements/wave_25.tres",
	"res://resources/achievements/wave_100.tres",
	"res://resources/achievements/wave_500.tres",
	"res://resources/achievements/wave_1000.tres",
	"res://resources/achievements/wall_tier_7.tres",
	"res://resources/achievements/damage_1000.tres",
	"res://resources/achievements/damage_1000000.tres",
	"res://resources/achievements/first_death.tres",
	"res://resources/achievements/deaths_10.tres",
	"res://resources/achievements/deaths_100.tres",
]

var definitions: Array[Achievement] = []
var unlocked: Array[String] = []


func _init() -> void:
	for path: String in DEFINITION_PATHS:
		var definition: Achievement = load(path)
		if definition != null:
			definitions.append(definition)


func is_unlocked(achievement_id: String) -> bool:
	return unlocked.has(achievement_id)


## Returns the ids that unlocked during this check, in definition order. Already unlocked ids are never returned again.
func check(stats: StatsTracker, wall_tier: int) -> Array[String]:
	var newly: Array[String] = []
	for definition: Achievement in definitions:
		if is_unlocked(definition.achievement_id):
			continue
		if _value_for(definition.stat, stats, wall_tier) >= definition.threshold:
			unlocked.append(definition.achievement_id)
			newly.append(definition.achievement_id)
	return newly


func unlocked_ids() -> Array[String]:
	return unlocked.duplicate()


## Replaces the unlocked list from a save. Non-string entries and unknown ids are dropped, duplicates kept once.
func set_unlocked(ids: Variant) -> void:
	unlocked.clear()
	if typeof(ids) != TYPE_ARRAY:
		return
	for entry: Variant in ids:
		if typeof(entry) != TYPE_STRING or unlocked.has(entry) or not _has_definition(entry):
			continue
		unlocked.append(entry)


func reset() -> void:
	unlocked.clear()


func _has_definition(achievement_id: String) -> bool:
	for definition: Achievement in definitions:
		if definition.achievement_id == achievement_id:
			return true
	return false


func _value_for(stat: String, stats: StatsTracker, wall_tier: int) -> int:
	match stat:
		"total_kills":
			return stats.total_kills
		"highest_wave":
			return stats.highest_wave
		"damage_dealt":
			return stats.damage_dealt
		"deaths":
			return stats.deaths
		"wall_tier":
			return wall_tier
	return 0
