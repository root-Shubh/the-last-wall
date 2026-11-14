## Logic tests for abilities, Region 1 objectives, The Abomination, Wave 1000 and the ending (SVTLW-64, 65, 66, 83, 84).
## Run: godot --headless --path game -s res://tests/test_battle_systems.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_abilities()
	_test_objectives()
	_test_abomination()
	_test_final_battle()
	_test_ending()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_abilities() -> void:
	print("abilities")
	var abilities: Abilities = Abilities.new()
	_check(abilities.all_ids().size() == 4, "four active abilities exist")
	_check(not abilities.is_unlocked(Abilities.RAIN_OF_ARROWS, []), "rain of arrows is locked before its research")
	_check(abilities.is_unlocked(Abilities.RAIN_OF_ARROWS, ["mil_volley_drill"]), "rain of arrows unlocks with its research")
	_check(not abilities.use(Abilities.RAIN_OF_ARROWS, 0, []), "a locked ability cannot be used")
	var research: Array = ["mil_volley_drill"]
	_check(abilities.use(Abilities.RAIN_OF_ARROWS, 10, research), "an unlocked ability can be used")
	_check(not abilities.use(Abilities.RAIN_OF_ARROWS, 11, research), "a used ability is on cooldown")
	_check(abilities.cooldown_remaining(Abilities.RAIN_OF_ARROWS, 11) == 299, "cooldown counts down in ticks")
	_check(abilities.use(Abilities.RAIN_OF_ARROWS, 10 + Abilities.DEFINITIONS[Abilities.RAIN_OF_ARROWS]["cooldown_ticks"], research), "the ability works again after its cooldown")
	_check(not abilities.is_unlocked("made_up", research), "an unknown ability is never unlocked")


func _test_objectives() -> void:
	print("campaign objectives")
	var objectives: CampaignObjectives = CampaignObjectives.new()
	_check(not objectives.completed(), "region 1 is not complete at the start")
	for i: int in range(objectives.kill_target_count):
		objectives.record_kill(objectives.kill_target_id)
	_check(objectives.kill_objective_done(), "the kill objective completes at the target count")
	objectives.record_kill("runner")
	_check(objectives.kills_of_target == objectives.kill_target_count, "kills of other enemies do not count")
	objectives.record_wave_end(0.2)
	_check(not objectives.wall_objective_done(), "the wall objective fails when health drops below the requirement")
	objectives = CampaignObjectives.new()
	objectives.record_unit_loss()
	_check(not objectives.survival_objective_done(), "losing a unit fails the survival objective")
	objectives = CampaignObjectives.new()
	for i: int in range(objectives.kill_target_count):
		objectives.record_kill(objectives.kill_target_id)
	objectives.record_boss_defeated()
	_check(objectives.completed(), "region 1 completes when every objective is met and the boss is defeated")
	_check(objectives.claim_reward() == CampaignObjectives.REGION_ONE_REWARD_GOLD, "the completion reward is granted")
	_check(objectives.claim_reward() == 0, "the completion reward is granted only once")


func _test_abomination() -> void:
	print("the abomination")
	_check(AbominationPhases.hide_damage(4.0) < 4.0, "light hits are reduced by the hide")
	_check(AbominationPhases.hide_damage(20.0) == 20.0, "heavy hits are not reduced")
	_check(AbominationPhases.phase_for_fraction(1.0) == 1, "full health is phase 1")
	_check(AbominationPhases.phase_for_fraction(0.5) == 2, "half health is phase 2")
	_check(AbominationPhases.phase_for_fraction(0.1) == 4, "near death is the last phase")
	var boss: AbominationPhases = AbominationPhases.new()
	_check(boss.update_phase(0.6), "the phase changes when the threshold is crossed")
	_check(not boss.update_phase(0.6), "the phase does not change twice for one threshold")
	_check(boss.claim_reward(false) == 0, "no reward while the boss is alive")
	_check(boss.claim_reward(true) == AbominationPhases.REWARD_GOLD, "the reward is granted once the boss is dead")
	_check(boss.claim_reward(true) == 0, "the boss reward is granted only once")


func _test_final_battle() -> void:
	print("wave 1000 and the final battle")
	_check(FinalBattle.is_final_wave(1000) and not FinalBattle.is_final_wave(999), "wave 1000 is the final wave")
	var battle: FinalBattle = FinalBattle.new()
	_check(battle.begin(), "the final battle starts")
	_check(not battle.begin(), "the final battle cannot start twice")
	_check(battle.phase == 1, "the battle begins in phase 1")
	var overlord_events: int = 0
	for tick: int in range(FinalBattle.OVERLORD_INTERVAL_TICKS):
		if battle.on_tick(4).has("overlord"):
			overlord_events += 1
	_check(overlord_events == 1, "phase 1 sends Overlords on an interval")
	for i: int in range(FinalBattle.PHASE_KILL_TARGETS[0]):
		battle.record_kill("runner")
	_check(battle.phase == 2, "reaching the first kill target starts phase 2")
	var intervened: bool = false
	for tick: int in range(FinalBattle.INTERVENTION_INTERVAL_TICKS):
		if battle.on_tick(4).has("intervention"):
			intervened = true
			break
	_check(intervened, "phase 2 has Overseer interventions")
	_check(battle.disabled_until.size() >= 1, "an intervention switches off a defence slot")
	for i: int in range(FinalBattle.PHASE_KILL_TARGETS[1] - FinalBattle.PHASE_KILL_TARGETS[0]):
		battle.record_kill("runner")
	_check(battle.phase == 3, "reaching the second kill target starts phase 3")
	for i: int in range(FinalBattle.PHASE_KILL_TARGETS[2] - FinalBattle.PHASE_KILL_TARGETS[1]):
		battle.record_kill("runner")
	_check(battle.victory and not battle.active, "reaching the last kill target wins the battle")
	_check(battle.disabled_until.is_empty(), "defences are switched back on after victory")


func _test_ending() -> void:
	print("collapse and ending")
	var ending: EndingSequence = EndingSequence.new()
	_check(not ending.start(true), "the ending does not play again once it has been seen")
	_check(ending.start(false), "the ending plays the first time")
	_check(ending.is_playing(), "the ending is playing")
	_check(ending.current_step()["text"] != "", "the first step has text")
	var ticks: int = 0
	while ending.is_playing() and ticks < 10000:
		ending.on_tick()
		ticks += 1
	_check(ending.is_finished(), "the ending finishes")
	_check(not ending.start(false), "a finished ending does not replay in the same session")
	var texts: Array[String] = []
	for step: Dictionary in EndingSequence.STEPS:
		texts.append(step["text"])
	_check(texts.has("SIMULATION TERMINATED"), "the ending shows SIMULATION TERMINATED")
	_check(texts.has("One minute had passed."), "the ending includes the wake scene")
	_check(EndingSequence.STEPS[EndingSequence.STEPS.size() - 1]["style"] == "credits", "the ending finishes on the credits")
