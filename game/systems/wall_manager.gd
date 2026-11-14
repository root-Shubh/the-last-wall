## Wall health, armour, repair and damage states (SVTLW-29, SVTLW-30).
## Health lives in GameState so saves and the HUD read one value. This node applies armour,
## runs repair on ticks, and turns health into a visual damage state.
class_name WallManager
extends Node

enum DamageState { INTACT, CRACKED, DAMAGED, CRITICAL, DESTROYED }

signal damage_state_changed(state: DamageState)
signal wall_destroyed

## Flat damage reduction applied to every attack on the wall.
@export var armour: float = 1.0
## Health restored per real second while the wall stands.
@export var repair_per_second: float = 0.0

var state: Node = null
var _state_value: DamageState = DamageState.INTACT
var _repair_accumulator: float = 0.0
var _destroyed: bool = false


## Pure mapping from health to damage state, so the thresholds are testable without a scene.
static func state_for(health: int, max_health: int) -> DamageState:
	if health <= 0:
		return DamageState.DESTROYED
	var ratio: float = float(health) / float(maxi(max_health, 1))
	if ratio <= 0.25:
		return DamageState.CRITICAL
	if ratio <= 0.5:
		return DamageState.DAMAGED
	if ratio <= 0.75:
		return DamageState.CRACKED
	return DamageState.INTACT


## Connects to a gold and health source. Pass GameState explicitly.
func bind(health_source: Node) -> void:
	state = health_source
	state.wall_health_changed.connect(_on_health_changed)
	_refresh_state()


func current_state() -> DamageState:
	return _state_value


func is_destroyed() -> bool:
	return _destroyed


## Applies an incoming attack after armour. Damage is rounded to whole health.
func attack(amount: float) -> void:
	if _destroyed or state == null:
		return
	var roll_without_crit: float = 1.0
	var dealt: float = DamageCalculator.calculate(amount, 1.0, 0.0, 1.0, armour, 1.0, roll_without_crit)
	state.damage_wall(roundi(dealt))


## Repair runs on simulation ticks so pausing also pauses repair.
func on_tick(_tick_index: int) -> void:
	if _destroyed or state == null or repair_per_second <= 0.0:
		return
	_repair_accumulator += repair_per_second / SimulationClock.TICKS_PER_SECOND
	var whole: int = int(_repair_accumulator)
	if whole > 0:
		_repair_accumulator -= whole
		state.repair_wall(whole)


func _on_health_changed(_health: int) -> void:
	_refresh_state()


func _refresh_state() -> void:
	var health: int = state.wall_health
	var max_health: int = state.wall_max_health
	var next: DamageState = state_for(health, max_health)
	if next != _state_value:
		_state_value = next
		damage_state_changed.emit(next)
	if next == DamageState.DESTROYED and not _destroyed:
		_destroyed = true
		wall_destroyed.emit()
