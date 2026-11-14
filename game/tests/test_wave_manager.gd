## Headless tests for WaveManager and the M1 wave catalog (SVTLW-26).
## Run: godot --headless --path game -s res://tests/test_wave_manager.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var catalog: WaveCatalog = load("res://resources/waves/m1_catalog.tres")
	_check(catalog != null and catalog.waves.size() == 10, "M1 catalog loads with 10 waves")
	if catalog != null:
		_test_basic_wave(catalog)
		_test_wave_order_and_end(catalog)
		_test_auto_start(catalog)
	_test_empty_wave_completes()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _manager(catalog: WaveCatalog, auto: bool) -> WaveManager:
	var manager: WaveManager = WaveManager.new()
	manager.catalog = catalog
	manager.auto_start = auto
	return manager


## Drives ticks until the spawn request count reaches the wave's total, then kills them all.
func _run_wave_to_completion(manager: WaveManager, guard: int) -> int:
	var spawned: Array = [0]
	manager.enemy_spawn_requested.connect(func(_id: String) -> void: spawned[0] += 1)
	var ticks: int = 0
	while manager.is_running() and ticks < guard:
		manager.on_tick(ticks)
		ticks += 1
		while spawned[0] > 0 and manager.is_running():
			spawned[0] -= 1
			manager.report_enemy_removed()
	return ticks


func _test_basic_wave(catalog: WaveCatalog) -> void:
	print("basic wave")
	var manager: WaveManager = _manager(catalog, false)
	var started: Array = [0]
	manager.wave_started.connect(func(_n: int) -> void: started[0] += 1)
	_check(manager.start_next_wave(), "starts wave 1")
	_check(started[0] == 1, "wave_started emitted")
	_check(not manager.start_next_wave(), "cannot start a second wave while running")
	var ids: Array = []
	manager.enemy_spawn_requested.connect(func(id: String) -> void: ids.append(id))
	for tick: int in range(20):
		manager.on_tick(tick)
	_check(ids.size() == 1 and ids[0] == "undead_infantry", "first enemy spawns at the interval with the right type")
	manager.free()


func _test_wave_order_and_end(catalog: WaveCatalog) -> void:
	print("waves 1 to 10")
	var manager: WaveManager = _manager(catalog, false)
	var completed: Array = []
	manager.wave_completed.connect(func(n: int) -> void: completed.append(n))
	var finished_all: Array = [false]
	manager.all_waves_completed.connect(func() -> void: finished_all[0] = true)
	for n: int in range(10):
		_check(manager.start_next_wave(), "start wave %d" % (n + 1))
		_run_wave_to_completion(manager, 10000)
	_check(completed.size() == 10 and completed[9] == 10, "all 10 waves complete in order")
	_check(not manager.start_next_wave(), "no wave 11 in the catalog")
	_check(finished_all[0], "all_waves_completed emitted")
	manager.free()


func _test_auto_start(catalog: WaveCatalog) -> void:
	print("auto start")
	var manager: WaveManager = _manager(catalog, true)
	var completions: Array = [0]
	manager.wave_completed.connect(func(_n: int) -> void: completions[0] += 1)
	manager.start_next_wave()
	# Run ticks and kills until wave 1 completes once. Auto start then begins wave 2.
	var spawned: Array = [0]
	manager.enemy_spawn_requested.connect(func(_id: String) -> void: spawned[0] += 1)
	var ticks: int = 0
	while completions[0] == 0 and ticks < 10000:
		manager.on_tick(ticks)
		ticks += 1
		while spawned[0] > 0:
			spawned[0] -= 1
			manager.report_enemy_removed()
	_check(manager.current_wave == 2 and manager.is_running(), "auto start begins wave 2 after wave 1")
	manager.free()


func _test_empty_wave_completes() -> void:
	print("empty wave")
	var catalog: WaveCatalog = WaveCatalog.new()
	var empty: WaveDefinition = WaveDefinition.new()
	empty.wave_number = 1
	empty.enemy_count = 0
	catalog.waves = [empty]
	var manager: WaveManager = _manager(catalog, false)
	var completed: Array = [0]
	manager.wave_completed.connect(func(_n: int) -> void: completed[0] += 1)
	manager.start_next_wave()
	_check(completed[0] == 1 and not manager.is_running(), "a zero-enemy wave completes immediately")
	manager.free()
