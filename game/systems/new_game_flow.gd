## Start of a new game (SVTLW-41, SVTLW-42). Resets the game, sets the character, and plays the
## opening sequence. The intro_seen flag is set when the sequence finishes or is skipped.
## The intro plays on every New Game, as the brief specifies.
class_name NewGameFlow
extends RefCounted

const OPENING_PATH: String = "res://resources/dialogue/opening.tres"
const FLAG_INTRO_SEEN: String = "intro_seen"


## Returns false if the character or name is invalid. Nothing is reset in that case.
static func start(game_state: Node, dialogue: DialogueManager, character_id: String, display_name: String) -> bool:
	if not game_state.is_valid_character(character_id, display_name):
		return false
	game_state.reset()
	game_state.set_character(character_id, display_name)
	var opening: DialogueSequence = load(OPENING_PATH)
	var on_finished: Callable = func(id: String) -> void:
		if id == opening.sequence_id:
			game_state.set_flag(FLAG_INTRO_SEEN, true)
	dialogue.sequence_finished.connect(on_finished, CONNECT_ONE_SHOT)
	dialogue.play(opening)
	return true
