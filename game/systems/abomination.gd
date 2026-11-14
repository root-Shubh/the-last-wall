## The Abomination boss (SVTLW-66). Pure phase and damage logic. Heavy hits get through the
## hide; light hits are cut to a fraction. Phases change at health thresholds.
class_name AbominationPhases
extends RefCounted

const ENEMY_ID: String = "abomination"
const MAX_HEALTH: float = 600.0
## Hits at or above this damage count as heavy and are not reduced.
const HEAVY_HIT_THRESHOLD: float = 12.0
const LIGHT_HIT_FRACTION: float = 0.4
## Health fractions at which the Abomination enters the next phase.
const PHASE_THRESHOLDS: Array[float] = [0.7, 0.4, 0.15]
const REWARD_GOLD: int = 200
const FLAG_DEFEATED: String = "abomination_defeated"

var phase: int = 1
var _reward_granted: bool = false


## Damage actually taken after the hide. Light hits are reduced; heavy hits are not.
static func hide_damage(amount: float) -> float:
	if amount >= HEAVY_HIT_THRESHOLD:
		return amount
	return amount * LIGHT_HIT_FRACTION


## Phase for a health fraction: 1 at full health, rising as health falls.
static func phase_for_fraction(fraction: float) -> int:
	var current: int = 1
	for threshold: float in PHASE_THRESHOLDS:
		if fraction <= threshold:
			current += 1
	return current


## Updates the phase from the current health fraction. Returns true when the phase changed.
func update_phase(fraction: float) -> bool:
	var next: int = phase_for_fraction(fraction)
	if next == phase:
		return false
	phase = next
	return true


## Gold reward granted once, on the first call after the Abomination is dead.
func claim_reward(dead: bool) -> int:
	if not dead or _reward_granted:
		return 0
	_reward_granted = true
	return REWARD_GOLD


func reward_granted() -> bool:
	return _reward_granted
