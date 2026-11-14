## Versioned save and load with atomic writes. Autoload name: SaveManager.
## Single slot for M1. Autosave is SVTLW-45. Multiple slots and migration tests come in M8 (SVTLW-93).
extends Node

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save_slot_1.json"
const TEMP_PATH: String = "user://save_slot_1.tmp"
const BACKUP_PATH: String = "user://save_slot_1.bak"

signal save_completed(success: bool)
signal load_completed(success: bool)


## Writes the save to a temporary file, then renames it over the real save.
## A failed write never replaces a previously valid save.
func save_game() -> bool:
	var payload: Dictionary = {
		"schema_version": SAVE_VERSION,
		"state": GameState.to_dict(),
	}
	var text: String = JSON.stringify(payload, "\t")

	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open temp save (%s)" % error_string(FileAccess.get_open_error()))
		save_completed.emit(false)
		return false
	file.store_string(text)
	file.close()

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: cannot open user:// directory")
		save_completed.emit(false)
		return false

	# Windows may refuse to rename over an existing file, so move the old save aside first.
	# The old save is restored if the new one cannot be put in place.
	var had_previous: bool = FileAccess.file_exists(SAVE_PATH)
	if had_previous:
		var moved_aside: Error = dir.rename(SAVE_PATH.get_file(), BACKUP_PATH.get_file())
		if moved_aside != OK:
			push_error("SaveManager: cannot move existing save aside (%s)" % error_string(moved_aside))
			save_completed.emit(false)
			return false

	var renamed: Error = dir.rename(TEMP_PATH.get_file(), SAVE_PATH.get_file())
	if renamed != OK and had_previous:
		dir.rename(BACKUP_PATH.get_file(), SAVE_PATH.get_file())
	elif had_previous:
		dir.remove(BACKUP_PATH.get_file())

	var success: bool = renamed == OK
	if not success:
		push_error("SaveManager: rename failed (%s)" % error_string(renamed))
	save_completed.emit(success)
	return success


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Loads and validates the save. Game state changes only when the whole file is valid.
func load_game() -> bool:
	if not has_save():
		load_completed.emit(false)
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open save (%s)" % error_string(FileAccess.get_open_error()))
		load_completed.emit(false)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save is not a JSON object; keeping current state")
		load_completed.emit(false)
		return false

	var payload: Dictionary = parsed
	if not payload.has("schema_version") or int(payload["schema_version"]) != SAVE_VERSION:
		push_warning("SaveManager: unsupported save version; keeping current state")
		load_completed.emit(false)
		return false
	if not payload.has("state") or typeof(payload["state"]) != TYPE_DICTIONARY:
		push_warning("SaveManager: save has no state block; keeping current state")
		load_completed.emit(false)
		return false

	var success: bool = GameState.from_dict(payload["state"])
	if not success:
		push_warning("SaveManager: save state failed validation; keeping current state")
	load_completed.emit(success)
	return success
