## Spawns and tracks enemies (SVTLW-33). Receives spawn requests from WaveManager
## and reports every enemy that leaves the battlefield, by death or by reaching the wall.
class_name EnemyManager
extends Node2D

signal enemy_removed(enemy: Enemy)
signal wall_attacked(damage: float)
## Attacks from climbers (bypass_wall_armour). WallManager must apply no armour to these (SVTLW-57).
signal wall_attacked_unarmoured(damage: float)

@export var definitions: Array[EnemyDefinition] = []
@export var spawn_x: float = 1180.0
@export var wall_stop_x: float = 230.0
## Y coordinate of the enemy lane. Archers must be within range of this line to fire at enemies.
@export var lane_y: float = 360.0

var enemies: Array[Enemy] = []
var _by_id: Dictionary = {}


func _ready() -> void:
	_rebuild_index()


## Returns the spawned enemy, or null when the id is unknown.
func spawn(enemy_id: String) -> Enemy:
	if _by_id.is_empty():
		_rebuild_index()
	if not _by_id.has(enemy_id):
		push_warning("EnemyManager: unknown enemy id '%s'" % enemy_id)
		return null

	var enemy: Enemy = Enemy.new()
	add_child(enemy)
	enemy.setup(_by_id[enemy_id], spawn_x, wall_stop_x, lane_y)
	enemy.died.connect(_on_enemy_left)
	enemy.reached_wall.connect(_on_reached_wall)
	enemy.attacked_wall.connect(_on_attacked_wall)
	enemies.append(enemy)
	return enemy


## Index loop over the live array: no copy per tick (SVTLW-90). Stops early if a signal handler
## removed enemies during the tick, so a shrinking array never reads past its end.
func on_tick(tick_index: int) -> void:
	var count: int = enemies.size()
	for i: int in range(count):
		if i >= enemies.size():
			break
		enemies[i].on_tick(tick_index)


## Applies damage to an enemy after allied shields (SVTLW-57). Returns the damage actually dealt.
## Battlefield damage to enemies should go through here so shield bearers take effect.
func damage_enemy(target: Enemy, amount: float) -> float:
	if target == null or not target.alive:
		return 0.0
	var dealt: float = maxf(amount, 0.0) * (1.0 - shield_fraction_for(target))
	target.take_damage(dealt)
	return dealt


## Strongest shield fraction from living bearers whose radius covers target. Bearers do not shield themselves.
func shield_fraction_for(target: Enemy) -> float:
	var best: float = 0.0
	for bearer: Enemy in enemies:
		if bearer == target or not bearer.alive or bearer.definition == null:
			continue
		var data: EnemyDefinition = bearer.definition
		if data.shield_radius <= 0.0 or data.shield_fraction <= 0.0:
			continue
		if bearer.position.distance_to(target.position) <= data.shield_radius:
			best = maxf(best, data.shield_fraction)
	return best


func living_count() -> int:
	return enemies.size()


func _rebuild_index() -> void:
	_by_id.clear()
	for definition: EnemyDefinition in definitions:
		_by_id[definition.enemy_id] = definition


func _on_enemy_left(enemy: Enemy) -> void:
	_remove(enemy)


func _on_reached_wall(enemy: Enemy) -> void:
	# An enemy that reaches the wall keeps attacking until it dies, so it is not removed here.
	pass


func _on_attacked_wall(enemy: Enemy, damage: float) -> void:
	if enemy.definition != null and enemy.definition.bypass_wall_armour:
		wall_attacked_unarmoured.emit(damage)
	else:
		wall_attacked.emit(damage)


func _remove(enemy: Enemy) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	enemy_removed.emit(enemy)
	enemy.queue_free()
