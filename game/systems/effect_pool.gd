## Pooled visual effects (SVTLW-60): impact flashes and area explosions. Placeholders only (ColorRect).
## Pre-allocates nodes and recycles them, so spawning never creates nodes after warm-up. Effects age
## by simulation tick, so they stay in step with the battle clock.
class_name EffectPool
extends Node2D

const IMPACT_TICKS: int = 3
const EXPLOSION_TICKS: int = 6
const IMPACT_SIZE: float = 12.0
const IMPACT_COLOR: Color = Color(1.0, 0.95, 0.6, 1.0)
const EXPLOSION_COLOR: Color = Color(1.0, 0.5, 0.15, 0.7)

@export var initial_size: int = 32

var total_created: int = 0
var _idle: Array[ColorRect] = []
## Each entry: {"node": ColorRect, "age": int, "life": int, "kind": String, "radius": float}.
var _active: Array[Dictionary] = []
var _warmed: bool = false


func _ready() -> void:
	_warm()


## Creates the pool's nodes once. Runs from _ready and on first use, because _ready is not
## guaranteed to run for nodes added during a SceneTree script.
func _warm() -> void:
	if _warmed:
		return
	_warmed = true
	for i: int in range(initial_size):
		_create()


## Brief flash at a point. Fades out after IMPACT_TICKS ticks.
func spawn_impact(at: Vector2) -> void:
	var node: ColorRect = _take()
	node.color = IMPACT_COLOR
	node.size = Vector2(IMPACT_SIZE, IMPACT_SIZE)
	node.pivot_offset = node.size * 0.5
	node.position = at - node.size * 0.5
	node.scale = Vector2.ONE
	node.modulate.a = 1.0
	_active.append({"node": node, "age": 0, "life": IMPACT_TICKS, "kind": "impact", "radius": IMPACT_SIZE * 0.5})


## Circle placeholder that grows to the radius and fades out after EXPLOSION_TICKS ticks.
func spawn_explosion(at: Vector2, radius: float) -> void:
	var node: ColorRect = _take()
	var diameter: float = maxf(radius, 1.0) * 2.0
	node.color = EXPLOSION_COLOR
	node.size = Vector2(diameter, diameter)
	node.pivot_offset = node.size * 0.5
	node.position = at - node.size * 0.5
	node.modulate.a = 1.0
	_active.append({"node": node, "age": 0, "life": EXPLOSION_TICKS, "kind": "explosion", "radius": radius})
	_apply_progress(_active[-1])


## Advances every active effect by one tick and recycles the ones that have expired.
func on_tick(_tick_index: int) -> void:
	for effect: Dictionary in _active.duplicate():
		effect["age"] = int(effect["age"]) + 1
		if int(effect["age"]) >= int(effect["life"]):
			_release(effect)
		else:
			_apply_progress(effect)


func active_count() -> int:
	return _active.size()


func idle_count() -> int:
	return _idle.size()


func _take() -> ColorRect:
	_warm()
	if _idle.is_empty():
		push_warning("EffectPool: grew beyond initial size (%d)" % initial_size)
		_create()
	var node: ColorRect = _idle.pop_back()
	node.visible = true
	return node


func _create() -> void:
	var node: ColorRect = ColorRect.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	node.visible = false
	total_created += 1
	_idle.append(node)


func _release(effect: Dictionary) -> void:
	var node: ColorRect = effect["node"]
	node.visible = false
	_active.erase(effect)
	_idle.append(node)


## Impacts stay put and fade. Explosions grow from 30% to full radius while fading.
func _apply_progress(effect: Dictionary) -> void:
	var node: ColorRect = effect["node"]
	var progress: float = float(effect["age"]) / float(effect["life"])
	node.modulate.a = 1.0 - progress
	if String(effect["kind"]) == "explosion":
		node.scale = Vector2.ONE * lerpf(0.3, 1.0, progress)
