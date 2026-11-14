## Headless tests for wall tiers and building level scale (SVTLW-63).
## Run: godot --headless --path game -s res://tests/test_wall_tiers.gd
extends SceneTree

const EXPECTED_NAMES: Array[String] = [
	"Wooden Palisade",
	"Reinforced Wooden Wall",
	"Stone Fortification",
	"Reinforced Stone Wall",
	"Ironclad Fortress",
	"Ancient Fortress",
	"Legendary Bastion",
]

var _failures: int = 0


func _initialize() -> void:
	_test_tiers_load()
	_test_upgrade_spends_and_keeps_ratio()
	_test_refused_upgrade_changes_nothing()
	_test_tier_seven_and_signal()
	_test_building_level_scale()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


## Builds a manager bound to a fresh WallManager and the GameState autoload.
func _setup(gold: int) -> Array:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.add_gold(gold)
	var wall: WallManager = WallManager.new()
	var manager: WallTierManager = WallTierManager.new()
	manager.bind(state, wall)
	return [state, wall, manager]


func _test_tiers_load() -> void:
	print("seven tiers load")
	var parts: Array = _setup(0)
	var manager: WallTierManager = parts[2]
	_check(manager.tiers.size() == 7, "seven tier resources load")
	var names_ok: bool = true
	var increasing: bool = true
	for index: int in range(manager.tiers.size()):
		var tier: WallTier = manager.tiers[index]
		names_ok = names_ok and tier.display_name == EXPECTED_NAMES[index] and tier.tier == index + 1
		if index > 0:
			var before: WallTier = manager.tiers[index - 1]
			increasing = increasing and tier.max_health > before.max_health and tier.armour > before.armour
	_check(names_ok, "tier names and numbers match the spec")
	_check(increasing, "health and armour strictly increase with each tier")
	_check(manager.current_tier().tier == 1 and parts[1].armour == 1.0, "bind starts at tier 1 and applies its armour")
	parts[1].free()
	manager.free()


func _test_upgrade_spends_and_keeps_ratio() -> void:
	print("upgrade spends gold and keeps health ratio")
	var parts: Array = _setup(100)
	var state: Node = parts[0]
	var wall: WallManager = parts[1]
	var manager: WallTierManager = parts[2]
	state.set_wall_max_health(100)
	state.wall_health = 50
	_check(manager.upgrade_tier(), "upgrade to tier 2 succeeds")
	_check(state.gold == 60, "upgrade spends the tier 2 cost (40 gold)")
	_check(state.wall_max_health == 150 and state.wall_health == 75, "max health 150 and health 75")
	_check(is_equal_approx(float(state.wall_health) / state.wall_max_health, 0.5), "health ratio stays 0.5")
	_check(state.wall_tier == 2 and wall.armour == 1.5 and wall.repair_per_second == 0.75, "wall armour and repair updated")
	parts[1].free()
	manager.free()


func _test_refused_upgrade_changes_nothing() -> void:
	print("refused upgrade")
	var parts: Array = _setup(10)
	var state: Node = parts[0]
	var wall: WallManager = parts[1]
	var manager: WallTierManager = parts[2]
	state.set_wall_max_health(100)
	state.wall_health = 50
	var changes: Array = [0]
	manager.tier_changed.connect(func(_tier: int) -> void: changes[0] += 1)
	_check(not manager.upgrade_tier(), "upgrade refused without enough gold")
	_check(state.gold == 10 and state.wall_max_health == 100 and state.wall_health == 50, "gold, max and health unchanged")
	_check(manager.current_index == 0 and wall.armour == 1.0 and changes[0] == 0, "tier, armour and signal unchanged")
	wall.free()
	manager.free()


func _test_tier_seven_and_signal() -> void:
	print("tier 7 limit and tier_changed")
	var parts: Array = _setup(100000)
	var state: Node = parts[0]
	var manager: WallTierManager = parts[2]
	var fired: Array = []
	manager.tier_changed.connect(func(tier: int) -> void: fired.append(tier))
	var successes: int = 0
	for attempt: int in range(10):
		if manager.upgrade_tier():
			successes += 1
	_check(successes == 6, "six successful upgrades reach tier 7")
	_check(fired == [2, 3, 4, 5, 6, 7], "tier_changed fires once per upgrade with the new tier")
	_check(not manager.upgrade_tier() and state.wall_tier == 7, "upgrade at tier 7 returns false")
	_check(fired.size() == 6, "no signal at tier 7")
	parts[1].free()
	manager.free()


func _test_building_level_scale() -> void:
	print("building level scale")
	_check(is_equal_approx(BuildingLevelVisuals.scale_for_level(1), 1.0), "level 1 scale is 1.0")
	_check(is_equal_approx(BuildingLevelVisuals.scale_for_level(2), 1.2), "level 2 scale is 1.2")
	_check(is_equal_approx(BuildingLevelVisuals.scale_for_level(5), 1.8), "level 5 scale is 1.8")
	_check(BuildingLevelVisuals.scale_for_level(3) > BuildingLevelVisuals.scale_for_level(2), "scale grows with level")
