## Fires each Overseer message once, when its milestone is first met (SVTLW-67). Fired ids are
## stored as GameState flags so they save with the game. Trigger checks are pure functions.
class_name OverseerMessenger
extends RefCounted

signal message_ready(text: String)

const FIRED_PREFIX: String = "overseer_fired_"
## Maps a trigger kind to the key read from the progress stats dictionary.
const KIND_TO_STAT: Dictionary = {
	"wave_reached": "wave",
	"damage_dealt_total": "total_damage",
	"deaths": "deaths",
}

var _state: Node
var _messages: Array[OverseerMessage] = []


func _init(state: Node, messages: Array[OverseerMessage]) -> void:
	_state = state
	_messages = messages


## True when the stats meet the message trigger. Unknown trigger kinds never fire.
static func is_met(message: OverseerMessage, stats: Dictionary) -> bool:
	if not KIND_TO_STAT.has(message.trigger_kind):
		return false
	return int(stats.get(KIND_TO_STAT[message.trigger_kind], 0)) >= message.trigger_value


func has_fired(message_id: String) -> bool:
	return _state.has_flag(FIRED_PREFIX + message_id)


## Returns the texts of messages whose milestone is newly met, in list order. Each one is
## marked fired, so repeated checks never return it again.
func check(stats: Dictionary) -> Array[String]:
	var ready_texts: Array[String] = []
	for message: OverseerMessage in _messages:
		if message.message_id.is_empty() or has_fired(message.message_id) or not is_met(message, stats):
			continue
		_state.set_flag(FIRED_PREFIX + message.message_id, true)
		ready_texts.append(message.text)
		message_ready.emit(message.text)
	return ready_texts


## Loads every OverseerMessage .tres in a folder. Files that fail to load are skipped.
static func load_all(dir_path: String = "res://resources/overseer") -> Array[OverseerMessage]:
	var messages: Array[OverseerMessage] = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".tres"):
			var message: OverseerMessage = load(dir_path.path_join(file_name)) as OverseerMessage
			if message != null:
				messages.append(message)
	return messages
