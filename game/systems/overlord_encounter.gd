## Runs one Machine Overlord fight (SVTLW-82). Pure: takes damage, reports phases and defeat, no scene access.
class_name OverlordEncounter
extends RefCounted

## Emitted once per phase, with the 1-based number of the phase just entered.
signal phase_reached(phase: int)
## Emitted once, when health reaches zero, with the permanent reward key.
signal defeated(reward_key: String)

var definition: OverlordDefinition
var health: float = 0.0
## Number of phases entered so far. Zero before the first threshold is crossed.
var phase: int = 0
var _defeated: bool = false


func _init(overlord: OverlordDefinition) -> void:
	definition = overlord
	health = maxf(overlord.max_health, 0.0)


## Applies damage. Returns the permanent reward key only on the call that defeats the overlord, else "".
func take_damage(amount: float) -> String:
	if _defeated or amount <= 0.0:
		return ""
	health = maxf(health - amount, 0.0)
	_advance_phases()
	if health <= 0.0:
		_defeated = true
		defeated.emit(definition.permanent_reward_key)
		return definition.permanent_reward_key
	return ""


func is_defeated() -> bool:
	return _defeated


## Reward key once defeated, empty before. Lets a caller read the reward without the damage call.
func defeat_reward() -> String:
	return definition.permanent_reward_key if _defeated else ""


## Health as a fraction of max health, 0 to 1.
func health_fraction() -> float:
	if definition.max_health <= 0.0:
		return 0.0
	return health / definition.max_health


func _advance_phases() -> void:
	var fraction: float = health_fraction()
	while phase < definition.phase_thresholds.size() and fraction <= definition.phase_thresholds[phase]:
		phase += 1
		phase_reached.emit(phase)
