## Headless tests for the projectile pool (SVTLW-36).
## Run: godot --headless --path game -s res://tests/test_projectiles.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_hit_applies_damage()
	_test_pool_reuse()
	_test_dead_target_expires()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _enemy_at(x: float) -> Enemy:
	var definition: EnemyDefinition = load("res://resources/enemies/undead_infantry.tres")
	var enemy: Enemy = Enemy.new()
	enemy.setup(definition, x, 0.0)
	enemy.global_position = Vector2(x, 0.0)
	return enemy


func _test_hit_applies_damage() -> void:
	print("hit")
	var pool: ProjectilePool = ProjectilePool.new()
	pool.initial_size = 4
	pool._ready()
	var enemy: Enemy = _enemy_at(100.0)
	var hits: Array = []
	pool.projectile_hit.connect(func(t: Enemy, d: float) -> void: hits.append([t, d]))
	pool.fire(Vector2(0.0, 0.0), enemy, 7.0)
	var ticks: int = 0
	while pool.active_count() > 0 and ticks < 100:
		pool.on_tick(ticks)
		ticks += 1
	_check(hits.size() == 1 and hits[0][0] == enemy and absf(hits[0][1] - 7.0) < 0.001, "projectile hits the target once with its damage")
	_check(pool.idle_count() == 4 and pool.active_count() == 0, "projectile returns to the pool after the hit")
	enemy.free()
	pool.free()


func _test_pool_reuse() -> void:
	print("reuse")
	var pool: ProjectilePool = ProjectilePool.new()
	pool.initial_size = 2
	pool._ready()
	var enemy: Enemy = _enemy_at(50.0)
	for shot: int in range(20):
		pool.fire(Vector2(0.0, 0.0), enemy, 1.0)
		var guard: int = 0
		while pool.active_count() > 0 and guard < 100:
			pool.on_tick(guard)
			guard += 1
	_check(pool.total_created == 2, "20 sequential shots reuse the 2 pooled projectiles")
	enemy.free()
	pool.free()


func _test_dead_target_expires() -> void:
	print("dead target")
	var pool: ProjectilePool = ProjectilePool.new()
	pool.initial_size = 2
	pool._ready()
	var enemy: Enemy = _enemy_at(200.0)
	var hits: Array = [0]
	pool.projectile_hit.connect(func(_t: Enemy, _d: float) -> void: hits[0] += 1)
	pool.fire(Vector2(0.0, 0.0), enemy, 5.0)
	enemy.take_damage(1000.0)
	pool.on_tick(0)
	_check(hits[0] == 0 and pool.active_count() == 0, "a projectile whose target died expires without a hit")
	enemy.free()
	pool.free()
