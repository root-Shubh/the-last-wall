## Prints the balance table and findings as Markdown for docs/BALANCE.md (SVTLW-91). Not a unit test.
## Run: godot --headless --path game -s res://tests/balance_report.gd
extends SceneTree


func _initialize() -> void:
	var builds: Array[Dictionary] = BalanceSim.standard_builds()
	print("| Build | DPS vs reference wave | Mean time to kill (s) | Wall damage per wave | Survival | Income per wave | Build cost | DPS per 100 gold |")
	print("|---|---|---|---|---|---|---|---|")
	for build: Dictionary in builds:
		var r: Dictionary = BalanceSim.evaluate(build)
		print("| %s | %.2f | %.2f | %.1f | %.0f%% | %.1f | %d | %.2f |" % [
			build["name"], r["dps"], r["ttk"], r["wall_damage"], 100.0 * r["survival"],
			r["income"], r["cost"], r["dps_per_100_gold"]])
	print("")
	print("Findings:")
	var findings: Array[String] = BalanceSim.findings(builds)
	if findings.is_empty():
		print("- none")
	for line: String in findings:
		print("- %s" % line)
	quit(0)
