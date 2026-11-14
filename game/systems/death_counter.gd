## Death count and Overseer comments (SVTLW-79). Atmospheric text only; no gameplay effect.
## Each line fires when the cumulative death count reaches its threshold, so each fires once.
class_name DeathCounter
extends RefCounted

const THRESHOLDS: Array[int] = [1, 10, 100, 347]
const LINES: Dictionary = {
	1: "Defensive failure. Restarting simulation.",
	10: "Another failed attempt. Your persistence is statistically unusual.",
	100: "One hundred failed simulations. The wall still stands. Mostly.",
	347: "YOU HAVE FAILED 347 TIMES. WHY DO YOU CONTINUE?",
}

var stats: StatsTracker = null


func _init(stats_source: StatsTracker) -> void:
	stats = stats_source


## Counts one death and returns the Overseer lines whose thresholds that death reached.
func on_death() -> Array[String]:
	stats.record_death()
	var fired: Array[String] = []
	for threshold: int in THRESHOLDS:
		if stats.deaths == threshold:
			fired.append(LINES[threshold])
	return fired
