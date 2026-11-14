## Spawns and tracks enemies (SVTLW-33). Receives spawn requests from WaveManager
## and reports every enemy that leaves the battlefield, by death or by reaching the wall.
class_name EnemyManager
extends Node2D

signal enemy_removed(enemy: Enemy)
signal wall_attacked(damage: float)

@export var definitions: Array[EnemyDefinition] = []
@export var spawn_x: float = 1180.0
@export var wall_stop_x: float = 230.0

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
	enemy.setup(_by_id[enemy_id], spawn_x, wall_stop_x)
	enemy.died.connect(_on_enemy_left)
	enemy.reached_wall.connect(_on_reached_wall)
	enemy.attacked_wall.connect(_on_attacked_wall)
	enemies.append(enemy)
	return enemy


func on_tick(tick_index: int) -> void:
	for enemy: Enemy in enemies.duplicate():
		enemy.on_tick(tick_index)


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


func _on_attacked_wall(_enemy: Enemy, damage: float) -> void:
	wall_attacked.emit(damage)


func _remove(enemy: Enemy) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	enemy_removed.emit(enemy)
	enemy.queue_free()
