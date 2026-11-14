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
## Specialisation (SVTLW-62). At most one per archer. range_multiplier scales attack_range,
## armour_penetration_bonus adds to the base penetration. Defaults leave behaviour unchanged.
var specialisation: SpecialisationDefinition = null
var range_multiplier: float = 1.0
var armour_penetration_bonus: float = 0.0
var _upgrade_damage: float = 1.0
var _upgrade_speed: float = 1.0
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
	if _ticks_since_shot < attack_interval_ticks():
		return
	var target: Enemy = select_target(enemies)
	if target == null:
		return
	_ticks_since_shot = 0
	var roll: float = _rng.randf()
	var damage: float = DamageCalculator.calculate(
		definition.base_damage, damage_multiplier, definition.crit_chance, definition.crit_multiplier,
		maxf(target.definition.armour - effective_penetration(), 0.0), 1.0, roll)
	fire_requested.emit(global_position, target, damage)


## Ticks between shots after attack speed (SVTLW-62). Equals the base interval when no specialisation.
func attack_interval_ticks() -> int:
	return maxi(roundi(definition.attack_interval_ticks / maxf(attack_speed_multiplier, 0.01)), 1)


## attack_range after the specialisation range multiplier.
func effective_range() -> float:
	return definition.attack_range * range_multiplier


## Base armour penetration plus the specialisation bonus.
func effective_penetration() -> float:
	return definition.armour_penetration + armour_penetration_bonus


## Upgrade multipliers from UnitManager (SVTLW-39). The specialisation factor is kept on top of them.
func set_upgrade_multipliers(damage: float, speed: float) -> void:
	_upgrade_damage = damage
	_upgrade_speed = speed
	_refresh_multipliers()


## Applies a specialisation (SVTLW-62). Refused if the archer already has one or the unit_id does not match.
## Returns true when applied. Base unit data is never changed.
func apply_specialisation(spec: SpecialisationDefinition) -> bool:
	if spec == null or definition == null or specialisation != null:
		return false
	if spec.unit_id != definition.unit_id:
		return false
	specialisation = spec
	range_multiplier = spec.range_multiplier
	armour_penetration_bonus = spec.armour_penetration_bonus
	_refresh_multipliers()
	return true


func specialisation_id() -> String:
	return specialisation.specialisation_id if specialisation != null else ""


func _refresh_multipliers() -> void:
	var spec_damage: float = specialisation.damage_multiplier if specialisation != null else 1.0
	var spec_speed: float = specialisation.attack_speed_multiplier if specialisation != null else 1.0
	damage_multiplier = _upgrade_damage * spec_damage
	attack_speed_multiplier = _upgrade_speed * spec_speed


## Sets how this archer chooses targets (SVTLW-58). priority_id is only used by PRIORITY_TYPE.
func set_targeting_mode(mode: int, priority_id: String = "") -> void:
	targeting_mode = mode
	priority_id_for_mode = priority_id


## Target chosen by targeting_mode among the enemies in range, or null.
func select_target(enemies: Array) -> Enemy:
	return Targeting.select(targeting_mode, enemies, global_position, effective_range(), priority_id_for_mode)


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
