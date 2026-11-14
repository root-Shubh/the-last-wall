## Prestige reset, Ancient Relics and the relic shop (SVTLW-73). Relic count and levels live in the injected GameState.
## Prestige is optional: the player may reset at any time, and early runs earn no relics.
class_name PrestigeManager
extends Node

signal prestige_completed(relics_gained: int)
signal relic_purchased(relic_id: String, level: int)

## Relic shop order. Each id has a res://resources/relics/<id>.tres file.
const RELIC_IDS: Array[String] = ["starting_gold", "archer_damage", "production", "population_slot"]
## Same ids as GameState.PATH_IDS, kept here so the manager works with any injected state.
const PATH_IDS: Array[String] = ["warlord", "architect", "merchant", "scholar", "arcanist"]
## Lowest highest-wave that earns any relic.
const MIN_WAVE_FOR_RELICS: int = 20

var state: Node = null


## Relics earned for a run: floor(highest_wave / 10) + floor(total_kills / 500), or 0 below wave 20.
static func relics_for_progress(highest_wave: int, total_kills: int) -> int:
	if highest_wave < MIN_WAVE_FOR_RELICS:
		return 0
	return highest_wave / 10 + maxi(total_kills, 0) / 500


## Ends the run. stats holds highest_wave and total_kills. Adds the relics earned, clears the run
## and pays the relic starting gold. Relics, levels, prestige count and path are kept. Returns relics gained.
func reset_for_prestige(stats: Dictionary) -> int:
	var gained: int = relics_for_progress(int(stats.get("highest_wave", 0)), int(stats.get("total_kills", 0)))
	state.relics += gained
	state.prestige_count += 1
	state.reset_run()
	state.add_gold(int(floor(effect_total("starting_gold"))))
	prestige_completed.emit(gained)
	return gained


func relic_level(relic_id: String) -> int:
	return int(state.relic_levels.get(relic_id, 0))


func relic_definition(relic_id: String) -> RelicUpgrade:
	if not RELIC_IDS.has(relic_id):
		return null
	return RelicUpgrade.load_by_id(relic_id)


## Empty string when the relic can be bought now. Otherwise the reason it cannot.
func relic_block_reason(relic_id: String) -> String:
	var data: RelicUpgrade = relic_definition(relic_id)
	if data == null:
		return "unknown relic"
	if relic_level(relic_id) >= data.max_level:
		return "max level reached"
	if state.relics < data.relic_cost:
		return "not enough relics"
	return ""


## Spends relics and raises the level by one. Returns false and changes nothing if refused.
func buy_relic(relic_id: String) -> bool:
	if relic_block_reason(relic_id) != "":
		return false
	var data: RelicUpgrade = relic_definition(relic_id)
	state.relics -= data.relic_cost
	state.relic_levels[relic_id] = relic_level(relic_id) + 1
	relic_purchased.emit(relic_id, relic_level(relic_id))
	return true


## Sum of effect_per_level x level over every bought relic that changes this effect.
func effect_total(effect_name: String) -> float:
	var total: float = 0.0
	for relic_id: String in RELIC_IDS:
		var data: RelicUpgrade = relic_definition(relic_id)
		if data.effect == effect_name:
			total += data.effect_per_level * relic_level(relic_id)
	return total


## Chooses the specialisation path (SVTLW-74). Returns false for an unknown id.
func choose_path(path_id: String) -> bool:
	if not PATH_IDS.has(path_id):
		return false
	state.prestige_path = path_id
	return true
