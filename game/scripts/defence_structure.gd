## One built defensive structure (SVTLW-54): a tower or an archer platform on a construction slot.
## Fires at the closest enemy in range on its own interval, like Archer. Shots go out through
## fire_requested so the battlefield can route them to the projectile pool. Spending gold to
## upgrade is the caller's job; upgrade() only changes level, damage and interval.
class_name DefenceStructure
extends Node2D

signal fire_requested(origin: Vector2, target: Enemy, damage: float)
signal level_changed(level: int)

## Damage rises by this fraction of base damage for each level above 1.
const DAMAGE_STEP_PER_LEVEL: float = 0.5
## Interval is multiplied by this for each level above 1 (0.8 means 20 percent faster per level).
const INTERVAL_FACTOR_PER_LEVEL: float = 0.8
## Visual scale grows by this much per level above 1.
const VISUAL_STEP_PER_LEVEL: float = 0.25
const DEFAULT_MAX_LEVEL: int = 3

var definition: BuildingDefinition = null
var building_id: String = ""
var slot: int = -1
var level: int = 1
var max_level: int = DEFAULT_MAX_LEVEL
var _ticks_since_shot: int = 0


## Visual: a block for each structure, larger with each upgrade level (SVTLW-54 gap: no visual before).
func _draw() -> void:
	var side: float = 32.0 * visual_scale_for_level(level)
	var art_name: String = "tower" if building_id == "tower" else "archer_platform"
	draw_texture_rect(SpriteArt.texture(art_name), Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side)), false)


func _process(_delta: float) -> void:
	queue_redraw()


## Prepares the structure for a completed build. Must be called before the first tick.
func setup(data: BuildingDefinition, on_slot: int, at: Vector2) -> void:
	definition = data
	building_id = data.building_id
	slot = on_slot
	position = at
	level = 1
	max_level = data.max_level if data.max_level > 0 else DEFAULT_MAX_LEVEL
	_ticks_since_shot = 0


## True when the building has all the attack fields set. Zero fields mean it is not a defence.
func is_defence() -> bool:
	return definition != null and definition.attack_damage > 0.0 \
		and definition.attack_interval_ticks > 0 and definition.attack_range > 0.0


## Damage per shot at a level. Pure, so tests can check the numbers without firing.
func damage_for_level(at_level: int) -> float:
	if not is_defence():
		return 0.0
	return definition.attack_damage * (1.0 + DAMAGE_STEP_PER_LEVEL * float(at_level - 1))


## Ticks between shots at a level, never below one tick.
func interval_for_level(at_level: int) -> int:
	if not is_defence():
		return 0
	var scaled: float = definition.attack_interval_ticks * pow(INTERVAL_FACTOR_PER_LEVEL, at_level - 1)
	return maxi(roundi(scaled), 1)


## Visual scale for a placeholder rect at a level. 1.0 at level 1.
func visual_scale_for_level(at_level: int) -> float:
	return 1.0 + VISUAL_STEP_PER_LEVEL * float(at_level - 1)


## Raises the level by one. Returns false at max level or for a building that is not a defence.
func upgrade() -> bool:
	if not is_defence() or level >= max_level:
		return false
	level += 1
	level_changed.emit(level)
	return true


## enemies: the living enemies on the battlefield, supplied by the manager each tick.
func on_tick(_tick_index: int, enemies: Array) -> void:
	if not is_defence():
		return
	_ticks_since_shot += 1
	if _ticks_since_shot < interval_for_level(level):
		return
	var target: Enemy = closest_in_range(enemies)
	if target == null:
		return
	_ticks_since_shot = 0
	# Crit and armour-piercing are not part of this story, so the roll is fixed and crit is off.
	var damage: float = DamageCalculator.calculate(
		damage_for_level(level), 1.0, 0.0, 1.0,
		maxf(target.definition.armour, 0.0), 1.0, 1.0)
	fire_requested.emit(global_position, target, damage)


func closest_in_range(enemies: Array) -> Enemy:
	var best: Enemy = null
	var best_distance: float = definition.attack_range if definition != null else 0.0
	for candidate: Variant in enemies:
		var enemy: Enemy = candidate
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best
