## Stats and achievements screen (SVTLW-78). Built in code and not yet wired into the battlefield.
## Call build() with the stats and achievements to show, then refresh() after they change.
class_name StatsScreen
extends CanvasLayer

var _stats: StatsTracker = null
var _achievements: Achievements = null
var _content: VBoxContainer = null
var _labels: Array[Label] = []
var _built: bool = false


func build(stats: StatsTracker, achievements: Achievements) -> void:
	_stats = stats
	_achievements = achievements
	if _built:
		refresh()
		return
	_built = true
	layer = 20
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.8)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.position = Vector2(24.0, 24.0)
	scroll.size = Vector2(1232.0, 672.0)
	add_child(scroll)
	_content = VBoxContainer.new()
	_content.custom_minimum_size = Vector2(1200.0, 0.0)
	scroll.add_child(_content)
	refresh()


## Rewrites every label from the current stats and unlock state.
func refresh() -> void:
	if _content == null or _stats == null:
		return
	for label: Label in _labels:
		_content.remove_child(label)
		label.free()
	_labels.clear()
	var title: String = "Statistics"
	_add_line(title)
	_add_line("Total kills: %d" % _stats.total_kills)
	_add_line("Waves survived: %d (highest %d)" % [_stats.waves_survived, _stats.highest_wave])
	_add_line("Resources earned: %d" % _stats.resources_earned)
	_add_line("Damage dealt: %d" % _stats.damage_dealt)
	_add_line("Damage received: %d" % _stats.damage_received)
	_add_line("Highest single hit: %d" % _stats.highest_damage_hit)
	_add_line("Deaths: %d" % _stats.deaths)
	_add_line("Playtime: %s" % format_playtime(_stats.playtime_seconds))
	if _achievements == null:
		return
	_add_line("Achievements (%d of %d)" % [_achievements.unlocked.size(), _achievements.definitions.size()])
	for definition: Achievement in _achievements.definitions:
		var status: String = "Unlocked" if _achievements.is_unlocked(definition.achievement_id) else "Locked"
		_add_line("[%s] %s: %s" % [status, definition.display_name, definition.description])


## Text of every label currently on the screen, in order.
func get_label_texts() -> Array[String]:
	var texts: Array[String] = []
	for label: Label in _labels:
		texts.append(label.text)
	return texts


## Formats seconds as H:MM:SS.
static func format_playtime(seconds: float) -> String:
	var total: int = int(maxf(seconds, 0.0))
	return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]


func _add_line(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	_content.add_child(label)
	_labels.append(label)
