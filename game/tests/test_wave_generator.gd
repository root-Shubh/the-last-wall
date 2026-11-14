## Headless tests for the data-driven wave generator (SVTLW-59).
## Run: godot --headless --path game -s res://tests/test_wave_generator.gd
extends SceneTree

const MIN_INTERVAL: int = 1
const LAST_WAVE: int = 150

var _failures: int = 0


func _initialize() -> void:
	var table: WaveStageTable = load("res://resources/waves/wave_stages.tres")
	_check(table != null and table.stages.size() == 4, "stage table loads with 4 stages")
	if table != null:
		var generator: WaveGenerator = WaveGenerator.new()
		generator.stage_table = table
		_test_all_waves(generator)
		_test_deterministic(generator)
		_test_wave_1_vs_150(generator)
		_test_enemy_ids_exist(table)
		_test_stage_boundaries(table, generator)
		_test_wave_manager_uses_generator(generator)
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _test_all_waves(generator: WaveGenerator) -> void:
	print("waves 1 to 150")
	var bad: Array = []
	var min_seen: int = 1000000
	for n: int in range(1, LAST_WAVE + 1):
		var definition: WaveDefinition = generator.generate(n)
		if definition == null or definition.enemy_count < 1 or definition.spawn_interval_ticks < MIN_INTERVAL:
			bad.append(n)
			continue
		min_seen = mini(min_seen, definition.spawn_interval_ticks)
	_check(bad.is_empty(), "every wave 1 to 150 has count >= 1 and interval >= minimum")
	_check(generator.generate(LAST_WAVE + 1) == null, "wave 151 has no definition")
	_check(generator.generate(0) == null, "wave 0 has no definition")
	_check(min_seen >= 6, "intervals never drop below the Onslaught floor")


func _test_deterministic(generator: WaveGenerator) -> void:
	print("determinism")
	var same: bool = true
	for n: int in range(1, LAST_WAVE + 1):
		var a: WaveDefinition = generator.generate(n)
		var b: WaveDefinition = generator.generate(n)
		if a.enemy_type_id != b.enemy_type_id or a.enemy_count != b.enemy_count or a.spawn_interval_ticks != b.spawn_interval_ticks:
			same = false
	_check(same, "same wave number always gives the same definition")
	var fresh: WaveGenerator = WaveGenerator.new()
	fresh.stage_table = generator.stage_table
	_check(fresh.generate(77).enemy_type_id == generator.generate(77).enemy_type_id, "a new generator gives the same result")


func _test_wave_1_vs_150(generator: WaveGenerator) -> void:
	print("composition varies by stage")
	var first: WaveDefinition = generator.generate(1)
	var last: WaveDefinition = generator.generate(LAST_WAVE)
	_check(first.enemy_count != last.enemy_count, "wave 1 and wave 150 differ in count")
	_check(first.enemy_count < last.enemy_count, "wave 150 is larger than wave 1")
	var mix_first: Dictionary = _mix(generator, 1, 30)
	var mix_last: Dictionary = _mix(generator, 111, 150)
	_check(mix_first != mix_last, "wave 1 and wave 150 differ in enemy mix")
	_check(mix_last.has("armoured_brute") and not mix_first.has("armoured_brute"), "armoured_brute appears only in later stages")


## Counts which enemy ids appear across a range of waves.
func _mix(generator: WaveGenerator, from: int, to: int) -> Dictionary:
	var counts: Dictionary = {}
	for n: int in range(from, to + 1):
		var id: String = generator.generate(n).enemy_type_id
		counts[id] = counts.get(id, 0) + 1
	return counts


func _test_enemy_ids_exist(table: WaveStageTable) -> void:
	print("enemy ids")
	var missing: Array = []
	for stage: WaveStage in table.stages:
		for id: String in stage.enemy_ids:
			if not ResourceLoader.exists("res://resources/enemies/%s.tres" % id):
				missing.append(id)
	_check(missing.is_empty(), "every enemy id used in the stage table has a resource")


func _test_stage_boundaries(table: WaveStageTable, generator: WaveGenerator) -> void:
	print("stage boundaries")
	var expected: Array = [["Skirmish", 1, 30], ["Swarm", 31, 70], ["Siege", 71, 110], ["Onslaught", 111, 150]]
	for pair: Array in expected:
		var first: WaveStage = table.stage_for_wave(pair[1])
		var last: WaveStage = table.stage_for_wave(pair[2])
		_check(first != null and first.stage_name == pair[0], "%s starts at wave %d" % [pair[0], pair[1]])
		_check(last != null and last.stage_name == pair[0], "%s ends at wave %d" % [pair[0], pair[2]])
	_check(generator.generate(31).enemy_count == 12, "wave 31 uses the Swarm base count")
	_check(generator.generate(31).spawn_interval_ticks == 16, "wave 31 uses the Swarm base interval")


func _test_wave_manager_uses_generator(generator: WaveGenerator) -> void:
	print("wave manager")
	var manager: WaveManager = WaveManager.new()
	manager.generator = generator
	var started: Array = [0]
	manager.wave_started.connect(func(_n: int) -> void: started[0] += 1)
	_check(manager.start_next_wave() and started[0] == 1, "WaveManager starts wave 1 from the generator without a catalog")
	manager.free()
