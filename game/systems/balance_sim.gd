## Headless balance simulator (SVTLW-91). Pure: no nodes, no autoloads. Every hit goes through DamageCalculator.
## A build is {"name": String, "units": [{"id": unit_id, "count": int}], "upgrades": {upgrade_id: level}}.
## Model, approximate by design (see docs/BALANCE.md): range is ignored, shields are ignored,
## crits use their expected value, and each unit group fires only at the reference wave.
## Upgrade effects other than the archer ones (gold_per_kill) are read by name; others do not change DPS.
class_name BalanceSim
extends RefCounted

const TICKS_PER_SECOND: float = 10.0
const SPAWN_X: float = 1180.0
const WALL_STOP_X: float = 230.0
## An upgrade step is flagged when its DPS gain per gold is above this multiple of the median step.
const EFFICIENCY_OUTLIER: float = 2.0
## A build is flagged when its DPS per gold is above this multiple of the next best build.
const DOMINANCE_RATIO: float = 1.5
## An upgrade is flagged unaffordable when its first level costs more than this many waves of income.
const AFFORDABLE_WAVES: float = 2.0
const DPS_UPGRADE_IDS: Array[String] = ["archer_damage", "archer_attack_speed"]
const UPGRADE_IDS: Array[String] = ["archer_damage", "archer_attack_speed", "gold_per_kill", "repair_rate", "wall_max_health"]
## Fixed reference wave: enemy id -> count. Every build is scored against this mix.
const REFERENCE_WAVE: Dictionary = {
	"undead_infantry": 10, "runner": 6, "armoured_brute": 2, "shield_bearer": 2, "climber": 2,
}


## Evaluates one build against the reference wave. Keys: dps, ttk, wall_damage, survival, income, cost, dps_per_100_gold.
static func evaluate(build: Dictionary) -> Dictionary:
	var dmg_mult: float = 1.0 + _effect_total(build, "archer_damage")
	var speed_mult: float = 1.0 + _effect_total(build, "archer_attack_speed")
	var gold_bonus: float = _effect_total(build, "gold_per_kill")
	var cost: int = _build_cost(build)

	var total_count: int = 0
	var dps: float = 0.0
	var ttk: float = 0.0
	var wall_damage: float = 0.0
	var killed_total: float = 0.0
	var income: float = 0.0
	for enemy_id: String in REFERENCE_WAVE:
		var enemy: EnemyDefinition = _enemy(enemy_id)
		var count: int = REFERENCE_WAVE[enemy_id]
		var group_dps: float = 0.0
		for entry: Dictionary in build.get("units", []):
			group_dps += _group_dps(entry, enemy, dmg_mult, speed_mult)
		var walk_seconds: float = (SPAWN_X - WALL_STOP_X) / maxf(enemy.move_speed, 0.01)
		var killed: float = minf(float(count), group_dps * walk_seconds / maxf(enemy.max_health, 0.01))
		var leaked: float = float(count) - killed
		total_count += count
		dps += group_dps * count
		ttk += (enemy.max_health / maxf(group_dps, 0.0001)) * count
		wall_damage += leaked * enemy.wall_damage
		killed_total += killed
		income += killed * (enemy.gold_reward + gold_bonus)

	var mean_dps: float = dps / maxf(float(total_count), 1.0)
	var mean_ttk: float = ttk / maxf(float(total_count), 1.0)
	return {
		"dps": mean_dps,
		"ttk": mean_ttk,
		"wall_damage": wall_damage,
		"survival": killed_total / maxf(float(total_count), 1.0),
		"income": income,
		"cost": cost,
		"dps_per_100_gold": 100.0 * mean_dps / maxf(float(cost), 1.0),
	}


## Returns the flagged findings for the given builds, as readable lines. An empty array means nothing is flagged.
static func findings(builds: Array) -> Array[String]:
	var lines: Array[String] = []
	var steps: Array[Dictionary] = _upgrade_steps()
	var efficiencies: Array[float] = []
	for step: Dictionary in steps:
		efficiencies.append(step["efficiency"])
	efficiencies.sort()
	var median: float = efficiencies[efficiencies.size() / 2] if not efficiencies.is_empty() else 0.0
	for step: Dictionary in steps:
		if median > 0.0 and step["efficiency"] > EFFICIENCY_OUTLIER * median:
			lines.append("upgrade %s level %d: DPS gain per gold %.5f is above %.1fx the median %.5f; propose lowering its cost or its effect" % [
				step["id"], step["level"] + 1, step["efficiency"], EFFICIENCY_OUTLIER, median])

	var income: float = _income_per_wave()
	for upgrade_id: String in UPGRADE_IDS:
		var first_cost: int = _upgrade_cost(upgrade_id, 0)
		if float(first_cost) > AFFORDABLE_WAVES * income:
			lines.append("upgrade %s first level costs %d gold, more than %.0f waves of income (%.0f gold); propose a lower base cost" % [
				upgrade_id, first_cost, AFFORDABLE_WAVES, income])

	var scored: Array[Dictionary] = []
	for build: Dictionary in builds:
		scored.append({"name": build.get("name", "?"), "value": evaluate(build)["dps_per_100_gold"]})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["value"] > b["value"])
	if scored.size() >= 2 and scored[1]["value"] > 0.0 and scored[0]["value"] > DOMINANCE_RATIO * scored[1]["value"]:
		lines.append("build %s is dominant: %.2f DPS per 100 gold against %.2f for %s; propose cutting its archer damage or raising its cost" % [
			scored[0]["name"], scored[0]["value"], scored[1]["value"], scored[1]["name"]])
	return lines


## Builds used by the balance report and the tests.
static func standard_builds() -> Array[Dictionary]:
	return [
		{"name": "archers", "units": [{"id": "archer", "count": 10}], "upgrades": {}},
		{"name": "archers_damage", "units": [{"id": "archer", "count": 10}], "upgrades": {"archer_damage": 5}},
		{"name": "archers_speed", "units": [{"id": "archer", "count": 10}], "upgrades": {"archer_damage": 3, "archer_attack_speed": 3}},
		{"name": "crossbow_line", "units": [{"id": "archer", "count": 4}, {"id": "crossbowman", "count": 6}], "upgrades": {"archer_damage": 3}},
		{"name": "gunner_battery", "units": [{"id": "archer", "count": 5}, {"id": "gunner", "count": 5}], "upgrades": {"archer_damage": 3}},
	]


static func _group_dps(entry: Dictionary, enemy: EnemyDefinition, dmg_mult: float, speed_mult: float) -> float:
	var unit: UnitDefinition = load("res://resources/units/%s.tres" % entry["id"])
	if unit == null:
		return 0.0
	var is_archer: bool = unit.unit_id == "archer"
	var interval: int = unit.attack_interval_ticks
	if is_archer:
		interval = maxi(roundi(float(interval) / maxf(speed_mult, 0.01)), 1)
	var shots_per_second: float = TICKS_PER_SECOND / float(interval)
	var armour: float = maxf(enemy.armour - unit.armour_penetration, 0.0)
	var mult: float = dmg_mult if is_archer else 1.0
	var chance: float = clampf(unit.crit_chance, 0.0, 1.0)
	var crit_hit: float = DamageCalculator.calculate(unit.base_damage, mult, chance, unit.crit_multiplier, armour, 1.0, 0.0)
	var plain_hit: float = DamageCalculator.calculate(unit.base_damage, mult, chance, unit.crit_multiplier, armour, 1.0, 1.0)
	var expected: float = chance * crit_hit + (1.0 - chance) * plain_hit
	return float(entry["count"]) * shots_per_second * expected


static func _effect_total(build: Dictionary, effect: String) -> float:
	var total: float = 0.0
	var levels: Dictionary = build.get("upgrades", {})
	for upgrade_id: String in levels:
		var data: UpgradeDefinition = load("res://resources/upgrades/%s.tres" % upgrade_id)
		if data != null and data.effect == effect:
			total += data.effect_per_level * int(levels[upgrade_id])
	return total


static func _build_cost(build: Dictionary) -> int:
	var cost: int = 0
	for entry: Dictionary in build.get("units", []):
		var unit: UnitDefinition = load("res://resources/units/%s.tres" % entry["id"])
		if unit != null:
			cost += unit.recruit_cost * int(entry["count"])
	var levels: Dictionary = build.get("upgrades", {})
	for upgrade_id: String in levels:
		for level: int in range(int(levels[upgrade_id])):
			cost += _upgrade_cost(upgrade_id, level)
	return cost


## Same formula as UpgradeManager.cost_for: base_cost x cost_multiplier^level, floored.
static func _upgrade_cost(upgrade_id: String, level: int) -> int:
	var data: UpgradeDefinition = load("res://resources/upgrades/%s.tres" % upgrade_id)
	if data == null:
		return 0
	return int(floor(data.base_cost * pow(data.cost_multiplier, level)))


## One entry per purchasable archer level on the baseline build, with DPS gain per gold.
static func _upgrade_steps() -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	var baseline: Dictionary = {"units": [{"id": "archer", "count": 10}], "upgrades": {}}
	for upgrade_id: String in DPS_UPGRADE_IDS:
		var data: UpgradeDefinition = load("res://resources/upgrades/%s.tres" % upgrade_id)
		for level: int in range(data.max_level):
			var before: Dictionary = baseline.duplicate(true)
			before["upgrades"][upgrade_id] = level
			var after: Dictionary = baseline.duplicate(true)
			after["upgrades"][upgrade_id] = level + 1
			var gain: float = evaluate(after)["dps"] - evaluate(before)["dps"]
			var cost: int = _upgrade_cost(upgrade_id, level)
			steps.append({"id": upgrade_id, "level": level, "efficiency": gain / maxf(float(cost), 1.0)})
	return steps


## Income of the baseline build over the reference wave, used as the affordability yardstick.
static func _income_per_wave() -> float:
	return evaluate({"units": [{"id": "archer", "count": 10}], "upgrades": {}})["income"]


static func _enemy(enemy_id: String) -> EnemyDefinition:
	return load("res://resources/enemies/%s.tres" % enemy_id)
