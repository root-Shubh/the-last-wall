## Headless tests for the top bar HUD (SVTLW-28).
## Run: godot --headless --path game -s res://tests/test_hud.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.add_gold(75)

	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	root.add_child(field)
	field.ensure_ready()
	var hud: TopBar = field.hud

	print("labels")
	_check(hud._gold_label.text == "Gold 75", "gold label shows the balance")
	state.spend_gold(25)
	_check(hud._gold_label.text == "Gold 50", "gold label updates on spend")
	_check(hud._wall_label.text == "Wall 100 / 100", "wall label shows health and max")
	state.damage_wall(20)
	_check(hud._wall_label.text == "Wall 80 / 100", "wall label updates on damage")
	_check(hud._wood_label.text.contains("--") and hud._research_label.text.contains("--"), "unbuilt resources show placeholders")
	field.start_wave()
	_check(hud._wave_label.text == "Wave 1", "wave label shows the running wave")

	print("speed and pause")
	_check(hud.speed_text() == "Speed 1x", "starts at 1x")
	hud.set_speed(3)
	_check(hud.speed_text() == "Speed 3x" and field.clock.speed == 3, "3x sets the clock and the label")
	hud.toggle_pause()
	_check(hud.speed_text() == "Paused" and field.clock.paused, "pause stops the clock and shows Paused")
	hud.set_speed(2)
	_check(hud.speed_text() == "Speed 2x" and not field.clock.paused, "choosing a speed resumes the clock")

	print("controls")
	var buttons: int = 0
	for child: Node in hud.get_children():
		buttons += _count_buttons(child)
	_check(buttons == 4, "four controls: pause, 1x, 2x, 3x")

	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _count_buttons(node: Node) -> int:
	var count: int = 1 if node is Button else 0
	for child: Node in node.get_children():
		count += _count_buttons(child)
	return count
