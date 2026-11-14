## Data for one wall tier (SVTLW-63). Tiers 1 to 7 run from a wooden palisade to a legendary bastion.
class_name WallTier
extends Resource

@export_range(1, 7) var tier: int = 1
@export var display_name: String = ""
@export var max_health: int = 100
@export var armour: float = 1.0
@export var repair_per_second: float = 0.0
## Placeholder tint until the tier sprites exist. The battlefield reads this when it is wired.
@export var colour: Color = Color.WHITE
## Gold cost to upgrade into this tier. Tier 1 is the starting tier and costs nothing.
@export var upgrade_cost: int = 0
