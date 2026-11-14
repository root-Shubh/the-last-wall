## Picks the active Challenge mode entry for a week (SVTLW-77). Pure: no clock reads, no scene access.
## Challenges load from resources/challenges/*.tres, so new challenges are added as data only.
class_name ChallengeRotation
extends RefCounted

const CHALLENGE_DIR: String = "res://resources/challenges"

var challenges: Array[ChallengeDefinition] = []


func _init(list: Array[ChallengeDefinition] = []) -> void:
	challenges = list


## Loads every ChallengeDefinition .tres in a folder, sorted by file name for a stable rotation order.
static func load_from_directory(dir_path: String = CHALLENGE_DIR) -> ChallengeRotation:
	var result: Array[ChallengeDefinition] = []
	var names: PackedStringArray = DirAccess.get_files_at(dir_path)
	names.sort()
	for file_name: String in names:
		var source: String = file_name.trim_suffix(".remap")
		if not source.ends_with(".tres"):
			continue
		var definition: ChallengeDefinition = load(dir_path.path_join(source)) as ChallengeDefinition
		if definition != null:
			result.append(definition)
	return ChallengeRotation.new(result)


func count() -> int:
	return challenges.size()


## Returns the challenge for a week number: week_index modulo the challenge count. Null when none are loaded.
## Negative week indexes wrap the same way (posmod), so every week maps to a valid challenge.
func active_for_week(week_index: int) -> ChallengeDefinition:
	if challenges.is_empty():
		return null
	return challenges[posmod(week_index, challenges.size())]
