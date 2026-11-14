## Headless check that the M1 battlefield scene builds with its required parts (SVTLW-24).
## Run: godot --headless --path game -s res://tests/test_battlefield.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	_check(packed != null, "battlefield scene loads")
	if packed != null:
		var field: Node = packed.instantiate()
		root.add_child(field)
		_check(field.has_node("Fortress/Wall"), "wall present")
		_check(field.has_node("Fortress/ArcherA") and field.has_node("Fortress/ArcherB") and field.has_node("Fortress/ArcherC"), "three archer slots present")
		_check(field.has_node("SpawnLane"), "spawn lane present")
		var wall: ColorRect = field.get_node("Fortress/Wall")
		var spawn: Marker2D = field.get_node("SpawnLane")
		_check(wall.global_position.x < spawn.global_position.x, "fortress is left of the spawn lane")
		_check(spawn.global_position.x <= 1280.0, "spawn lane inside 1280 width")
		field.queue_free()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)
