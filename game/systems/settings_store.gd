## Player settings that affect feedback (SVTLW-37). Saved to user://settings.cfg so they persist.
## Missing or unreadable files fall back to defaults and never block the game.
class_name SettingsStore
extends RefCounted

const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "effects"

var damage_numbers_enabled: bool = true
var screen_shake_enabled: bool = true


## Returns true if a file was read. Otherwise keeps the defaults.
func load_from(path: String = DEFAULT_PATH) -> bool:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return false
	damage_numbers_enabled = bool(config.get_value(SECTION, "damage_numbers", true))
	screen_shake_enabled = bool(config.get_value(SECTION, "screen_shake", true))
	return true


func save_to(path: String = DEFAULT_PATH) -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION, "damage_numbers", damage_numbers_enabled)
	config.set_value(SECTION, "screen_shake", screen_shake_enabled)
	return config.save(path) == OK
