## Save migrations, corrupt-save handling and balance simulator smoke tests (SVTLW-90, SVTLW-91, SVTLW-93).
## Fixtures live in res://tests/fixtures. Loads go through the real SaveManager file at SAVE_PATH,
## which this suite overwrites and deletes, the same as test_persistence.
## Run: godot --headless --path game -s res://tests/test_migrations.gd
extends SceneTree

const SAVE_PATH: String = "user://save_slot_1.json"
const SAVE_VERSION: int = 1
const FIXTURE_V1: String = "res://tests/fixtures/save_v1.json"
const FIXTURE_CORRUPT: String = "res://tests/fixtures/save_corrupt.json"

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	var saves: Node = root.get_node("SaveManager")
	_remove_save()

	_test_v1_fixture(state, saves)
	_test_corrupt_fixture(state, saves)
	_test_round_trip(state, saves)
	_test_balance_sim()
	_remove_save()

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _remove_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Copies a res:// fixture byte for byte over the save path, as if the player had that file on disk.
func _install_fixture(path: String) -> void:
	var source: FileAccess = FileAccess.open(path, FileAccess.READ)
	var text: String = source.get_as_text()
	source.close()
	var target: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	target.store_string(text)
	target.close()


func _test_v1_fixture(state: Node, saves: Node) -> void:
	print("schema v1 fixture")
	var source: FileAccess = FileAccess.open(FIXTURE_V1, FileAccess.READ)
	_check(source != null, "fixture file is readable")
	var payload: Dictionary = JSON.parse_string(source.get_as_text())
	source.close()
	_check(int(payload.get("schema_version", 0)) == SAVE_VERSION, "fixture is schema version 1")

	state.reset()
	_check(state.from_dict(payload["state"]), "GameState.from_dict accepts the fixture")
	_check(state.gold == 340, "fixture gold is 340")
	_check(state.current_wave == 4, "fixture wave is 4")
	_check(state.wall_health == 80 and state.wall_max_health == 120, "fixture wall is 80 of 120")
	_check(state.character_id == "" and state.flags.is_empty(), "fields missing from v1 default to empty")
	_check(state.wall_tier == 1 and state.production_levels.is_empty(), "missing tier and production default")
	_check(state.wood + state.stone + state.iron == 0, "missing materials default to zero")

	state.reset()
	_install_fixture(FIXTURE_V1)
	_check(saves.load_game(), "SaveManager.load_game loads the v1 fixture")
	_check(state.gold == 340 and state.current_wave == 4, "load_game restores gold and wave from v1")
	_check(state.wall_health == 80 and state.wall_max_health == 120, "load_game restores the wall from v1")


func _test_corrupt_fixture(state: Node, saves: Node) -> void:
	print("corrupt save")
	state.reset()
	state.add_gold(50)
	state.set_wave(2)
	_check(saves.save_game(), "a valid save is written first")
	var valid_bytes: String = FileAccess.get_file_as_string(SAVE_PATH)

	_install_fixture(FIXTURE_CORRUPT)
	state.reset()
	state.add_gold(7)
	_check(not saves.load_game(), "truncated JSON is rejected")
	_check(state.gold == 7 and state.current_wave == 0, "rejected load leaves current state untouched")

	var bad_wall: Dictionary = {"gold": 1, "wave": 1, "wall_health": 200, "wall_max_health": 100}
	_check(not state.from_dict(bad_wall), "wall health above maximum is rejected")
	_check(state.gold == 7, "rejected from_dict leaves gold untouched")

	var negative: Dictionary = {"gold": -5, "wave": 1, "wall_health": 10, "wall_max_health": 100}
	_check(not state.from_dict(negative), "negative gold is rejected")

	_check(not saves.load_game() or state.gold == 7, "repeat load of corrupt data changes nothing")
	# The corrupt copy is ours to replace; restore a valid save for the next test.
	var rewrite: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	rewrite.store_string(valid_bytes)
	rewrite.close()
	_check(saves.load_game() and state.gold == 50, "a valid save still loads after the corrupt attempts")
	_check(not FileAccess.file_exists("user://save_slot_1.tmp"), "no temp file is left behind after saving")


func _test_round_trip(state: Node, saves: Node) -> void:
	print("round trip")
	state.reset()
	state.add_gold(123)
	state.set_wave(2)
	state.set_wall_max_health(150)
	state.damage_wall(30)
	state.set_flag("intro_seen", true)
	state.set_character("female", "Ann")
	state.add_material("wood", 7)
	state.production_levels = {"smithy": 2}
	state.wall_tier = 3
	var before: Dictionary = state.to_dict()

	_check(saves.save_game({"battlefield": {"tick": 9}}), "save_game writes the state")
	state.reset()
	_check(saves.load_game(), "save_game output loads back")
	_check(state.to_dict() == before, "loaded state equals the saved state")
	_check(saves.last_extra.get("battlefield", {}).get("tick", -1) == 9, "extra data round trips")
	_remove_save()


func _test_balance_sim() -> void:
	print("balance simulator")
	var archer_only: Dictionary = {"units": [{"id": "archer", "count": 1}], "upgrades": {}}
	var result: Dictionary = BalanceSim.evaluate(archer_only)
	_check(float(result.get("dps", 0.0)) > 0.0, "one archer has DPS above zero")
	var findings: Array[String] = BalanceSim.findings(BalanceSim.standard_builds())
	_check(findings is Array, "findings list is returned (%d flagged)" % findings.size())
	for line: String in findings:
		print("        finding: %s" % line)
