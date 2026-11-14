## Draws the fortress for the battle: the wall by tier (floors appear as the wall is upgraded), the
## commander on the wall, production buildings, and buildings under construction with a progress bar.
## Defence structures draw themselves (DefenceStructure). Everything here is read-only game state.
class_name BattleView
extends Node2D

const GROUND_Y: float = 560.0
const WALL_LEFT: float = 96.0
const WALL_WIDTH: float = 110.0
const FLOOR_BASE: float = 110.0
const FLOOR_STEP: float = 46.0
const SLOT_SIZE: float = 30.0

var field: Battlefield = null

## Colours per building id, for production buildings and sites.
const BUILDING_COLOURS: Dictionary = {
	"lumber_mill": Color(0.42, 0.3, 0.16),
	"quarry": Color(0.5, 0.5, 0.52),
	"iron_mine": Color(0.36, 0.36, 0.42),
}


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if field == null or field.game_state == null:
		return
	_draw_wall()
	_draw_commander()
	_draw_buildings()


## Wall height and floors follow the wall tier (SVTLW-63). Tier 1 is a short palisade.
func _draw_wall() -> void:
	var tier: int = clampi(int(field.game_state.wall_tier), 1, 7)
	var height: float = FLOOR_BASE + FLOOR_STEP * float(tier - 1)
	var top: float = GROUND_Y - height
	var colour: Color = Color(0.5, 0.38, 0.26).lerp(Color(0.62, 0.62, 0.66), float(tier - 1) / 6.0)
	draw_rect(Rect2(WALL_LEFT, top, WALL_WIDTH, height), colour)
	# Each floor after the first is a band with a crenellated top.
	for floor_index: int in range(1, tier):
		var y: float = GROUND_Y - FLOOR_STEP * float(floor_index)
		draw_line(Vector2(WALL_LEFT, y), Vector2(WALL_LEFT + WALL_WIDTH, y), colour.darkened(0.35), 2.0)
	for merlon: int in range(4):
		draw_rect(Rect2(WALL_LEFT + 4.0 + float(merlon) * 27.0, top - 8.0, 16.0, 8.0), colour)
	draw_rect(Rect2(WALL_LEFT, top, WALL_WIDTH, height), colour.darkened(0.4), false, 2.0)


## The player's commander stands on top of the wall (SVTLW-42, the chosen character).
func _draw_commander() -> void:
	var tier: int = clampi(int(field.game_state.wall_tier), 1, 7)
	var top: float = GROUND_Y - (FLOOR_BASE + FLOOR_STEP * float(tier - 1)) - 8.0
	var x: float = WALL_LEFT + WALL_WIDTH * 0.5
	var cloak: Color = Color(0.2, 0.3, 0.45)
	draw_rect(Rect2(x - 7.0, top - 22.0, 14.0, 22.0), cloak)
	draw_circle(Vector2(x, top - 27.0), 6.0, Color(0.85, 0.7, 0.55))
	draw_rect(Rect2(x - 8.0, top - 33.0, 16.0, 4.0), Color(0.25, 0.2, 0.15))


## Production buildings and construction sites. Defence structures are drawn by their own node.
func _draw_buildings() -> void:
	var completed: Array = field.constructions.completed_list()
	for entry: Variant in completed:
		var building_id: String = str(entry["building_id"])
		if building_id in ["tower", "archer_platform"]:
			continue
		var slot: int = int(entry["slot"])
		var at: Vector2 = Battlefield.SLOT_POSITIONS[slot]
		var colour: Color = BUILDING_COLOURS.get(building_id, Color(0.5, 0.5, 0.5))
		var rect: Rect2 = Rect2(at - Vector2(SLOT_SIZE, SLOT_SIZE) * 0.5, Vector2(SLOT_SIZE, SLOT_SIZE))
		draw_rect(rect, colour)
		draw_rect(rect, colour.darkened(0.4), false, 2.0)
	for site: Dictionary in field.constructions.active:
		var at: Vector2 = Battlefield.SLOT_POSITIONS[int(site["slot"])]
		var rect: Rect2 = Rect2(at - Vector2(SLOT_SIZE, SLOT_SIZE) * 0.5, Vector2(SLOT_SIZE, SLOT_SIZE))
		draw_rect(rect, Color(0.3, 0.3, 0.3, 0.6))
		draw_rect(rect, Color(0.8, 0.7, 0.3), false, 2.0)
		var data: BuildingDefinition = field.constructions.definition(str(site["building_id"]))
		var fraction: float = clampf(float(site["progress"]) / float(maxi(data.build_time_ticks, 1)), 0.0, 1.0)
		draw_rect(Rect2(rect.position.x, rect.end.y + 3.0, SLOT_SIZE, 4.0), Color(0.15, 0.15, 0.15))
		draw_rect(Rect2(rect.position.x, rect.end.y + 3.0, SLOT_SIZE * fraction, 4.0), Color(0.95, 0.8, 0.3))


## Height of the top of the wall for the current tier. Archers stand on this line.
func wall_top_y() -> float:
	var tier: int = clampi(int(field.game_state.wall_tier), 1, 7)
	return GROUND_Y - (FLOOR_BASE + FLOOR_STEP * float(tier - 1))
