## Minimal research tree panel (SVTLW-61). One section per branch, one button per node.
## A refused node is disabled and its reason is shown as the tooltip. Not wired into the battlefield yet.
## The manager is injected through bind(). Pressing a button calls ResearchManager.research().
class_name ResearchPanel
extends CanvasLayer

const PANEL_POSITION: Vector2 = Vector2(16.0, 48.0)
const PANEL_WIDTH: float = 260.0

var manager: ResearchManager = null
var _column: VBoxContainer
var _points_label: Label
var _buttons: Dictionary = {}  # research_id -> Button
var _built: bool = false


func bind(research_manager: ResearchManager) -> void:
	build()
	manager = research_manager
	if manager != null:
		manager.points_changed.connect(func(_p: int) -> void: refresh())
		manager.research_completed.connect(func(_id: String) -> void: refresh())
	_rebuild_buttons()
	refresh()


func build() -> void:
	if _built:
		return
	_built = true
	layer = 12
	var panel: PanelContainer = PanelContainer.new()
	panel.position = PANEL_POSITION
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	add_child(panel)
	_column = VBoxContainer.new()
	_column.custom_minimum_size = Vector2(PANEL_WIDTH - 16.0, 0.0)
	panel.add_child(_column)
	_points_label = Label.new()
	_column.add_child(_points_label)


## The button for one research node, or null when the panel does not show it.
func button_for(research_id: String) -> Button:
	return _buttons.get(research_id, null)


func refresh() -> void:
	if manager == null:
		return
	_points_label.text = "Research points: %d" % manager.research_points
	for research_id: String in _buttons:
		var button: Button = _buttons[research_id]
		var reason: String = manager.can_research(research_id)
		button.disabled = reason != ""
		button.tooltip_text = reason if reason != "" else "Research %s" % research_id
		if manager.is_researched(research_id):
			button.text = "%s (done)" % manager.definition(research_id).display_name


func _rebuild_buttons() -> void:
	for child: Node in _column.get_children():
		if child != _points_label:
			child.queue_free()
	_buttons.clear()
	if manager == null:
		return
	for branch: String in ResearchDefinition.BRANCHES:
		var header: Label = Label.new()
		header.text = branch
		_column.add_child(header)
		for data: ResearchDefinition in manager.definitions:
			if data.branch != branch:
				continue
			var button: Button = Button.new()
			button.text = "%s (%d RP)" % [data.display_name, data.cost_rp]
			var research_id: String = data.research_id
			button.pressed.connect(func() -> void: _on_pressed(research_id))
			_column.add_child(button)
			_buttons[research_id] = button


func _on_pressed(research_id: String) -> void:
	if manager != null:
		manager.research(research_id)
	refresh()
