## Global game state: gold, current wave and wall health.
## Autoload name: GameState. Spending rules are expanded in SVTLW-38 (economy ledger).
extends Node

signal resources_changed(gold: int)
signal wave_changed(wave: int)
signal wall_health_changed(health: int)

const DEFAULT_WALL_MAX_HEALTH: int = 100

var gold: int = 0
var current_wave: int = 0
var wall_max_health: int = DEFAULT_WALL_MAX_HEALTH
var wall_health: int = DEFAULT_WALL_MAX_HEALTH


## Restores every value to a new game.
func reset() -> void:
	gold = 0
	current_wave = 0
	wall_max_health = DEFAULT_WALL_MAX_HEALTH
	wall_health = wall_max_health
	resources_changed.emit(gold)
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
	return true


func damage_wall(amount: int) -> void:
	wall_health = maxi(wall_health - maxi(amount, 0), 0)
	wall_health_changed.emit(wall_health)


func repair_wall(amount: int) -> void:
	wall_health = mini(wall_health + maxi(amount, 0), wall_max_health)
	wall_health_changed.emit(wall_health)


func is_wall_destroyed() -> bool:
	return wall_health <= 0


func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"wave": current_wave,
		"wall_health": wall_health,
		"wall_max_health": wall_max_health,
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

	gold = int(data["gold"])
	current_wave = int(data["wave"])
	wall_max_health = new_max
	wall_health = new_health
	resources_changed.emit(gold)
	wave_changed.emit(current_wave)
	wall_health_changed.emit(wall_health)
	return true


func _is_non_negative_whole(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return number >= 0.0 and is_equal_approx(number, floor(number))
