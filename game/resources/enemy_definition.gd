## Data for one enemy type (SVTLW-34). Each type has a distinct role, not only different numbers.
## Role and counter are documented in docs/NARRATIVE.md and docs/GAME_DESIGN.md.
class_name EnemyDefinition
extends Resource

@export var enemy_id: String = ""
@export var display_name: String = ""
## pressure: basic wall attacks. swarm: fast, many. wall_breaker: heavy wall damage, slow.
@export_enum("pressure", "swarm", "wall_breaker") var role: String = "pressure"
@export var max_health: float = 10.0
@export var armour: float = 0.0
## World pixels per second at 1x.
@export var move_speed: float = 30.0
@export var wall_damage: float = 3.0
@export_range(1, 1000) var attack_interval_ticks: int = 10
