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
var hud: TopBar
var settings: SettingsStore
var damage_numbers: DamageNumbers
## Number of screen shakes started, for tests.
var shake_count: int = 0
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
	settings = SettingsStore.new()
	settings.load_from()
	damage_numbers = DamageNumbers.new()
	damage_numbers.settings = settings
	add_child(damage_numbers)
	_build_systems()
	_connect_systems()
	hud = TopBar.new()
	add_child(hud)
	hud.bind(game_state, clock, waves, wall)


## Shakes the battlefield briefly. Does nothing when screen shake is turned off (SVTLW-37).
func shake(strength: float) -> void:
	ensure_ready()
	if not settings.screen_shake_enabled:
		return
	shake_count += 1
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", Vector2(strength, -strength * 0.5), 0.05)
	tween.tween_property(self, "position", Vector2.ZERO, 0.1)


## Starts the next wave from the catalog. Returns false if one is already running.
func start_wave() -> bool:
	ensure_ready()
	return waves.start_next_wave()


func recruit_archer(at: Vector2) -> Archer:
	ensure_ready()
	return units.recruit("archer", at)


## Advances the battlefield by whole ticks. The real clock calls this on each tick too.
func step_ticks(count: int) -> void:
	ensure_ready()
	for i: int in range(count):
		clock.advance(1.0 / SimulationClock.TICKS_PER_SECOND + 0.0001)


func _build_systems() -> void:
	waves = WaveManager.new()
	waves.catalog = load("res://resources/waves/m1_catalog.tres")
	add_child(waves)

	enemies = EnemyManager.new()
	enemies.definitions = [
		load("res://resources/enemies/undead_infantry.tres"),
		load("res://resources/enemies/runner.tres"),
		load("res://resources/enemies/armoured_brute.tres"),
	]
	add_child(enemies)

	projectiles = ProjectilePool.new()
	add_child(projectiles)

	units = UnitManager.new()
	units.unit_definitions = [load("res://resources/units/archer.tres")]
	units.state = game_state
	add_child(units)

	rewards = RewardTracker.new()
	add_child(rewards)
	rewards.bind(enemies, waves, game_state)

	wall = WallManager.new()
	wall.armour = 1.0
	add_child(wall)
	wall.bind(game_state)


func _connect_systems() -> void:
	clock.tick_advanced.connect(_on_tick)
	waves.enemy_spawn_requested.connect(func(id: String) -> void: enemies.spawn(id))
	enemies.enemy_removed.connect(func(_e: Enemy) -> void: waves.report_enemy_removed())
	enemies.wall_attacked.connect(func(damage: float) -> void:
		wall.attack(damage)
		shake(clampf(damage, 1.0, 6.0)))
	units.unit_recruited.connect(_on_unit_recruited)
	projectiles.projectile_hit.connect(_on_projectile_hit)
	wall.wall_destroyed.connect(_on_wall_destroyed)
	wall.damage_state_changed.connect(_on_wall_state_changed)
	_on_wall_state_changed(wall.current_state())


func _on_tick(tick_index: int) -> void:
	waves.on_tick(tick_index)
	enemies.on_tick(tick_index)
	units.on_tick(tick_index, enemies.enemies)
	projectiles.on_tick(tick_index)
	wall.on_tick(tick_index)


func _on_unit_recruited(archer: Archer) -> void:
	archer.fire_requested.connect(func(origin: Vector2, target: Enemy, damage: float) -> void:
		projectiles.fire(origin, target, damage))


func _on_projectile_hit(target: Enemy, damage: float) -> void:
	if is_instance_valid(target):
		damage_numbers.show_hit(target.global_position, damage)
		target.take_damage(damage)


func _on_wall_destroyed() -> void:
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
