## Post-game continuation (SVTLW-85): the unstable backup environment after the canonical ending.
## Pure: the caller passes in the canonical ending flag. This class only reads it and never sets it.
class_name PostGame
extends RefCounted

const MAX_MULTIPLIER: float = 5.0
const MULTIPLIER_PER_CYCLE: float = 0.1
const OVERLORD_IDS: PackedStringArray = ["architect", "executor", "devourer", "warden"]


## Unlocked only after the canonical ending has been seen.
func is_unlocked(canonical_ending_seen: bool) -> bool:
	return canonical_ending_seen


## Enemy scaling for a number of completed cycles: 1.0 + 0.1 per cycle, capped at 5.0.
func difficulty_multiplier(cycles: int) -> float:
	return minf(1.0 + MULTIPLIER_PER_CYCLE * maxi(cycles, 0), MAX_MULTIPLIER)


## Overlords become optional bosses once cycle 1 is complete. Before that there are none.
func optional_boss_ids(cycles: int) -> PackedStringArray:
	if cycles < 1:
		return PackedStringArray()
	return OVERLORD_IDS.duplicate()
