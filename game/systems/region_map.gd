## Maps a wave number to its campaign region (SVTLW-80). Pure: no scene or autoload access.
class_name RegionMap
extends RefCounted

const REGION_PATHS: PackedStringArray = [
	"res://resources/regions/fallen_kingdom.tres",
	"res://resources/regions/ashen_forest.tres",
	"res://resources/regions/iron_wastes.tres",
	"res://resources/regions/cursed_highlands.tres",
	"res://resources/regions/dead_capital.tres",
]

var regions: Array[Region] = []


func _init(paths: PackedStringArray = REGION_PATHS) -> void:
	for path: String in paths:
		var region: Region = load(path) as Region
		if region != null:
			regions.append(region)


## Returns the region that covers a wave number, or null when no region does.
func region_for_wave(wave_number: int) -> Region:
	for region: Region in regions:
		if wave_number >= region.first_wave and wave_number <= region.last_wave:
			return region
	return null
