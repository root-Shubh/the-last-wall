## On-screen battle controls (SVTLW-99): Recruit Archer, Start Wave, Save and Quit.
## Each button calls the same method a test calls, so the buttons are covered by tests too.
class_name BattleControls
extends CanvasLayer

signal quit_requested

var field: Battlefield = null
var _built: bool = false
const RECRUIT_START_X: float = 190.0
const RECRUIT_STEP_X: float = 30.0
const RECRUIT_Y: float = 300.0


func bind(battlefield: Battlefield) -> void:
	field = battlefield
	build()


func build() -> void:
	if _built:
		return
	_built = true
	layer = 26
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(12.0, 680.0)
	add_child(row)
	_button(row, "Recruit Archer", func() -> void: recruit())
	_button(row, "Start Wave", func() -> void: start_wave())
	_button(row, "Save", func() -> void: save())
	_button(row, "Quit", func() -> void: quit_requested.emit())


## Places a new archer in the next free slot on the fortress. Returns null if refused.
func recruit() -> Archer:
	if field == null:
		return null
	var slot: int = field.units.archers.size()
	return field.recruit_archer(Vector2(RECRUIT_START_X + RECRUIT_STEP_X * slot, RECRUIT_Y))


func start_wave() -> bool:
	return field != null and field.start_wave()


func save() -> bool:
	return field != null and field.save_now()


func _button(parent: Node, text: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
