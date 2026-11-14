## One pooled projectile (SVTLW-36). Flies toward an enemy on simulation ticks and reports the hit.
## Reused by ProjectilePool, never freed per shot.
class_name Projectile
extends Node2D

signal hit(target: Enemy, damage: float)
signal expired(projectile: Projectile)

## World pixels per tick.
const SPEED_PER_TICK: float = 12.0
const HIT_DISTANCE: float = 8.0

var target: Enemy = null
var damage: float = 0.0
var in_flight: bool = false
## True for shots from defence structures: a hit there also raises an explosion (SVTLW-100).
var explosive: bool = false


func launch(origin: Vector2, aim_at: Enemy, amount: float) -> void:
	global_position = origin
	target = aim_at
	damage = amount
	in_flight = true
	visible = true


## Moves one tick. Hits when close enough; expires if the target is gone.
func on_tick(_tick_index: int) -> void:
	if not in_flight:
		return
	if target == null or not is_instance_valid(target) or not target.alive:
		_expire()
		return
	var to_target: Vector2 = target.global_position - global_position
	if to_target.length() <= HIT_DISTANCE:
		var struck: Enemy = target
		var amount: float = damage
		_finish()
		hit.emit(struck, amount)
		return
	global_position += to_target.normalized() * minf(SPEED_PER_TICK, to_target.length())


func _expire() -> void:
	_finish()
	expired.emit(self)


func _finish() -> void:
	in_flight = false
	visible = false
	target = null
