## Headless tests for the gold ledger and upgrades (SVTLW-38, SVTLW-39).
## Run: godot --headless --path game -s res://tests/test_upgrades.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var state: Node = root.get_node("GameState")
	_test_ledger(state)
	_test_upgrade_data(state)
	_test_purchase_rules(state)
	_test_effects(state)
	_test_battlefield_applies_effects(state)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _manager(state: Node) -> UpgradeManager:
	var manager: UpgradeManager = UpgradeManager.new()
	var ids: Array[String] = ["archer_damage", "archer_attack_speed", "wall_max_health", "repair_rate", "gold_per_kill"]
	for id: String in ids:
		manager.definitions.append(load("res://resources/upgrades/%s.tres" % id))
	manager.state = state
	manager._rebuild_index()
	root.add_child(manager)
	return manager


func _test_ledger(state: Node) -> void:
	print("gold ledger")
	state.reset()
	state.add_gold(50)
	var spent: Array = []
	state.gold_spent.connect(func(amount: int, balance: int) -> void: spent.append([amount, balance]))
	var refunded: Array = [0]
	state.gold_refunded.connect(func(amount: int, _b: int) -> void: refunded[0] += amount)
	_check(state.spend_gold(30), "spend within balance succeeds")
	_check(spent.size() == 1 and spent[0] == [30, 20], "gold_spent carries the amount and new balance")
	_check(not state.spend_gold(21) and state.gold == 20, "insufficient spend fails and leaves the balance")
	_check(spent.size() == 1, "failed spend emits nothing")
	state.refund_gold(15)
	_check(state.gold == 35 and refunded[0] == 15, "refund returns gold and emits gold_refunded")
	state.refund_gold(0)
	state.refund_gold(-5)
	_check(state.gold == 35, "zero and negative refunds are ignored")


func _test_upgrade_data(state: Node) -> void:
	print("upgrade data")
	state.reset()
	var manager: UpgradeManager = _manager(state)
	_check(manager.definitions.size() == 5, "five M1 upgrades load")
	var effects: Dictionary = {}
	for data: UpgradeDefinition in manager.definitions:
		effects[data.effect] = true
	_check(effects.size() == 5, "each upgrade changes a different effect")
	_check(manager.cost_for("archer_damage") == 20, "level 0 costs the base cost")
	manager.levels["archer_damage"] = 2
	_check(manager.cost_for("archer_damage") == 45, "cost scales: floor(20 x 1.5^2) = 45")
	manager.levels.clear()
	manager.free()


func _test_purchase_rules(state: Node) -> void:
	print("purchase rules")
	state.reset()
	state.add_gold(100)
	var manager: UpgradeManager = _manager(state)
	_check(manager.purchase_block_reason("repair_rate") == "requires wall_max_health", "prerequisite blocks purchase")
	_check(manager.purchase("archer_damage") and state.gold == 80, "first archer damage level costs 20")
	_check(manager.purchase("wall_max_health") and state.gold == 55, "wall upgrade costs 25")
	_check(manager.purchase("repair_rate") and state.gold == 15, "prerequisite met, repair costs 40 from 55")
	_check(manager.purchase_block_reason("archer_attack_speed") == "not enough gold", "unaffordable upgrade is refused")
	_check(not manager.purchase("archer_attack_speed") and state.gold == 15, "refused purchase spends nothing")
	manager.levels["gold_per_kill"] = 10
	_check(manager.purchase_block_reason("gold_per_kill") == "max level reached", "max level blocks purchase")
	manager.levels.clear()
	manager.free()


func _test_battlefield_applies_effects(state: Node) -> void:
	print("battlefield applies upgrade effects")
	state.reset()
	state.add_gold(500)
	var field: Battlefield = load("res://scenes/battlefield.tscn").instantiate()
	field.game_state = state
	root.add_child(field)
	field.ensure_ready()
	_check(field.buy_upgrade("archer_damage"), "buy archer damage through the battlefield")
	_check(absf(field.units.archer_damage_multiplier - 1.1) < 0.0001, "archer damage multiplier becomes 1.1")
	_check(field.buy_upgrade("wall_max_health"), "buy wall max health")
	_check(state.wall_max_health == 120 and state.wall_health == 120, "wall max and current health rise by 20")
	_check(field.buy_upgrade("repair_rate"), "buy repair rate (needs wall max health first)")
	_check(absf(field.wall.repair_per_second - 1.0) < 0.0001, "wall repair rate becomes 1 per second")
	_check(field.buy_upgrade("gold_per_kill") and field.rewards.kill_gold_bonus == 1, "gold per kill bonus reaches the reward tracker")
	_check(field.buy_upgrade("archer_attack_speed") and field.units.archer_speed_multiplier > 1.0, "attack speed upgrade is bought and applied")


func _test_effects(state: Node) -> void:
	print("effects")
	state.reset()
	state.add_gold(1000)
	var manager: UpgradeManager = _manager(state)
	manager.purchase("archer_damage")
	manager.purchase("archer_damage")
	_check(absf(manager.effect_total("archer_damage") - 0.2) < 0.0001, "two levels of archer damage give +0.2")
	_check(manager.effect_total("repair_rate") == 0.0, "upgrades that are not bought add nothing")
	var preview: Dictionary = manager.preview("archer_damage")
	_check(preview.get("next_level") == 3 and preview.get("cost") == 45, "preview shows next level and cost")
	manager.levels.clear()
	manager.free()
