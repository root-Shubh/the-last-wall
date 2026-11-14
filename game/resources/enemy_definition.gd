## Data for one enemy type (SVTLW-34). Each type has a distinct role, not only different numbers.
## Role and counter are documented in docs/NARRATIVE.md and docs/GAME_DESIGN.md.
class_name EnemyDefinition
extends Resource

@export var enemy_id: String = ""
@export var display_name: String = ""
## Role and counter (SVTLW-57). Each role has one job and one answer to it:
## pressure: basic wall attacks. Counter: any defender, the baseline.
## swarm: fast, many. Counter: area damage that hits several enemies at once.
## wall_breaker: heavy wall damage, slow. Counter: kill it before it reaches the wall.
## shield_bearer: while alive, cuts damage taken by allies within shield_radius by shield_fraction.
##   Counter: focus it first. Its shield does not protect itself and stops when it dies.
## climber: scales the wall face and attacks from above, so its hits ignore wall armour
##   (bypass_wall_armour). Counter: only melee defenders (spearman, swordsman) can stop it;
##   archers cannot (melee_counter_only). Until those defenders exist it cannot be stopped.
@export_enum("pressure", "swarm", "wall_breaker", "shield_bearer", "climber") var role: String = "pressure"
@export var max_health: float = 10.0
@export var armour: float = 0.0
## World pixels per second at 1x.
@export var move_speed: float = 30.0
@export var wall_damage: float = 3.0
@export_range(1, 1000) var attack_interval_ticks: int = 10
## Gold granted when this enemy is killed (SVTLW-27).
@export var gold_reward: int = 1
## Optional material granted on kill (SVTLW-56): "wood", "stone" or "iron". Empty grants none.
@export var resource_reward_type: String = ""
@export var resource_reward_amount: int = 0
## Shield bearer only: radius in world pixels where allies take less damage. Zero disables it.
@export var shield_radius: float = 0.0
## Shield bearer only: fraction of incoming damage an allied enemy in range does not take.
## The strongest shield in range applies; shields do not stack.
@export_range(0.0, 1.0) var shield_fraction: float = 0.0
## Climber only: attacks on the wall ignore the wall's flat armour (WallManager.armour).
@export var bypass_wall_armour: bool = false
## Climber only: when true, only the ids in MELEE_DEFENDER_IDS can stop it.
@export var melee_counter_only: bool = false

## Defender ids that count as melee for melee_counter_only enemies. Units not yet in the game.
const MELEE_DEFENDER_IDS: PackedStringArray = ["spearman", "swordsman"]
