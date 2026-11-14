## One Overseer message (SVTLW-67). Data only: OverseerMessenger decides when it fires.
## corrupted_text is reserved for corrupted variants (Act II and later) and is not used yet.
class_name OverseerMessage
extends Resource

## Trigger kinds: "wave_reached", "damage_dealt_total" or "deaths".
@export var message_id: String = ""
@export_multiline var text: String = ""
@export_multiline var corrupted_text: String = ""
@export var trigger_kind: String = "wave_reached"
@export var trigger_value: int = 0
