## One line of dialogue (SVTLW-40). A line either waits for the player or times out on its own.
## When choices are given, the player must pick one, and the choice index is recorded.
class_name DialogueLine
extends Resource

@export var speaker: String = ""
@export_multiline var text: String = ""
## Optional portrait texture path (res://). Empty means no portrait.
@export var portrait_path: String = ""
## Seconds before the line advances by itself. Zero means it waits for the player.
@export var duration_seconds: float = 0.0
## Player response options. When not empty, the line waits for pick_choice() and ignores timers.
@export var choices: PackedStringArray = PackedStringArray()
