## One enemy on the battlefield (SVTLW-33). Moves and attacks on simulation ticks, not frames.
## Reports what happened through signals. Removal and wave bookkeeping belong to EnemyManager.
class_name Enemy
extends Node2D

signal died(enemy: Enemy)
signal reached_wall(enemy: Enemy)
signal attacked_wall(enemy: Enemy, damage: float)

var definition: EnemyDefinition
var health: float = 0.0
var alive: bool = false
var at_wall: bool = false
var _wall_stop_x: float = 0.0
var _ticks_since_attack: int = 0


## Prepares the enemy for the battlefield. Must be called before the first tick.
func setup(data: EnemyDefinition, start_x: float, wall_stop_x: float, lane_y: float = 0.0) -> void:
	definition = data
	health = data.max_health
	alive = true
	at_wall = false
	_ticks_since_attack = 0
	_wall_stop_x = wall_stop_x
	position = Vector2(start_x, lane_y)


## Advances one simulation tick: walk until the wall, then attack on the interval.
func on_tick(_tick_index: int) -> void:
	if not alive or definition == null:
		return
	if not at_wall:
		var step: float = definition.move_speed / SimulationClock.TICKS_PER_SECOND
		position.x = maxf(position.x - step, _wall_stop_x)
		if position.x <= _wall_stop_x:
			at_wall = true
			reached_wall.emit(self)
		return

	_ticks_since_attack += 1
	if _ticks_since_attack >= definition.attack_interval_ticks:
		_ticks_since_attack = 0
		attacked_wall.emit(self, definition.wall_damage)


## True when a defender of this id may stop this enemy (SVTLW-57). Most enemies can be stopped
## by anything; melee_counter_only enemies (climbers) only by melee defenders.
func can_be_stopped_by(defender_id: String) -> bool:
	if definition == null:
		return false
	if not definition.melee_counter_only:
		return true
	return EnemyDefinition.MELEE_DEFENDER_IDS.has(defender_id)


## Applies final damage (already computed by DamageCalculator). Dies once; later hits do nothing.
func take_damage(amount: float) -> void:
	if not alive:
		return
	health -= maxf(amount, 0.0)
	if health <= 0.0:
		health = 0.0
		alive = false
		died.emit(self)
