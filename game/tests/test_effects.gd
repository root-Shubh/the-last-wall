## Headless tests for settings persistence, damage numbers and the reduce-effects toggles (SVTLW-37).
## Run: godot --headless --path game -s res://tests/test_effects.gd
extends SceneTree

const TEST_PATH: String = "user://test_settings.cfg"

var _failures: int = 0


func _initialize() -> void:
	_test_settings_persist()
	_test_damage_numbers_toggle()
	_test_screen_shake_toggle()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_settings_persist() -> void:
	print("settings persist")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var store: SettingsStore = SettingsStore.new()
	_check(not store.load_from(TEST_PATH) and store.damage_numbers_enabled and store.screen_shake_enabled, "missing file keeps defaults (on)")
	store.damage_numbers_enabled = false
	store.screen_shake_enabled = false
	_check(store.save_to(TEST_PATH), "settings save")
	var reloaded: SettingsStore = SettingsStore.new()
	_check(reloaded.load_from(TEST_PATH), "settings load after save")
	_check(not reloaded.damage_numbers_enabled and not reloaded.screen_shake_enabled, "toggles persist across load")


func _test_damage_numbers_toggle() -> void:
	print("damage numbers toggle")
	var store: SettingsStore = SettingsStore.new()
	var numbers: DamageNumbers = DamageNumbers.new()
	numbers.settings = store
	root.add_child(numbers)

	var label: Label = numbers.show_hit(Vector2(100.0, 100.0), 7.4)
	_check(label != null and label.text == "7" and numbers.spawned_count == 1, "a hit shows the rounded damage")

	store.damage_numbers_enabled = false
	_check(numbers.show_hit(Vector2(100.0, 100.0), 9.0) == null, "turning damage numbers off stops new labels")
	_check(numbers.spawned_count == 1, "no label is counted while off")
	numbers.free()


func _test_screen_shake_toggle() -> void:
	print("screen shake toggle")
	var state: Node = root.get_node("GameState")
	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	root.add_child(field)
	field.ensure_ready()
	field.settings.screen_shake_enabled = false
	field.shake(4.0)
	_check(field.shake_count == 0, "no shake when screen shake is off")
	field.settings.screen_shake_enabled = true
	field.shake(4.0)
	_check(field.shake_count == 1, "shake starts when screen shake is on")
