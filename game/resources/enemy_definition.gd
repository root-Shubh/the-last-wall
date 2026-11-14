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
## Countermeasure roles (SVTLW-72) each carry one tactical rule; see docs/NARRATIVE.md "Machine countermeasures".
@export_enum("pressure", "swarm", "wall_breaker", "shield_bearer", "climber",
	"resource_suppressor", "damage_limiter", "calculation_guardian", "process_terminator",
	"memory_devourer", "recursive_sentinel") var role: String = "pressure"
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
## Climber and process terminator: when true, only the ids in MELEE_DEFENDER_IDS can stop it.
@export var melee_counter_only: bool = false
## Damage limiter (SVTLW-72): no single hit deals more than this. Zero disables it.
@export var hit_cap: float = 0.0
## Calculation guardian (SVTLW-72): a single hit above this is ignored entirely. Zero disables it.
@export var immune_above_hit: float = 0.0
## Memory devourer (SVTLW-72): while alive, one research effect is disabled. Integration reads this flag.
@export var disables_research_while_alive: bool = false
## Recursive sentinel (SVTLW-72): health gained each time it is hit, up to max_health. Zero disables it.
## Data only until battlefield integration applies it.
@export var heal_on_hit: float = 0.0

## Faction (SVTLW-81): "" for the original enemies, "corrupted" or "ancient_horde". Documented in docs/NARRATIVE.md.
@export var faction: String = ""
## Corrupted regeneration (SVTLW-81): health restored per second while alive, capped at max_health. Zero disables it.
@export var regen_per_second: float = 0.0
## Corrupted poison (SVTLW-81): damage per second its poison deals while the enemy is alive. Zero disables it.
## Battlefield wiring for regen and poison is a later story; these fields are the data contract.
@export var poison_damage_per_second: float = 0.0

## Defender ids that count as melee for melee_counter_only enemies. Units not yet in the game.
const MELEE_DEFENDER_IDS: PackedStringArray = ["spearman", "swordsman"]


## Pure rule for SVTLW-72 hit limits: returns the damage this enemy takes from one raw hit.
## Guardian immunity is checked on the raw hit first, then the damage limiter caps what remains.
func damage_after_hit_rules(raw_damage: float) -> float:
	var amount: float = maxf(raw_damage, 0.0)
	if immune_above_hit > 0.0 and amount > immune_above_hit:
		return 0.0
	if hit_cap > 0.0:
		amount = minf(amount, hit_cap)
	return amount
