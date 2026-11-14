## Battlefield controller (SVTLW-28 and SVTLW-29 wiring). Creates the M1 systems and connects
## them: clock to waves, waves to enemies, enemies to wall, archers to projectiles, and kills to rewards.
## Systems hold no references to each other except through these connections.
class_name Battlefield
extends Node2D

signal game_over

## Gold and wall health source. Tests inject it. In the game it defaults to the GameState autoload.
var game_state: Node = null

var clock: SimulationClock
var waves: WaveManager
var enemies: EnemyManager
var units: UnitManager
var projectiles: ProjectilePool
var rewards: RewardTracker
var wall: WallManager
var upgrades: UpgradeManager
var hud: TopBar
var settings: SettingsStore
var damage_numbers: DamageNumbers
var constructions: ConstructionManager
var production: ProductionManager
var effects: EffectPool
var context_panel: ContextPanel
## Fixed build slots on the fortress, indexed by slot number (SVTLW-100).
const SLOT_POSITIONS: Array[Vector2] = [Vector2(130.0, 170.0), Vector2(130.0, 540.0), Vector2(60.0, 360.0), Vector2(60.0, 250.0)]
## Gold per upgrade level: upgrading from level n costs UPGRADE_GOLD_PER_LEVEL * n.
const UPGRADE_GOLD_PER_LEVEL: int = 25
## Radius of the explosion raised by a defence structure's shot.
const EXPLOSION_RADIUS: float = 40.0
## Built defence structures by building id. A building can only be built once.
var _defences: Dictionary = {}
## Active abilities, Region 1 objectives, The Abomination, Wave 1000 and the ending (SVTLW-64, 65, 66, 83, 84).
var abilities: Abilities = Abilities.new()
var objectives: CampaignObjectives = CampaignObjectives.new()
var boss_phases: AbominationPhases = AbominationPhases.new()
var final_battle: FinalBattle = FinalBattle.new()
var ending: EndingSequence = EndingSequence.new()
var _boss_enemy: Enemy = null
## Stats, achievements, death lines, Overseer messages, narrative, endless siege, challenge and regions (SVTLW-78 to 85 wiring).
var meta: BattleMeta = null
## Overseer texts, unlocked achievement ids and death lines, emitted as they happen.
signal overseer_message(text: String)
signal achievement_unlocked(achievement_id: String)
signal death_line(text: String)
## Name of the region the current wave is in (SVTLW-81).
signal region_entered(region_name: String)
var _tick_index: int = 0
var _last_stand_until: int = 0
const RAIN_DAMAGE: float = 6.0
const REPAIR_AMOUNT: int = 30
const REINFORCEMENT_COUNT: int = 2
## Emitted for each step of the collapse ending, so the UI can show text and fades (SVTLW-84).
signal ending_step(step: Dictionary)
## Number of screen shakes started, for tests.
var shake_count: int = 0
var _shake_strength: float = 0.0
var _shake_tick: int = 0
var _built: bool = false


func _ready() -> void:
	ensure_ready()


## Builds and connects the systems once. Safe to call more than once. Tests call it directly
## because _ready is not guaranteed to run for nodes added during a SceneTree script.
func ensure_ready() -> void:
	if _built:
		return
	_built = true
	clock = get_node("SimulationClock")
	if game_state == null:
		game_state = get_node_or_null("/root/GameState")
	if save_manager == null:
		save_manager = get_node_or_null("/root/SaveManager")
	if audio == null:
		audio = get_node_or_null("/root/AudioManager")
	settings = SettingsStore.new()
	settings.load_from()
	if audio != null:
		audio.apply_settings(settings)
	damage_numbers = DamageNumbers.new()
	damage_numbers.settings = settings
	add_child(damage_numbers)
	_build_systems()
	_build_meta()
	_build_research()
	_connect_systems()
	_build_view()
	hud = TopBar.new()
	add_child(hud)
	hud.bind(game_state, clock, waves, wall)
	hud.bind_production(production)
	context_panel.select_recruitment()


## Shakes the battlefield briefly. Does nothing when screen shake is turned off (SVTLW-37).
## The offset decays over ticks in _on_tick, through ScreenShake.shake_offset (SVTLW-100).
func shake(strength: float) -> void:
	ensure_ready()
	if not settings.screen_shake_enabled:
		return
	shake_count += 1
	_shake_strength = strength
	_shake_tick = 0


func _update_shake() -> void:
	if _shake_strength <= 0.0:
		return
	position = ScreenShake.shake_offset(_shake_strength, _shake_tick, settings.screen_shake_enabled)
	_shake_tick += 1
	if _shake_tick >= ScreenShake.DECAY_TICKS:
		_shake_strength = 0.0
		position = Vector2.ZERO


## Starts a build on a fixed slot. Returns false and spends nothing when it is refused (SVTLW-100).
func build(building_id: String, slot: int) -> bool:
	ensure_ready()
	if slot < 0 or slot >= SLOT_POSITIONS.size():
		notice.emit("No free slot on the fortress")
		return false
	var reason: String = constructions.start_block_reason(building_id, slot)
	if reason != "":
		notice.emit(reason)
		return false
	var cost: int = constructions.definition(building_id).build_cost
	constructions.start_construction(building_id, slot)
	float_text(SLOT_POSITIONS[slot], "-%d gold" % cost, Color(1.0, 0.8, 0.3))
	return true


## A short message for refused actions and results (SVTLW-105 feedback).
signal notice(text: String)


## Floating text that rises and fades, for gold gained or spent and for damage (feedback).
func float_text(at: Vector2, text: String, colour: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = at + Vector2(-20.0, -40.0)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 34.0, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1)
	tween.chain().tween_callback(label.queue_free)


## Builds the wall-tier system and the fortress view (SVTLW-63, floors and tiers).
func _build_view() -> void:
	tiers = WallTierManager.new()
	add_child(tiers)
	tiers.bind(game_state, wall)
	tiers.load_default_tiers()
	tiers.current_index = clampi(int(game_state.wall_tier) - 1, 0, WallTierManager.TIER_COUNT - 1)
	# The scene's placeholder fortress shapes give way to the tiered wall and the recruited archers.
	for placeholder: String in ["Fortress/Wall", "Fortress/Keep", "Fortress/ArcherA", "Fortress/ArcherB", "Fortress/ArcherC"]:
		var shape: CanvasItem = get_node_or_null(placeholder)
		if shape != null:
			shape.visible = false
	view = BattleView.new()
	view.field = self
	add_child(view)


## Upgrades the wall one tier, with the tier's gold cost. Refusals say why (SVTLW-63).
func upgrade_wall() -> bool:
	ensure_ready()
	if tiers.current_index >= WallTierManager.TIER_COUNT - 1:
		notice.emit("The wall is already at its highest tier")
		return false
	var next: WallTier = tiers.tiers[tiers.current_index + 1]
	if not game_state.can_afford(next.upgrade_cost):
		notice.emit("Wall upgrade needs %d gold, you have %d" % [next.upgrade_cost, game_state.gold])
		return false
	if not tiers.upgrade_tier():
		notice.emit("Wall upgrade refused")
		return false
	notice.emit("Wall upgraded to %s" % next.display_name)
	return true


## First fixed slot with nothing built or building on it. -1 when every slot is taken.
func free_slot() -> int:
	ensure_ready()
	for slot: int in range(SLOT_POSITIONS.size()):
		if constructions.is_slot_free(slot):
			return slot
	return -1


## Buys one level for a built defence structure or a registered production building (SVTLW-100).
## Refuses with no spend when the building is at max level or not built.
func upgrade_building(building_id: String) -> bool:
	ensure_ready()
	var structure: DefenceStructure = _defences.get(building_id, null)
	var level: int = 0
	var max_level: int = 0
	if structure != null:
		level = structure.level
		max_level = structure.max_level
	elif production.is_registered(building_id):
		level = production.level_of(building_id)
		max_level = maxi(production.definition(building_id).max_level, 1)
	else:
		return false
	if level >= max_level:
		return false
	var cost: int = UPGRADE_GOLD_PER_LEVEL * level
	if not game_state.spend_gold(cost):
		return false
	var done: bool = structure.upgrade() if structure != null else production.upgrade(building_id)
	if not done:
		game_state.refund_gold(cost)
		return false
	_sound("upgrade")
	return true


## Starts the next wave from the catalog. Returns false if one is already running.
func start_wave() -> bool:
	ensure_ready()
	# Wave 1000 is the final Overseer battle, not a normal wave (SVTLW-83).
	if FinalBattle.is_final_wave(waves.current_wave + 1):
		return final_battle.begin()
	var started: bool = waves.start_next_wave()
	if started:
		var region: Region = meta.region_for_wave(waves.current_wave)
		if region != null:
			region_entered.emit(region.display_name)
	return started


func recruit_archer(at: Vector2) -> Archer:
	ensure_ready()
	if _challenge_restriction() == "no_archers":
		notice.emit("Challenge this week: no archers")
		return null
	var reason: String = units.recruit_block_reason("archer")
	if reason != "":
		notice.emit(reason)
		return null
	var archer: Archer = units.recruit("archer", at)
	if archer != null:
		float_text(at, "Archer recruited", Color(0.7, 0.9, 1.0))
	return archer


## The restriction of this week's challenge when challenge mode is on, else "" (SVTLW-77).
func _challenge_restriction() -> String:
	if meta == null or not game_state.has_flag("challenge_mode"):
		return ""
	var challenge: ChallengeDefinition = meta.current_challenge(int(Time.get_unix_time_from_system()))
	return challenge.restriction if challenge != null else ""


## Turns challenge mode on or off. The restriction applies from then on.
func set_challenge_mode(on: bool) -> void:
	ensure_ready()
	game_state.set_flag("challenge_mode", on)
	_apply_upgrade_effects()


## Active abilities (SVTLW-64). Returns false when locked, on cooldown or refused.
func use_ability(ability_id: String) -> bool:
	ensure_ready()
	var researched: Array = game_state.research.get("researched", [])
	if not abilities.use(ability_id, _tick_index, researched):
		return false
	match ability_id:
		Abilities.RAIN_OF_ARROWS:
			for enemy: Enemy in enemies.enemies.duplicate():
				enemies.damage_enemy(enemy, RAIN_DAMAGE)
		Abilities.EMERGENCY_REPAIR:
			game_state.repair_wall(REPAIR_AMOUNT)
		Abilities.REINFORCEMENT:
			for i: int in range(REINFORCEMENT_COUNT):
				recruit_archer(SLOT_POSITIONS[0] + Vector2(20.0 * i, 0.0))
		Abilities.LAST_STAND:
			_last_stand_until = _tick_index + Abilities.LAST_STAND_TICKS
	_sound("ability")
	return true


func _last_stand_active() -> bool:
	return _tick_index < _last_stand_until


## Spawns The Abomination (SVTLW-66). Returns the enemy, or null if it is already on the field.
func spawn_boss() -> Enemy:
	ensure_ready()
	if _boss_enemy != null and is_instance_valid(_boss_enemy) and _boss_enemy.alive:
		return null
	_boss_enemy = enemies.spawn(AbominationPhases.ENEMY_ID)
	return _boss_enemy


## Start Region 1's final objectives (SVTLW-65): the caller reports progress through the battlefield.
func region_objectives() -> CampaignObjectives:
	ensure_ready()
	return objectives


## The canonical ending sequence (SVTLW-84). Read its steps through ending_step.
func ending_sequence() -> EndingSequence:
	ensure_ready()
	return ending


## Advances the battlefield by whole ticks. The real clock calls this on each tick too.
func step_ticks(count: int) -> void:
	ensure_ready()
	for i: int in range(count):
		clock.advance(1.0 / SimulationClock.TICKS_PER_SECOND + 0.0001)


## Research (SVTLW-61): the manager, and the panel the Research button opens. Points come from waves.
const RESEARCH_POINTS_PER_WAVE: int = 1
var research: ResearchManager = null
var research_panel: ResearchPanel = null
var tiers: WallTierManager = null
var view: BattleView = null


func _build_research() -> void:
	research = ResearchManager.new()
	research.load_definitions("res://resources/research")
	research.bind(game_state)
	research_panel = ResearchPanel.new()
	add_child(research_panel)
	research_panel.bind(research)
	research_panel.visible = false


## Enemy types unlocked by wave number. Every wave mixes the types unlocked so far, so waves are not one type each.
const ENEMY_UNLOCK_WAVES: Dictionary = {
	"undead_infantry": 1,
	"runner": 4,
	"armoured_brute": 7,
	"shield_bearer": 10,
	"climber": 13,
}
var _spawn_counter: int = 0


## The next enemy for a wave: cycles through the types unlocked by that wave.
func _mixed_enemy_for_wave(wave_number: int) -> String:
	var pool: Array[String] = []
	for id: String in ENEMY_UNLOCK_WAVES:
		if wave_number >= int(ENEMY_UNLOCK_WAVES[id]):
			pool.append(id)
	if pool.is_empty():
		pool.append("undead_infantry")
	_spawn_counter += 1
	return pool[(_spawn_counter - 1) % pool.size()]


## Builds the meta-game connections. Overseer messages load from resources/overseer (SVTLW-67, 68).
func _build_meta() -> void:
	var messages: Array[OverseerMessage] = []
	var dir: DirAccess = DirAccess.open("res://resources/overseer")
	if dir != null:
		for file: String in dir.get_files():
			if file.ends_with(".tres"):
				var message: OverseerMessage = load("res://resources/overseer/" + file) as OverseerMessage
				if message != null:
					messages.append(message)
	meta = BattleMeta.new(game_state, waves.generator, messages)


func _build_systems() -> void:
	waves = WaveManager.new()
	waves.catalog = load("res://resources/waves/m1_catalog.tres")
	add_child(waves)

	waves.generator = WaveGenerator.new()
	waves.generator.stage_table = load("res://resources/waves/wave_stages.tres")

	enemies = EnemyManager.new()
	enemies.definitions = [
		load("res://resources/enemies/undead_infantry.tres"),
		load("res://resources/enemies/runner.tres"),
		load("res://resources/enemies/armoured_brute.tres"),
		load("res://resources/enemies/climber.tres"),
		load("res://resources/enemies/shield_bearer.tres"),
		load("res://resources/enemies/overlord.tres"),
		load("res://resources/enemies/abomination.tres"),
	]
	add_child(enemies)

	projectiles = ProjectilePool.new()
	add_child(projectiles)

	effects = EffectPool.new()
	add_child(effects)

	var building_defs: Array[BuildingDefinition] = []
	for id: String in ["tower", "archer_platform", "lumber_mill", "quarry", "iron_mine"]:
		building_defs.append(load("res://resources/buildings/%s.tres" % id))
	constructions = ConstructionManager.new()
	constructions.definitions = building_defs
	constructions.state = game_state
	add_child(constructions)

	production = ProductionManager.new()
	production.definitions = building_defs
	production.state = game_state
	add_child(production)

	units = UnitManager.new()
	units.unit_definitions = [
		load("res://resources/units/archer.tres"),
		load("res://resources/units/crossbowman.tres"),
		load("res://resources/units/gunner.tres"),
		load("res://resources/units/spearman.tres"),
		load("res://resources/units/swordsman.tres"),
	]
	units.state = game_state
	add_child(units)

	rewards = RewardTracker.new()
	add_child(rewards)
	rewards.bind(enemies, waves, game_state)

	wall = WallManager.new()
	wall.armour = 1.0
	add_child(wall)
	wall.bind(game_state)

	upgrades = UpgradeManager.new()
	upgrades.definitions = [
		load("res://resources/upgrades/archer_damage.tres"),
		load("res://resources/upgrades/archer_attack_speed.tres"),
		load("res://resources/upgrades/wall_max_health.tres"),
		load("res://resources/upgrades/repair_rate.tres"),
		load("res://resources/upgrades/gold_per_kill.tres"),
	]
	upgrades.state = game_state
	add_child(upgrades)

	context_panel = ContextPanel.new()
	add_child(context_panel)
	context_panel.bind(units, game_state, constructions)


## Base wall health before upgrades (SVTLW-39).
const BASE_WALL_MAX_HEALTH: int = 100


## Buys one upgrade level. Returns false if it is blocked (SVTLW-39).
func buy_upgrade(upgrade_id: String) -> bool:
	ensure_ready()
	return upgrades.purchase(upgrade_id)


## Pushes every upgrade total into the systems it changes (SVTLW-39).
func _apply_upgrade_effects() -> void:
	_apply_exploit_effects()
	units.set_archer_multipliers(
		1.0 + upgrades.effect_total("archer_damage") + _exploit.get("parallel_combat_bonus", 0.0),
		1.0 + upgrades.effect_total("archer_attack_speed") + _exploit.get("unbounded_multiplier_bonus", 0.0))
	game_state.set_wall_max_health(BASE_WALL_MAX_HEALTH + roundi(upgrades.effect_total("wall_max_health")))
	rewards.kill_gold_bonus = roundi(upgrades.effect_total("gold_per_kill"))
	_apply_challenge_restrictions()


## Challenge restrictions, applied after the normal values (SVTLW-77).
func _apply_challenge_restrictions() -> void:
	match _challenge_restriction():
		"no_repairs":
			wall.repair_per_second = 0.0
		"wall_max_health_half":
			game_state.set_wall_max_health(maxi(BASE_WALL_MAX_HEALTH / 2, 1))


## Simulation Exploitation research (SVTLW-71). Each effect key maps to one combat or economy effect.
## The mapping is a proposal: the research text does not say where each effect applies. See docs/BALANCE.md.
## overflow_damage_cap: raises the per-hit damage cap (40 base). recursive_production_bonus: offline gain multiplier.
## unbounded_multiplier_bonus: archer attack speed. parallel_combat_bonus: archer damage.
## infinite_recursion_bonus: extra wall repair per second. reality_desync_vs_machines: extra damage to every enemy.
## memory_corruption_debuff: enemies deal less damage to the wall.
var _exploit: Dictionary = {}
const HIT_CAP_BASE: float = 40.0


func _apply_exploit_effects() -> void:
	if meta == null:
		return
	_exploit = {}
	var totals: Dictionary = meta.exploit_totals(game_state.research.get("researched", []))
	for key: Variant in totals:
		_exploit[str(key)] = float(totals[key])
	wall.repair_per_second = upgrades.effect_total("repair_rate") + _exploit.get("infinite_recursion_bonus", 0.0)


func _connect_systems() -> void:
	clock.tick_advanced.connect(_on_tick)
	waves.enemy_spawn_requested.connect(func(_id: String) -> void: enemies.spawn(_mixed_enemy_for_wave(waves.current_wave)))
	waves.wave_completed.connect(_on_wave_completed)
	enemies.enemy_removed.connect(func(_e: Enemy) -> void: waves.report_enemy_removed())
	enemies.wall_attacked.connect(func(damage: float) -> void:
		meta.on_damage_received(damage)
		damage *= 1.0 - _exploit.get("memory_corruption_debuff", 0.0)
		if not _last_stand_active():
			wall.attack(damage)
		_sound("wall_impact")
		shake(clampf(damage, 1.0, 6.0)))
	# Climbers ignore wall armour (SVTLW-57), so their damage goes straight through.
	enemies.wall_attacked_unarmoured.connect(func(damage: float) -> void:
		if not _last_stand_active():
			wall.attack_unarmoured(damage)
		_sound("wall_impact")
		shake(clampf(damage, 1.0, 6.0)))
	constructions.construction_completed.connect(_on_construction_completed)
	projectiles.explosion_requested.connect(func(at: Vector2) -> void:
		effects.spawn_explosion(effects.to_local(at), EXPLOSION_RADIUS))
	waves.wave_started.connect(func(_n: int) -> void: _sound("wave_start"))
	waves.wave_completed.connect(func(_n: int) -> void: _sound("wave_end"))
	rewards.reward_granted.connect(func(_a: int, _r: String) -> void: _sound("reward"))
	upgrades.upgrade_purchased.connect(func(_id: String, _l: int) -> void: _sound("upgrade"))
	units.unit_recruited.connect(_on_unit_recruited)
	projectiles.projectile_hit.connect(_on_projectile_hit)
	wall.wall_destroyed.connect(_on_wall_destroyed)
	wall.damage_state_changed.connect(_on_wall_state_changed)
	_on_wall_state_changed(wall.current_state())
	upgrades.effects_changed.connect(_apply_upgrade_effects)
	_apply_upgrade_effects()
	# Kills (health at zero) feed the objectives and the final battle. Enemies that reach the wall do not.
	enemies.enemy_removed.connect(_on_enemy_removed_for_objectives)
	waves.wave_completed.connect(_on_wave_completed_for_objectives)


func _on_tick(tick_index: int) -> void:
	waves.on_tick(tick_index)
	enemies.on_tick(tick_index)
	units.on_tick(tick_index, enemies.enemies)
	projectiles.on_tick(tick_index)
	wall.on_tick(tick_index)
	constructions.on_tick(tick_index)
	production.on_tick(tick_index)
	_tick_index = tick_index
	for structure: DefenceStructure in _defences.values():
		# A slot switched off by the Overseer stops firing until it comes back (SVTLW-83).
		if final_battle.active and final_battle.slot_disabled(structure.slot):
			continue
		structure.on_tick(tick_index, enemies.enemies)
	_on_final_battle_tick()
	effects.on_tick(tick_index)
	_update_shake()
	# Autosave runs after every system has finished this tick, never in the middle of one (SVTLW-45).
	if _autosave_pending:
		_autosave_pending = false
		save_now()


func _on_wave_completed(_wave_number: int) -> void:
	_autosave_pending = true


## A finished tower or archer platform gets a DefenceStructure on its slot. A production building is registered (SVTLW-100).
func _on_construction_completed(building_id: String, slot: int) -> void:
	var data: BuildingDefinition = constructions.definition(building_id)
	if data.attack_damage > 0.0:
		var structure: DefenceStructure = DefenceStructure.new()
		structure.setup(data, slot, SLOT_POSITIONS[slot])
		structure.fire_requested.connect(_on_defence_fire)
		add_child(structure)
		_defences[building_id] = structure
	production.register(building_id)


## Advances the final battle and the ending by one tick (SVTLW-83, SVTLW-84).
func _on_final_battle_tick() -> void:
	meta.on_tick(1.0 / SimulationClock.TICKS_PER_SECOND)
	if final_battle.active:
		for event: String in final_battle.on_tick(SLOT_POSITIONS.size()):
			if event == "overlord":
				enemies.spawn(FinalBattle.OVERLORD_ID)
	if final_battle.victory and not ending.is_playing() and not ending.is_finished():
		ending.start(game_state.has_flag(EndingSequence.FLAG_CANONICAL))
	if ending.is_playing():
		var finished: bool = ending.on_tick()
		ending_step.emit(ending.current_step())
		if finished:
			game_state.set_flag(EndingSequence.FLAG_CANONICAL, true)
			save_now()


## Kills feed the objectives, the final battle and the Abomination (SVTLW-65, 66, 83).
func _on_enemy_removed_for_objectives(enemy: Enemy) -> void:
	if enemy.health > 0.0:
		return
	var enemy_id: String = enemy.definition.enemy_id
	if enemy.definition.gold_reward > 0:
		float_text(enemy.global_position, "+%d gold" % enemy.definition.gold_reward, Color(1.0, 0.85, 0.3))
	objectives.record_kill(enemy_id)
	final_battle.record_kill(enemy_id)
	meta.on_kill(enemy_id)
	if enemy == _boss_enemy:
		objectives.record_boss_defeated()
		var gold: int = boss_phases.claim_reward(true)
		if gold > 0:
			game_state.add_gold(gold)
			game_state.set_flag(AbominationPhases.FLAG_DEFEATED, true)
	if objectives.completed():
		var reward: int = objectives.claim_reward()
		if reward > 0:
			game_state.add_gold(reward)
			game_state.set_flag(CampaignObjectives.FLAG_REGION_ONE, true)


func _on_wave_completed_for_objectives(wave_number: int) -> void:
	var max_health: float = maxf(float(game_state.wall_max_health), 1.0)
	objectives.record_wave_end(float(game_state.wall_health) / max_health)
	research.add_points(RESEARCH_POINTS_PER_WAVE)
	var intro: String = meta.start_region_overlord(wave_number)
	if intro != "":
		overseer_message.emit(intro)
	var result: Dictionary = meta.on_wave_completed(wave_number, game_state.wall_tier)
	for text: String in result["messages"]:
		overseer_message.emit(text)
	for achievement_id: String in result["achievements"]:
		achievement_unlocked.emit(achievement_id)


func _on_defence_fire(origin: Vector2, target: Enemy, damage: float) -> void:
	projectiles.fire(origin, target, damage, true)
	_sound("shot")


## Save and load (SVTLW-44, SVTLW-45). Game state is saved by SaveManager. The battlefield adds
## its own part: the wave reached, upgrade levels and where each archer stands.
var save_manager: Node = null
var _autosave_pending: bool = false
## Sound event hooks (SVTLW-50). Null-safe: the game works without the audio autoload.
var audio: Node = null


func _sound(event_name: String) -> void:
	if audio != null:
		audio.play_event(event_name)


func save_now() -> bool:
	ensure_ready()
	if save_manager == null:
		return false
	var archer_positions: Array = []
	for archer: Archer in units.archers:
		archer_positions.append([archer.position.x, archer.position.y])
	var extra: Dictionary = {
		"battlefield": {
			"wave": waves.current_wave,
			"upgrades": upgrades.levels.duplicate(),
			"archers": archer_positions,
			"buildings": constructions.completed_list(),
			"defence_levels": _defence_levels(),
			"abilities": abilities.to_dict(),
			"objectives": objectives.to_dict(),
			"boss": boss_phases.to_dict(),
			"final_battle": final_battle.to_dict(),
			"last_stand_until": _last_stand_until,
		},
	}
	# The save time lets the next load work out offline production (SVTLW-75).
	game_state.last_saved_unix = int(Time.get_unix_time_from_system())
	return save_manager.save_game(extra)


## Applies the battlefield part of the last loaded save. Call after SaveManager.load_game().
func restore_from_save() -> bool:
	ensure_ready()
	if save_manager == null or not save_manager.last_extra.has("battlefield"):
		return false
	var saved: Dictionary = save_manager.last_extra["battlefield"]
	if typeof(saved) != TYPE_DICTIONARY:
		return false
	waves.current_wave = clampi(int(saved.get("wave", 0)), 0, 1000)
	var levels: Dictionary = saved.get("upgrades", {})
	upgrades.levels = {}
	for key: Variant in levels:
		upgrades.levels[str(key)] = int(levels[key])
	upgrades.effects_changed.emit()
	for entry: Variant in saved.get("archers", []):
		if typeof(entry) == TYPE_ARRAY and entry.size() == 2:
			units.restore_unit("archer", Vector2(float(entry[0]), float(entry[1])))
	# Finished buildings come back on their slots first, so defence structures and production exist (save restore gap).
	for entry: Variant in saved.get("buildings", []):
		if typeof(entry) == TYPE_DICTIONARY:
			constructions.restore_completed(str(entry.get("building_id", "")), int(entry.get("slot", -1)))
	var levels_saved: Variant = saved.get("defence_levels", {})
	if typeof(levels_saved) == TYPE_DICTIONARY:
		for id: Variant in levels_saved:
			var structure: DefenceStructure = _defences.get(str(id), null)
			if structure != null:
				var target: int = clampi(int(levels_saved[id]), 1, structure.max_level)
				while structure.level < target and structure.upgrade():
					pass
	production.load_from_state()
	_apply_offline_progress()
	if typeof(saved.get("abilities", null)) == TYPE_DICTIONARY:
		abilities.from_dict(saved["abilities"])
	if typeof(saved.get("objectives", null)) == TYPE_DICTIONARY:
		objectives.from_dict(saved["objectives"])
	if typeof(saved.get("boss", null)) == TYPE_DICTIONARY:
		boss_phases.from_dict(saved["boss"])
	if typeof(saved.get("final_battle", null)) == TYPE_DICTIONARY:
		final_battle.from_dict(saved["final_battle"])
	_last_stand_until = int(saved.get("last_stand_until", 0))
	return true


## Adds the production earned while the game was closed, capped and with the Recursive Production bonus (SVTLW-75).
func _apply_offline_progress() -> void:
	var rates: Dictionary = {}
	for resource: String in OfflineProgress.RESOURCE_ORDER:
		rates[resource] = production.production_per_tick_for(resource) * (1.0 + _exploit.get("recursive_production_bonus", 0.0))
	var result: Dictionary = meta.offline_gain(rates, game_state.last_saved_unix, int(Time.get_unix_time_from_system()), game_state.offline_enabled)
	var gained: Dictionary = result["gained"]
	for resource: String in gained:
		if int(gained[resource]) > 0:
			game_state.add_material(resource, int(gained[resource]))
	var summary: String = OfflineProgress.format_summary(result)
	if summary != "":
		overseer_message.emit(summary)


## Prestige: converts the run into relics, then clears the run. The caller reloads the scene (SVTLW-73).
func prestige_now() -> int:
	ensure_ready()
	return meta.prestige_reset(game_state.stats.to_dict())


## Left click selects the archer, enemy or building under the cursor, for the context panel (SVTLW-52 gap).
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _built or context_panel == null:
		return
	var point: Vector2 = get_global_mouse_position()
	for archer: Archer in units.archers:
		if archer.global_position.distance_to(point) <= 24.0:
			context_panel.show_unit(archer)
			return
	for enemy: Enemy in enemies.enemies:
		if is_instance_valid(enemy) and enemy.alive and enemy.global_position.distance_to(point) <= 24.0:
			context_panel.show_enemy(enemy)
			return
	for building_id: String in _defences:
		var structure: DefenceStructure = _defences[building_id]
		if structure.global_position.distance_to(point) <= 28.0:
			context_panel.show_building(building_id)
			return


## Upgrade level of each built defence structure, for saving.
func _defence_levels() -> Dictionary:
	var out: Dictionary = {}
	for id: Variant in _defences:
		out[id] = (_defences[id] as DefenceStructure).level
	return out


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _built:
		save_now()


func _on_unit_recruited(archer: Archer) -> void:
	archer.fire_requested.connect(func(origin: Vector2, target: Enemy, damage: float) -> void:
		projectiles.fire(origin, target, damage)
		_sound("shot"))


func _on_projectile_hit(target: Enemy, damage: float) -> void:
	if is_instance_valid(target):
		# The Abomination's hide cuts light hits; heavy hits get through (SVTLW-66).
		if target == _boss_enemy:
			damage = AbominationPhases.hide_damage(damage)
			if target.definition.max_health > 0.0:
				boss_phases.update_phase(target.health / target.definition.max_health)
		# Exploitation: a higher per-hit cap, and extra damage to every enemy (SVTLW-71).
		damage = minf(damage, HIT_CAP_BASE * (1.0 + _exploit.get("overflow_damage_cap", 0.0)))
		damage *= 1.0 + _exploit.get("reality_desync_vs_machines", 0.0)
		damage_numbers.show_hit(target.global_position, damage)
		meta.on_damage_dealt(damage)
		enemies.damage_enemy(target, damage)
		var overlord_text: String = meta.damage_overlord(damage)
		if overlord_text != "":
			overseer_message.emit(overlord_text)
		effects.spawn_impact(effects.to_local(target.global_position))
		_sound("hit")


func _on_wall_destroyed() -> void:
	for line: String in meta.on_wall_destroyed():
		death_line.emit(line)
	clock.set_paused(true)
	game_over.emit()


## Wall visuals for each damage state (SVTLW-30). Colour darkens and cracks appear as health falls.
const WALL_COLOURS: Array[Color] = [
	Color(0.45, 0.36, 0.27, 1),
	Color(0.4, 0.31, 0.23, 1),
	Color(0.35, 0.26, 0.2, 1),
	Color(0.28, 0.2, 0.16, 1),
	Color(0.15, 0.1, 0.08, 1),
]


func _on_wall_state_changed(state: WallManager.DamageState) -> void:
	var wall_rect: ColorRect = get_node_or_null("Fortress/Wall")
	if wall_rect == null:
		return
	wall_rect.color = WALL_COLOURS[state]
	var crack: ColorRect = wall_rect.get_node_or_null("Cracks")
	if crack != null:
		crack.visible = state >= WallManager.DamageState.CRACKED
	var warning: ColorRect = wall_rect.get_node_or_null("CriticalWarning")
	if warning != null:
		warning.visible = state == WallManager.DamageState.CRITICAL
