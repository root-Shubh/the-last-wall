## Global game state: gold, current wave and wall health.
## Autoload name: GameState. Spending rules are expanded in SVTLW-38 (economy ledger).
extends Node

signal resources_changed(gold: int)
signal wave_changed(wave: int)
signal wall_health_changed(health: int)
## Emitted for every successful spend (SVTLW-38). Refunds emit gold_refunded instead.
signal gold_spent(amount: int, balance: int)
signal gold_refunded(amount: int, balance: int)
## Emitted whenever wood, stone or iron changes (SVTLW-56). Carries all three balances.
signal materials_changed(wood: int, stone: int, iron: int)

## Material ids accepted by the generic add/spend/can_afford path (SVTLW-56).
const MATERIAL_IDS: Array[String] = ["wood", "stone", "iron"]

const DEFAULT_WALL_MAX_HEALTH: int = 100
## Specialisation path ids accepted by prestige_path (SVTLW-74).
const PATH_IDS: Array[String] = ["warlord", "architect", "merchant", "scholar", "arcanist"]

var gold: int = 0
var wood: int = 0
var stone: int = 0
var iron: int = 0
var current_wave: int = 0
## Completed production buildings: building_id -> level (SVTLW-55). Kept in sync by ProductionManager.
var production_levels: Dictionary = {}
var wall_max_health: int = DEFAULT_WALL_MAX_HEALTH
var wall_health: int = DEFAULT_WALL_MAX_HEALTH
## Current wall tier 1 to MAX_WALL_TIER (SVTLW-63). Set by WallTierManager.
const MAX_WALL_TIER: int = 7
var wall_tier: int = 1
## Hidden simulation instability 0 to 100 (SVTLW-69). Optional in saves; raised by milestones.
var instability: float = 0.0
## Completed post-game cycles (SVTLW-85). Zero until the canonical ending is seen and a cycle is finished.
const MAX_POST_GAME_CYCLES: int = 1000
var post_game_cycles: int = 0
## Unix time of the last save, for offline progress (SVTLW-75). 0 means never recorded.
var last_saved_unix: int = 0
## Player choice to allow passive offline production on return (SVTLW-75).
var offline_enabled: bool = true

## Cosmetic and narrative only (SVTLW-42). Both characters play identically.
const CHARACTER_IDS: Array[String] = ["male", "female"]
const NAME_MAX_LENGTH: int = 16
var character_id: String = ""
var character_name: String = ""
## Story flags such as intro_seen (SVTLW-41). Values are booleans.
var flags: Dictionary = {}
## Prestige state (SVTLW-73, SVTLW-74). Kept across run resets; only a new game clears them.
var relics: int = 0
## Permanent relic purchases: relic_id -> level. Written by PrestigeManager.
var relic_levels: Dictionary = {}
var prestige_count: int = 0
## Chosen specialisation path id ("" for none). Only the choice is stored.
var prestige_path: String = ""
## Research save data (SVTLW-61): {"points": int, "researched": Array of ids}. Written by ResearchManager.
var research: Dictionary = {}
## Lifetime statistics and unlocked achievements (SVTLW-78). Optional in saves.
var stats: StatsTracker = StatsTracker.new()
var achievements: Achievements = Achievements.new()


## Restores every value to a new game.
func reset() -> void:
	relics = 0
	relic_levels.clear()
	prestige_count = 0
	prestige_path = ""
	instability = 0.0
	post_game_cycles = 0
	character_id = ""
	character_name = ""
	reset_run()


## Clears the per-run values for a prestige reset (SVTLW-73). Relics, relic levels, prestige count and path are kept.
func reset_run() -> void:
	gold = 0
	wood = 0
	stone = 0
	iron = 0
	current_wave = 0
	production_levels.clear()
	wall_max_health = DEFAULT_WALL_MAX_HEALTH
	wall_health = wall_max_health
	wall_tier = 1
	last_saved_unix = 0
	offline_enabled = true
	flags.clear()
	research = {}
	stats.reset()
	achievements.reset()
	resources_changed.emit(gold)
	_emit_materials()
	wave_changed.emit(current_wave)
	wall_health_changed.emit(wall_health)


func set_wave(value: int) -> void:
	current_wave = maxi(value, 0)
	wave_changed.emit(current_wave)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	resources_changed.emit(gold)


func can_afford(cost: int) -> bool:
	return cost >= 0 and gold >= cost


## Returns true and deducts the cost only when the balance covers it.
func spend_gold(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	resources_changed.emit(gold)
	gold_spent.emit(cost, gold)
	return true


## Returns gold to the balance, for example when a purchase is cancelled. Ignores zero or negative amounts.
func refund_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	resources_changed.emit(gold)
	gold_refunded.emit(amount, gold)


## Balance of a material ("wood", "stone" or "iron"). Unknown ids return 0.
func material_amount(material: String) -> int:
	match material:
		"wood":
			return wood
		"stone":
			return stone
		"iron":
			return iron
	return 0


## Adds a material. Unknown ids and non-positive amounts change nothing.
func add_material(material: String, amount: int) -> void:
	if amount <= 0 or not MATERIAL_IDS.has(material):
		return
	_set_material(material, material_amount(material) + amount)


func can_afford_material(material: String, cost: int) -> bool:
	return MATERIAL_IDS.has(material) and cost >= 0 and material_amount(material) >= cost


## Deducts a material only when the balance covers it. Returns false and changes nothing otherwise.
func spend_material(material: String, cost: int) -> bool:
	if not can_afford_material(material, cost):
		return false
	_set_material(material, material_amount(material) - cost)
	return true


func _set_material(material: String, value: int) -> void:
	match material:
		"wood":
			wood = value
		"stone":
			stone = value
		"iron":
			iron = value
	_emit_materials()


func _emit_materials() -> void:
	materials_changed.emit(wood, stone, iron)


## Raises or lowers the maximum wall health. Current health moves by the same amount (SVTLW-39).
func set_wall_max_health(value: int) -> void:
	if value <= 0:
		return
	var delta: int = value - wall_max_health
	wall_max_health = value
	wall_health = clampi(wall_health + delta, 0, wall_max_health)
	wall_health_changed.emit(wall_health)


func damage_wall(amount: int) -> void:
	wall_health = maxi(wall_health - maxi(amount, 0), 0)
	wall_health_changed.emit(wall_health)


func repair_wall(amount: int) -> void:
	wall_health = mini(wall_health + maxi(amount, 0), wall_max_health)
	wall_health_changed.emit(wall_health)


func is_wall_destroyed() -> bool:
	return wall_health <= 0


## Sets a story flag. Flags are booleans only.
func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))


## True when the id is a known character and the name is 1 to 16 characters after trimming.
func is_valid_character(id: String, display_name: String) -> bool:
	var trimmed: String = display_name.strip_edges()
	return CHARACTER_IDS.has(id) and trimmed.length() >= 1 and trimmed.length() <= NAME_MAX_LENGTH


## Sets the character when is_valid_character is true. Returns false and changes nothing otherwise.
func set_character(id: String, display_name: String) -> bool:
	if not is_valid_character(id, display_name):
		return false
	character_id = id
	character_name = display_name.strip_edges()
	return true


func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"wood": wood,
		"stone": stone,
		"iron": iron,
		"wave": current_wave,
		"wall_health": wall_health,
		"wall_max_health": wall_max_health,
		"character_id": character_id,
		"character_name": character_name,
		"flags": flags.duplicate(),
		"production": production_levels.duplicate(),
		"wall_tier": wall_tier,
		"relics": relics,
		"relic_levels": relic_levels.duplicate(),
		"prestige_count": prestige_count,
		"prestige_path": prestige_path,
		"instability": instability,
		"research": research.duplicate(true),
		"post_game_cycles": post_game_cycles,
		"last_saved_unix": last_saved_unix,
		"offline_enabled": offline_enabled,
		"stats": stats.to_dict(),
		"achievements": achievements.unlocked_ids(),
	}


## Applies saved values only if every field is present, numeric and non-negative.
## Returns false and leaves the current state untouched when the data is invalid.
func from_dict(data: Dictionary) -> bool:
	var keys: Array[String] = ["gold", "wave", "wall_health", "wall_max_health"]
	for key: String in keys:
		if not data.has(key) or not _is_non_negative_whole(data[key]):
			return false
	var new_max: int = int(data["wall_max_health"])
	var new_health: int = int(data["wall_health"])
	if new_max <= 0 or new_health > new_max:
		return false

	# Character and flags are optional so saves from before SVTLW-41 and SVTLW-42 still load.
	var new_id: String = str(data.get("character_id", ""))
	var new_name: String = str(data.get("character_name", ""))
	var new_flags: Dictionary = {}
	if typeof(data.get("flags", {})) == TYPE_DICTIONARY:
		for key: Variant in data.get("flags", {}):
			if typeof(data["flags"][key]) == TYPE_BOOL:
				new_flags[str(key)] = data["flags"][key]
	character_id = new_id if CHARACTER_IDS.has(new_id) else ""
	character_name = new_name if new_name.length() <= NAME_MAX_LENGTH else ""
	flags = new_flags

	# Materials (SVTLW-56) are optional so saves from before the economy story load with zeros.
	var new_materials: Dictionary = {}
	for material: String in MATERIAL_IDS:
		var value: Variant = data.get(material, 0)
		new_materials[material] = int(value) if _is_non_negative_whole(value) else 0

	# Production (SVTLW-55) is optional so saves from before the production story load with none.
	var new_production: Dictionary = {}
	var raw_production: Variant = data.get("production", {})
	if typeof(raw_production) == TYPE_DICTIONARY:
		for key: Variant in raw_production:
			var level: Variant = raw_production[key]
			if typeof(key) == TYPE_STRING and _is_non_negative_whole(level) and int(level) >= 1:
				new_production[key] = int(level)

	# Wall tier (SVTLW-63) is optional so saves from before the tier story load as tier 1.
	var new_tier: int = 1
	var raw_tier: Variant = data.get("wall_tier", 1)
	if _is_non_negative_whole(raw_tier) and int(raw_tier) >= 1:
		new_tier = mini(int(raw_tier), MAX_WALL_TIER)

	# Prestige fields (SVTLW-73, SVTLW-74) are optional so older saves load with no relics and no path.
	var new_relics: int = _whole_or_zero(data.get("relics", 0))
	var new_prestige_count: int = _whole_or_zero(data.get("prestige_count", 0))
	var raw_path: String = str(data.get("prestige_path", ""))
	var new_relic_levels: Dictionary = {}
	var raw_levels: Variant = data.get("relic_levels", {})
	if typeof(raw_levels) == TYPE_DICTIONARY:
		for key: Variant in raw_levels:
			if typeof(key) == TYPE_STRING and _is_non_negative_whole(raw_levels[key]) and int(raw_levels[key]) >= 1:
				new_relic_levels[key] = int(raw_levels[key])
	# Instability (SVTLW-69) is optional; missing or invalid values load as 0.
	var new_instability: float = SimulationInstability.sanitize_value(data.get("instability", 0.0))
	# Research (SVTLW-61) is optional so saves from before the research story load with zero points.
	var new_research: Dictionary = {"points": 0, "researched": []}
	var raw_research: Variant = data.get("research", {})
	if typeof(raw_research) == TYPE_DICTIONARY:
		var points: Variant = raw_research.get("points", 0)
		if _is_non_negative_whole(points):
			new_research["points"] = int(points)
		var ids: Variant = raw_research.get("researched", [])
		if typeof(ids) == TYPE_ARRAY:
			for id: Variant in ids:
				if typeof(id) == TYPE_STRING and not new_research["researched"].has(id):
					new_research["researched"].append(id)


	# Post-game cycles (SVTLW-85) are optional so older saves load with zero, and clamped to the maximum.
	var new_cycles: int = 0
	var raw_cycles: Variant = data.get("post_game_cycles", 0)
	if _is_non_negative_whole(raw_cycles):
		new_cycles = mini(int(raw_cycles), MAX_POST_GAME_CYCLES)
	# Stats and achievements (SVTLW-78) are optional; invalid values fall back to zeros and no unlocks.
	stats.from_dict(data.get("stats", {}))
	achievements.set_unlocked(data.get("achievements", []))

	gold = int(data["gold"])
	instability = new_instability
	research = new_research
	relics = new_relics
	prestige_count = new_prestige_count
	prestige_path = raw_path if PATH_IDS.has(raw_path) else ""
	relic_levels = new_relic_levels
	# Offline progress fields (SVTLW-75) are optional so older saves load with defaults.
	var new_saved_unix: int = 0
	var raw_saved: Variant = data.get("last_saved_unix", 0)
	if _is_non_negative_whole(raw_saved):
		new_saved_unix = int(raw_saved)
	var new_offline: bool = typeof(data.get("offline_enabled", true)) == TYPE_BOOL and bool(data.get("offline_enabled", true))

	last_saved_unix = new_saved_unix
	offline_enabled = new_offline
	wall_tier = new_tier
	post_game_cycles = new_cycles
	production_levels = new_production
	wood = new_materials["wood"]
	stone = new_materials["stone"]
	iron = new_materials["iron"]
	current_wave = int(data["wave"])
	wall_max_health = new_max
	wall_health = new_health
	resources_changed.emit(gold)
	_emit_materials()
	wave_changed.emit(current_wave)
	wall_health_changed.emit(wall_health)
	return true


func _whole_or_zero(value: Variant) -> int:
	return int(value) if _is_non_negative_whole(value) else 0


func _is_non_negative_whole(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return number >= 0.0 and is_equal_approx(number, floor(number))
