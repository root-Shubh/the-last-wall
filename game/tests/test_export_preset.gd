## Headless checks for the Windows export preset, store plan, release checklist and build ignore rule (SVTLW-94, SVTLW-96, SVTLW-97).
## Run: godot --headless --path game -s res://tests/test_export_preset.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_export_preset()
	_test_gitignore()
	_test_store_plan()
	_test_release_checklist()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


## Reads a file that sits beside the game folder (repo root), using an absolute path on disk.
func _repo_file(relative: String) -> String:
	var path := ProjectSettings.globalize_path("res://").path_join("..").path_join(relative).simplify_path()
	return FileAccess.get_file_as_string(path)


func _test_export_preset() -> void:
	print("windows export preset")
	var cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check(cfg != "", "export_presets.cfg exists")
	_check(cfg.contains("platform=\"Windows Desktop\""), "preset platform is Windows Desktop")
	_check(cfg.contains("name=\"Windows Desktop\""), "preset is named Windows Desktop")
	_check(cfg.contains("export_path=\"../build/"), "output path is under ../build/")
	_check(cfg.contains("binary_format/embed_pck=true"), "PCK is embedded")


func _test_gitignore() -> void:
	print("gitignore")
	var lines := Array(_repo_file(".gitignore").replace("\r", "").split("\n"))
	_check(lines.has("build/"), ".gitignore contains build/")


func _test_store_plan() -> void:
	print("store plan")
	var text := _repo_file("docs/STORE_PLAN.md")
	_check(text != "", "docs/STORE_PLAN.md exists")
	_check(text.to_lower().contains("not created"), "store page is marked not created")


func _test_release_checklist() -> void:
	print("release checklist")
	var text := _repo_file("docs/ROADMAP.md")
	_check(text.contains("Release checklist"), "docs/ROADMAP.md contains Release checklist")
