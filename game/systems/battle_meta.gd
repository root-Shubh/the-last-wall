## Connects the meta-game systems to the battle (stats, achievements, death counter, Overseer messages,
## narrative acts, endless siege, weekly challenge and regions). Each system stays pure; this class only
## calls them with the battle's events, so the battlefield script stays small.
class_name BattleMeta
extends RefCounted

const SECONDS_PER_WEEK: int = 7 * 24 * 60 * 60

var stats: StatsTracker
var achievements: Achievements
var death_counter: DeathCounter
var messenger: OverseerMessenger
var narrative: NarrativeProgress
var endless: EndlessSiege
var challenges: ChallengeRotation
var regions: RegionMap
var prestige: PrestigeManager
var _state: Node
var _overlord_encounter: OverlordEncounter = null


func _init(game_state: Node, generator: WaveGenerator, overseer_messages: Array[OverseerMessage]) -> void:
	_state = game_state
	stats = game_state.stats
	achievements = game_state.achievements
	death_counter = DeathCounter.new(stats)
	messenger = OverseerMessenger.new(game_state, overseer_messages)
	narrative = NarrativeProgress.new(game_state)
	endless = EndlessSiege.new(generator)
	challenges = ChallengeRotation.load_from_directory()
	regions = RegionMap.new()
	prestige = PrestigeManager.new()
	prestige.state = game_state
	_overlord_encounter = null


## One enemy killed by the player.
func on_kill(_enemy_id: String) -> void:
	stats.record_kill()
	endless.record_kills(1)


## Damage the player's defences and units dealt to enemies.
func on_damage_dealt(amount: float) -> void:
	stats.record_damage_dealt(roundi(amount))
	stats.record_hit(roundi(amount))


## Damage the wall took from enemies.
func on_damage_received(amount: float) -> void:
	stats.record_damage_received(roundi(amount))


func on_tick(seconds: float) -> void:
	stats.add_playtime(seconds)


## A wave finished. Returns the Overseer texts that fired and the newly unlocked achievement ids.
func on_wave_completed(wave_number: int, wall_tier: int) -> Dictionary:
	stats.record_wave_survived(wave_number)
	stats.highest_wave = maxi(stats.highest_wave, wave_number)
	narrative.try_advance(stats.to_dict())
	var messages: Array[String] = messenger.check(stats.to_dict())
	var unlocked: Array[String] = achievements.check(stats, wall_tier)
	return {"messages": messages, "achievements": unlocked}


## The wall fell. Returns the death lines that fired.
func on_wall_destroyed() -> Array[String]:
	return death_counter.on_death()


func region_for_wave(wave_number: int) -> Region:
	return regions.region_for_wave(wave_number)


## Challenge for the current week, from the system clock.
func current_challenge(now_unix: int) -> ChallengeDefinition:
	return challenges.active_for_week(now_unix / SECONDS_PER_WEEK)


## Exploitation research effects, summed from the researched ids. Mapping to combat is in battlefield.gd.
func exploit_totals(researched: Array) -> Dictionary:
	var ids: PackedStringArray = PackedStringArray()
	for id: Variant in researched:
		ids.append(str(id))
	return ExploitEffects.totals(ids)


## Starts the region's Overlord when its last wave completes. Returns the intro text, or "" if none.
func start_region_overlord(wave_number: int) -> String:
	for region: Region in regions.regions:
		if region.last_wave != wave_number or region.boss_id == "":
			continue
		var path: String = "res://resources/overlords/%s.tres" % region.boss_id
		if not ResourceLoader.exists(path):
			continue
		var definition: OverlordDefinition = load(path) as OverlordDefinition
		if definition == null:
			continue
		_overlord_encounter = OverlordEncounter.new(definition)
		return definition.narrative_intro
	return ""


func overlord_active() -> bool:
	return _overlord_encounter != null and not _overlord_encounter.is_defeated()


## Damage to the region Overlord. Returns the defeat text when this hit defeats it, else "".
func damage_overlord(amount: float) -> String:
	if not overlord_active():
		return ""
	var reward_key: String = _overlord_encounter.take_damage(amount)
	if reward_key == "":
		return ""
	_state.set_flag(reward_key, true)
	return _overlord_encounter.definition.defeat_text


## Offline gold-like production since the last save, using the battle's per-tick rates.
func offline_gain(rates: Dictionary, last_saved_unix: int, now_unix: int, enabled: bool) -> Dictionary:
	var elapsed: int = OfflineProgress.elapsed_since(last_saved_unix, now_unix)
	return OfflineProgress.compute(rates, elapsed, OfflineProgress.DEFAULT_CAP_SECONDS, enabled)


## Relic and path actions for the prestige screen.
func prestige_reset(stats_dict: Dictionary) -> int:
	return prestige.reset_for_prestige(stats_dict)


func buy_relic(relic_id: String) -> bool:
	return prestige.buy_relic(relic_id)


func choose_path(path_id: String) -> bool:
	return prestige.choose_path(path_id)
