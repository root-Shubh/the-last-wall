## Runs waves from a WaveCatalog on the simulation clock (SVTLW-26).
## Emits enemy_spawn_requested for the enemy system to act on. It never creates enemies itself.
## A wave completes when every enemy has spawned and every spawned enemy has been reported dead.
class_name WaveManager
extends Node

signal wave_started(wave_number: int)
signal enemy_spawn_requested(enemy_type_id: String)
signal wave_completed(wave_number: int)
signal all_waves_completed

@export var catalog: WaveCatalog
## Optional (SVTLW-59). When set, waves come from the generator and the catalog is ignored.
@export var generator: WaveGenerator
@export var auto_start: bool = false

var current_wave: int = 0
var _definition: WaveDefinition = null
var _spawned: int = 0
var _alive: int = 0
var _ticks_since_spawn: int = 0
var _running: bool = false


## Starts the next wave in the catalog. Returns false if a wave is running or none remain.
func start_next_wave() -> bool:
	if _running or (catalog == null and generator == null):
		return false
	var next_number: int = current_wave + 1
	var definition: WaveDefinition = _get_definition(next_number)
	if definition == null:
		all_waves_completed.emit()
		return false

	current_wave = next_number
	_definition = definition
	_spawned = 0
	_alive = 0
	_ticks_since_spawn = 0
	_running = true
	wave_started.emit(current_wave)
	# An empty wave has nothing to spawn or kill, so it completes straight away.
	if definition.enemy_count <= 0:
		_check_complete()
	return true


func _get_definition(wave_number: int) -> WaveDefinition:
	if generator != null:
		var generated: WaveDefinition = generator.generate(wave_number)
		if generated != null:
			return generated
	if catalog == null:
		return null
	return catalog.get_wave(wave_number)


## Called on each simulation tick, usually from the battlefield's SimulationClock.
func on_tick(_tick_index: int) -> void:
	if not _running or _definition == null:
		return
	if _spawned >= _definition.enemy_count:
		return
	_ticks_since_spawn += 1
	if _ticks_since_spawn < _definition.spawn_interval_ticks:
		return
	_ticks_since_spawn = 0
	_spawned += 1
	_alive += 1
	enemy_spawn_requested.emit(_definition.enemy_type_id)


## Called by the enemy system when an enemy dies or reaches the wall.
func report_enemy_removed() -> void:
	if not _running:
		return
	_alive = maxi(_alive - 1, 0)
	_check_complete()


func is_running() -> bool:
	return _running


func _check_complete() -> void:
	if _definition == null:
		return
	if _spawned >= _definition.enemy_count and _alive == 0:
		_running = false
		wave_completed.emit(current_wave)
		if auto_start:
			start_next_wave()
