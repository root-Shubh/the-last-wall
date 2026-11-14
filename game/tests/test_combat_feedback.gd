## Headless tests for combat feedback: effect pool, area damage and screen shake (SVTLW-60).
## Run: godot --headless --path game -s res://tests/test_combat_feedback.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_pool_reuse()
	_test_impact_expires()
	_test_explosion_expires()
	_test_area_damage()
	_test_shake_offset()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _make_pool(size: int) -> EffectPool:
	var pool: EffectPool = EffectPool.new()
	pool.initial_size = size
	root.add_child(pool)
	return pool


func _test_pool_reuse() -> void:
	print("pool warm and reuse")
	var pool: EffectPool = _make_pool(4)
	pool._warm()
	_check(pool.total_created == 4 and pool.idle_count() == 4, "pool warms to 4 idle effects")
	for i: int in range(4):
		pool.spawn_impact(Vector2(i, i))
	_check(pool.active_count() == 4 and pool.idle_count() == 0, "four spawns use all four effects")
	for i: int in range(EffectPool.IMPACT_TICKS):
		pool.on_tick(i)
	for i: int in range(4):
		pool.spawn_explosion(Vector2(i, i), 20.0)
	_check(pool.total_created == 4, "repeated spawns reuse effects (total_created unchanged)")
	pool.free()


func _test_impact_expires() -> void:
	print("impact expiry")
	var pool: EffectPool = _make_pool(2)
	pool.spawn_impact(Vector2(10.0, 10.0))
	_check(pool.active_count() == 1, "impact is active after spawn")
	for i: int in range(EffectPool.IMPACT_TICKS - 1):
		pool.on_tick(i)
	_check(pool.active_count() == 1, "impact still active before its lifetime ends")
	pool.on_tick(EffectPool.IMPACT_TICKS)
	_check(pool.active_count() == 0 and pool.idle_count() == 2, "impact returns to idle after its lifetime")
	pool.free()


func _test_explosion_expires() -> void:
	print("explosion expiry")
	var pool: EffectPool = _make_pool(2)
	pool.spawn_explosion(Vector2(50.0, 50.0), 40.0)
	for i: int in range(EffectPool.EXPLOSION_TICKS - 1):
		pool.on_tick(i)
	_check(pool.active_count() == 1, "explosion still active before its lifetime ends")
	pool.on_tick(EffectPool.EXPLOSION_TICKS)
	_check(pool.active_count() == 0 and pool.idle_count() == 2, "explosion returns to idle after its lifetime")
	pool.free()


func _test_area_damage() -> void:
	print("area damage falloff")
	_check(AreaDamage.area_damage_falloff(0.0, 100.0, 50.0) == 50.0, "full damage at the centre")
	_check(is_equal_approx(AreaDamage.area_damage_falloff(50.0, 100.0, 50.0), 25.0), "half damage at half radius")
	_check(AreaDamage.area_damage_falloff(100.0, 100.0, 50.0) == 0.0, "zero damage at the radius")
	_check(AreaDamage.area_damage_falloff(150.0, 100.0, 50.0) == 0.0, "zero damage beyond the radius")
	_check(AreaDamage.area_damage_falloff(-5.0, 100.0, 50.0) == 50.0, "negative distance is treated as the centre")


func _test_shake_offset() -> void:
	print("screen shake offset")
	_check(ScreenShake.shake_offset(0.0, 0) == Vector2.ZERO, "zero strength gives no shake")
	_check(ScreenShake.shake_offset(4.0, 0, false) == Vector2.ZERO, "disabled shake gives no offset")
	var first: float = ScreenShake.shake_offset(4.0, 0).length()
	var later: float = ScreenShake.shake_offset(4.0, 5).length()
	var last: float = ScreenShake.shake_offset(4.0, ScreenShake.DECAY_TICKS).length()
	_check(is_equal_approx(first, 4.0), "shake starts at full strength")
	_check(later < first and later > 0.0, "shake decays with tick")
	_check(last == 0.0, "shake is zero once decayed")
	_check(ScreenShake.shake_offset(4.0, 3) == ScreenShake.shake_offset(4.0, 3), "shake is deterministic")
