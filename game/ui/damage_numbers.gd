## Floating damage numbers (SVTLW-37). Purely visual: does nothing when the player turns them off.
## Each number floats up and fades, then removes itself.
class_name DamageNumbers
extends Node2D

const RISE_PIXELS: float = 36.0
const LIFETIME_SECONDS: float = 0.8

var settings: SettingsStore = null
## Number of labels spawned, for tests and debugging.
var spawned_count: int = 0


func show_hit(at: Vector2, amount: float) -> Label:
	if settings != null and not settings.damage_numbers_enabled:
		return null
	var label: Label = Label.new()
	label.text = "%d" % roundi(amount)
	label.position = at + Vector2(-8.0, -24.0)
	add_child(label)
	spawned_count += 1

	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - RISE_PIXELS, LIFETIME_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, LIFETIME_SECONDS)
	tween.chain().tween_callback(label.queue_free)
	return label
