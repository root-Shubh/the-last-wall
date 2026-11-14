## One archer defender (SVTLW-31). Targets the closest enemy in range on ticks and asks the
## pool to fire. Damage is computed by DamageCalculator with an injected random source.
class_name Archer
extends Node2D

signal died(archer: Archer)
signal fire_requested(origin: Vector2, target: Enemy, damage: float)

var definition: UnitDefinition
var health: float = 0.0
var alive: bool = false
var _ticks_since_shot: int = 0
var _rng: RandomNumberGenerator = null


func setup(data: UnitDefinition, at: Vector2, rng: RandomNumberGenerator) -> void:
	definition = data
	health = data.max_health
	alive = true
	position = at
	_ticks_since_shot = 0
	_rng = rng


## enemies: the living enemies on the battlefield, supplied by the manager each tick.
func on_tick(_tick_index: int, enemies: Array) -> void:
	if not alive or definition == null:
		return
	_ticks_since_shot += 1
	if _ticks_since_shot < definition.attack_interval_ticks:
		return
	var target: Enemy = closest_in_range(enemies)
	if target == null:
		return
	_ticks_since_shot = 0
	var roll: float = _rng.randf()
	var damage: float = DamageCalculator.calculate(
		definition.base_damage, 1.0, definition.crit_chance, definition.crit_multiplier,
		target.definition.armour, 1.0, roll)
	fire_requested.emit(global_position, target, damage)


func closest_in_range(enemies: Array) -> Enemy:
	var best: Enemy = null
	var best_distance: float = definition.attack_range
	for candidate: Variant in enemies:
		var enemy: Enemy = candidate
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


func take_damage(amount: float) -> void:
	if not alive:
		return
	health -= maxf(amount, 0.0)
	if health <= 0.0:
		health = 0.0
		alive = false
		died.emit(self)
