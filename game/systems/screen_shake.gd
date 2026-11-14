## Pure screen-shake helper (SVTLW-60). Deterministic, so tests can check it. The battlefield wires it up.
class_name ScreenShake
extends RefCounted

## Ticks until the shake has fully decayed to zero.
const DECAY_TICKS: int = 10


## Offset for a shake that started with the given strength, `tick` ticks after it began.
## Returns zero when the shake is disabled, the strength is not positive, or it has decayed.
static func shake_offset(strength: float, tick: int, enabled: bool = true) -> Vector2:
	if not enabled or strength <= 0.0 or tick < 0 or tick >= DECAY_TICKS:
		return Vector2.ZERO
	var remaining: float = 1.0 - float(tick) / float(DECAY_TICKS)
	var direction: Vector2 = Vector2(cos(tick * 2.4), sin(tick * 1.3)).normalized()
	return direction * strength * remaining
