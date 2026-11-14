## Region 1 campaign objectives (SVTLW-65). Pure: the battlefield reports events and reads completion.
## The reward is granted once, by claim_reward().
class_name CampaignObjectives
extends RefCounted

const REGION_ONE_REWARD_GOLD: int = 150
const FLAG_REGION_ONE: String = "region_1_complete"

var kill_target_id: String = "armoured_brute"
var kill_target_count: int = 5
## Wall health fraction that must hold at the end of every wave.
var wall_fraction_required: float = 0.5
## Units allowed to be lost across the region.
var unit_losses_allowed: int = 0

var kills_of_target: int = 0
var unit_losses: int = 0
var wall_held: bool = true
var boss_defeated: bool = false
var _reward_claimed: bool = false


func record_kill(enemy_id: String) -> void:
	if enemy_id == kill_target_id:
		kills_of_target += 1


func record_unit_loss() -> void:
	unit_losses += 1


## Call at the end of each wave with the wall's health fraction (0 to 1).
func record_wave_end(wall_fraction: float) -> void:
	if wall_fraction < wall_fraction_required:
		wall_held = false


func record_boss_defeated() -> void:
	boss_defeated = true


func kill_objective_done() -> bool:
	return kills_of_target >= kill_target_count


func survival_objective_done() -> bool:
	return unit_losses <= unit_losses_allowed


func wall_objective_done() -> bool:
	return wall_held


func completed() -> bool:
	return kill_objective_done() and survival_objective_done() and wall_objective_done() and boss_defeated


## Returns the reward gold the first time the region is complete, and 0 after that.
func claim_reward() -> int:
	if not completed() or _reward_claimed:
		return 0
	_reward_claimed = true
	return REGION_ONE_REWARD_GOLD


func reward_claimed() -> bool:
	return _reward_claimed
