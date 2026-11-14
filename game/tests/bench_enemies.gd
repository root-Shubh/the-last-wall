## Enemy load benchmark (SVTLW-90). Not a unit test: the name does not match test_*.gd, so run_tests skips it.
## Spawns 100, 250, 500 and 1000 enemies through EnemyManager and times 600 simulation ticks at each size.
## Run: godot --headless --path game -s res://tests/bench_enemies.gd
extends SceneTree

const SIZES: Array[int] = [100, 250, 500, 1000]
const TICKS: int = 600
const ENEMY_IDS: Array[String] = ["undead_infantry", "runner", "armoured_brute", "shield_bearer", "climber"]


func _initialize() -> void:
	print("enemy tick benchmark, %d ticks per size, headless" % TICKS)
	print("enemies  avg_tick_ms  max_tick_ms  objects  static_mem_mb")
	for size: int in SIZES:
		_run(size)
	quit(0)


func _run(size: int) -> void:
	var manager: EnemyManager = EnemyManager.new()
	for id: String in ENEMY_IDS:
		var definition: EnemyDefinition = load("res://resources/enemies/%s.tres" % id)
		manager.definitions.append(definition)
	root.add_child(manager)

	for i: int in range(size):
		manager.spawn(ENEMY_IDS[i % ENEMY_IDS.size()])

	var total_usec: int = 0
	var worst_usec: int = 0
	for tick: int in range(TICKS):
		var start: int = Time.get_ticks_usec()
		manager.on_tick(tick)
		var elapsed: int = Time.get_ticks_usec() - start
		total_usec += elapsed
		worst_usec = maxi(worst_usec, elapsed)

	var objects: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	print("%7d  %12.4f  %11.4f  %7d  %13.2f" % [
		size, float(total_usec) / TICKS / 1000.0, float(worst_usec) / 1000.0, objects, memory_mb])

	root.remove_child(manager)
	manager.free()
