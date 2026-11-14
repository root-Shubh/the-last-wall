## Reusable pool of projectiles (SVTLW-36). Pre-allocates at start and recycles, so shots
## do not create or free nodes. Grows only when every projectile is busy, and logs it.
class_name ProjectilePool
extends Node2D

signal projectile_hit(target: Enemy, damage: float)

@export var initial_size: int = 64

var _idle: Array[Projectile] = []
var _active: Array[Projectile] = []
var total_created: int = 0
var _warmed: bool = false


func _ready() -> void:
	_warm()


## Creates the pool's projectiles once. Runs from _ready and on first use, because _ready is not
## guaranteed to run for nodes added during a SceneTree script.
func _warm() -> void:
	if _warmed:
		return
	_warmed = true
	for i: int in range(initial_size):
		_create()


## Launches a projectile from origin at an enemy. Returns null when no target is given.
func fire(origin: Vector2, target: Enemy, damage: float) -> Projectile:
	if target == null:
		return null
	_warm()
	if _idle.is_empty():
		push_warning("ProjectilePool: grew beyond initial size (%d)" % initial_size)
		_create()
	var projectile: Projectile = _idle.pop_back()
	_active.append(projectile)
	projectile.launch(origin, target, damage)
	return projectile


func on_tick(tick_index: int) -> void:
	for projectile: Projectile in _active.duplicate():
		projectile.on_tick(tick_index)


func active_count() -> int:
	return _active.size()


func idle_count() -> int:
	return _idle.size()


func _create() -> void:
	var projectile: Projectile = Projectile.new()
	add_child(projectile)
	projectile.visible = false
	projectile.hit.connect(_on_hit)
	projectile.expired.connect(_on_done)
	total_created += 1
	_idle.append(projectile)


func _on_hit(target: Enemy, damage: float) -> void:
	_release_current()
	projectile_hit.emit(target, damage)


func _on_done(_projectile: Projectile) -> void:
	_release_current()


func _release_current() -> void:
	# Return every projectile that is no longer in flight to the idle list.
	for projectile: Projectile in _active.duplicate():
		if not projectile.in_flight:
			_active.erase(projectile)
			_idle.append(projectile)
