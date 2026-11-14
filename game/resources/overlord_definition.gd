## One Machine Overlord (SVTLW-82). Data lives in resources/overlords/*.tres.
## Each overlord has its own encounter, special attacks, narrative and a permanent reward on defeat.
class_name OverlordDefinition
extends Resource

@export var overlord_id: String = ""
@export var display_name: String = ""
@export var max_health: float = 5000.0
## Health fractions (0 to 1), highest first. Each one starts a new phase once, when health falls to or below it.
@export var phase_thresholds: PackedFloat32Array = PackedFloat32Array()
## Ids of the special attacks this overlord uses, in phase order.
@export var special_attack_ids: PackedStringArray = PackedStringArray()
@export_multiline var narrative_intro: String = ""
@export_multiline var defeat_text: String = ""
## Permanent reward granted once on defeat, for example "archer_damage_bonus_5".
@export var permanent_reward_key: String = ""
