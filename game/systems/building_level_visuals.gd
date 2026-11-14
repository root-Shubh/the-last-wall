## Pure helper for building level visuals (SVTLW-63). Any building view scales its sprite with this.
class_name BuildingLevelVisuals
extends RefCounted


## Each level adds 20 percent to the building scale. Level 1 is the base size.
static func scale_for_level(level: int) -> float:
	return 1.0 + 0.2 * (level - 1)
