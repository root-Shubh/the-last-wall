## Kill and wave rewards (SVTLW-27). Listens to the enemy manager and wave manager, grants gold
## through GameState, and keeps the counters the post-wave summary needs.
class_name RewardTracker
extends Node

signal reward_granted(amount: int, reason: String)

## Survival bonus per cleared wave is this value times the wave number.
@export var survival_bonus_per_wave: int = 10

## Extra gold per kill from upgrades (SVTLW-39). Zero until the upgrade is bought.
@export var kill_gold_bonus: int = 0

var kills: int = 0
var gold_from_kills: int = 0
var gold_from_waves: int = 0
var state: Node = null


## Connects to the managers. Pass the gold source explicitly so the tracker is testable.
func bind(enemies: EnemyManager, waves: WaveManager, gold_source: Node) -> void:
	state = gold_source
	enemies.enemy_removed.connect(_on_enemy_removed)
	waves.wave_completed.connect(_on_wave_completed)


func reset() -> void:
	kills = 0
	gold_from_kills = 0
	gold_from_waves = 0


func _on_enemy_removed(enemy: Enemy) -> void:
	kills += 1
	var amount: int = enemy.definition.gold_reward + kill_gold_bonus
	if amount <= 0:
		return
	gold_from_kills += amount
	state.add_gold(amount)
	reward_granted.emit(amount, "kill")


func _on_wave_completed(wave_number: int) -> void:
	var amount: int = survival_bonus_per_wave * wave_number
	if amount <= 0:
		return
	gold_from_waves += amount
	state.add_gold(amount)
	reward_granted.emit(amount, "wave %d survived" % wave_number)
