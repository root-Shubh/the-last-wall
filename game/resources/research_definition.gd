## Data for one research node (SVTLW-61). Cost, prerequisites, exclusions and the effect key all live here.
## Data only: the effect itself is applied by later code, which reads effect_key and effect_value.
class_name ResearchDefinition
extends Resource

const BRANCHES: Array[String] = ["Military", "Engineering", "Economy", "Arcane", "Logistics"]

@export var research_id: String = ""
@export var display_name: String = ""
@export_enum("Military", "Engineering", "Economy", "Arcane", "Logistics", "Simulation Exploitation") var branch: String = "Military"
@export var cost_rp: int = 10
## Every id listed here must be researched before this node can be researched.
@export var prerequisites: PackedStringArray = PackedStringArray()
## Ids that cannot be researched alongside this node. Declare both sides of a pair.
@export var exclusive_with: PackedStringArray = PackedStringArray()
@export var effect_key: String = ""
@export var effect_value: float = 0.0
