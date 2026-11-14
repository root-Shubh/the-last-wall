## One archer defender (SVTLW-31). Targets the closest enemy in range on ticks and asks the
## pool to fire. Damage is computed by DamageCalculator with an injected random source.
class_name Archer
extends Node2D

signal died(archer: Archer)
signal fire_requested(origin: Vector2, target: Enemy, damage: float)

var definition: UnitDefinition
var health: float = 0.0
var alive: bool = false
## Set from upgrades (SVTLW-39). 1.0 means no change.
var damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
## Targeting (SVTLW-58). The default CLOSEST keeps the original behaviour.
var targeting_mode: int = Targeting.Mode.CLOSEST
var priority_id_for_mode: String = ""
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
	var interval: int = maxi(roundi(definition.attack_interval_ticks / maxf(attack_speed_multiplier, 0.01)), 1)
	if _ticks_since_shot < interval:
		return
	var target: Enemy = select_target(enemies)
	if target == null:
		return
	_ticks_since_shot = 0
	var roll: float = _rng.randf()
	var damage: float = DamageCalculator.calculate(
		definition.base_damage, damage_multiplier, definition.crit_chance, definition.crit_multiplier,
		maxf(target.definition.armour - definition.armour_penetration, 0.0), 1.0, roll)
	fire_requested.emit(global_position, target, damage)


## Sets how this archer chooses targets (SVTLW-58). priority_id is only used by PRIORITY_TYPE.
func set_targeting_mode(mode: int, priority_id: String = "") -> void:
	targeting_mode = mode
	priority_id_for_mode = priority_id


## Target chosen by targeting_mode among the enemies in range, or null.
func select_target(enemies: Array) -> Enemy:
	return Targeting.select(targeting_mode, enemies, global_position, definition.attack_range, priority_id_for_mode)


## Kept for existing callers and tests. Equals select_target; the default mode is CLOSEST.
func closest_in_range(enemies: Array) -> Enemy:
	return select_target(enemies)


func take_damage(amount: float) -> void:
	if not alive:
		return
	health -= maxf(amount, 0.0)
	if health <= 0.0:
		health = 0.0
		alive = false
		died.emit(self)
