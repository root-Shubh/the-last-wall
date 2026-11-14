## Passive production earned while the game was closed (SVTLW-75).
## Pure: no nodes, no clock reads. The caller supplies elapsed seconds and rates.
## Offline play never simulates battles; it only adds passive production, capped at cap_seconds.
class_name OfflineProgress
extends RefCounted

const TICKS_PER_SECOND: int = 10
const DEFAULT_CAP_SECONDS: int = 8 * 60 * 60
## Resource ids in the order the summary lists them.
const RESOURCE_ORDER: Array[String] = ["wood", "stone", "iron"]


## Returns {"gained": {resource: int}, "seconds_used": int}.
## Negative elapsed (clock moved back) and disabled offline progress both give zero gain.
static func compute(production_per_tick_by_resource: Dictionary, elapsed_seconds: int, cap_seconds: int, enabled: bool) -> Dictionary:
	var gained: Dictionary = {}
	for resource: String in RESOURCE_ORDER:
		gained[resource] = 0
	for resource: Variant in production_per_tick_by_resource:
		gained[str(resource)] = 0
	var seconds_used: int = 0
	if enabled and elapsed_seconds > 0:
		seconds_used = mini(elapsed_seconds, maxi(cap_seconds, 0))
		var ticks: int = seconds_used * TICKS_PER_SECOND
		for resource: Variant in production_per_tick_by_resource:
			var rate: float = maxf(float(production_per_tick_by_resource[resource]), 0.0)
			gained[str(resource)] = int(floor(rate * ticks))
	return {"gained": gained, "seconds_used": seconds_used}


## Seconds between the last save and now. Returns 0 when no save time is recorded.
## A negative result means the clock moved back; compute() treats it as no elapsed time.
static func elapsed_since(last_saved_unix: int, now_unix: int) -> int:
	if last_saved_unix <= 0:
		return 0
	return now_unix - last_saved_unix


## Text shown on return, for example "Offline production (2h 0m): +30 wood, +12 stone, +0 iron."
static func format_summary(result: Dictionary) -> String:
	var gained: Dictionary = result.get("gained", {})
	var seconds_used: int = int(result.get("seconds_used", 0))
	var parts: Array[String] = []
	for resource: String in RESOURCE_ORDER:
		parts.append("+%d %s" % [int(gained.get(resource, 0)), resource])
	for resource: Variant in gained:
		if not RESOURCE_ORDER.has(str(resource)):
			parts.append("+%d %s" % [int(gained[resource]), str(resource)])
	return "Offline production (%s): %s." % [_duration_text(seconds_used), ", ".join(parts)]


static func _duration_text(seconds: int) -> String:
	var hours: int = seconds / 3600
	var minutes: int = (seconds % 3600) / 60
	return "%dh %dm" % [hours, minutes]
