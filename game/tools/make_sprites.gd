## Asset build step (not a test). Writes the pixel-art sprites to res://art/sprites/*.png.
## Each sprite is a grid of characters; each character is one pixel mapped through PALETTE.
## Run after editing a grid:  godot --headless --path game -s res://tools/make_sprites.gd
extends SceneTree

const OUT_DIR: String = "res://art/sprites"

const PALETTE: Dictionary = {
	".": Color(0, 0, 0, 0),
	"k": Color(0.09, 0.07, 0.10),
	"w": Color(0.86, 0.82, 0.74),
	"s": Color(0.52, 0.49, 0.45),
	"d": Color(0.30, 0.28, 0.26),
	"b": Color(0.42, 0.27, 0.15),
	"B": Color(0.62, 0.44, 0.26),
	"g": Color(0.28, 0.48, 0.22),
	"G": Color(0.46, 0.70, 0.34),
	"n": Color(0.22, 0.36, 0.18),
	"r": Color(0.62, 0.20, 0.18),
	"R": Color(0.82, 0.38, 0.32),
	"y": Color(0.90, 0.70, 0.26),
	"Y": Color(1.00, 0.90, 0.55),
	"p": Color(0.92, 0.77, 0.61),
	"c": Color(0.16, 0.33, 0.52),
	"C": Color(0.38, 0.60, 0.80),
	"x": Color(0.52, 0.55, 0.60),
	"X": Color(0.80, 0.83, 0.88),
	"e": Color(0.88, 0.85, 0.74),
	"v": Color(0.40, 0.20, 0.52),
	"V": Color(0.66, 0.40, 0.78),
	"o": Color(0.78, 0.44, 0.14),
	"m": Color(0.36, 0.44, 0.62),
	"M": Color(0.56, 0.62, 0.78),
	"q": Color(0.44, 0.40, 0.36),
}

const ARCHER: Array[String] = [
	"................",
	".....kkkk.......",
	"....kCCCCk......",
	"....kpppbk......",
	"....kpkpkk......",
	"....kpppbk......",
	"...kCCCCCCk.....",
	"..kCCwCCCCCk....",
	"..kCCCCCCCCk....",
	"..kCCCCCCCCk....",
	"...kCCCCCCk.....",
	"...kcckkcck.....",
	"...kcc..kcck....",
	"...kcc..kcck....",
	"...kk....kk.....",
	"................",
]

const INFANTRY: Array[String] = [
	"................",
	"....kkkkkk......",
	"...kgggggggk....",
	"...kgekgkegk....",
	"...kggggggggk...",
	"...kgkkkkkggk...",
	"....kgggggk.....",
	"...kgggggggk....",
	"..kgggggggggk...",
	"..kgggkkkggggk..",
	"...kggggggggk...",
	"....kgk..kgk....",
	"....kgk..kgk....",
	"...kkk....kkk...",
	"................",
	"................",
]

const RUNNER: Array[String] = [
	"................",
	".....kkkkk......",
	"....kYYYYYk.....",
	"....kYkYkYk.....",
	"....kYYYYYk.....",
	"...kkkkkkkk.....",
	"..kRRRRRRRRk....",
	".kRRRRRRRRRRk...",
	".kRRRRRRRRRRk...",
	"..kRRRRRRRRk....",
	"...kkkkkkkk.....",
	"...kr.k..kr.....",
	"..kr...k...kr...",
	"..kk.........k..",
	"................",
	"................",
]

const BRUTE: Array[String] = [
	"................",
	"...kkkkkkkk.....",
	"..kdddddddddk...",
	"..kdsssssssdk...",
	"..kdsrsssrsdk...",
	"..kddddddddddk..",
	".kdddddddddddk..",
	".kdssssssssssdk.",
	".kdsssksksssdk..",
	".kdssssssssssdk.",
	"..kddddddddddk..",
	"...kkk....kkk...",
	"...kdk....kdk...",
	"..kkkk....kkkk..",
	"................",
	"................",
]

const SHIELD_BEARER: Array[String] = [
	"................",
	".....kkkkk......",
	"....kMMMMMk.....",
	"....kMpMpMk.....",
	"...kkMMMMMkk....",
	"..kMMMMMMMMMk...",
	"..kMMMMMMMMMk...",
	"..kMMMMMMMMMk...",
	"..kMMMMMMMMMk...",
	"...kMMMMMMMk....",
	"....kkkkkkk.....",
	"....kmk.kmk.....",
	"....kmk.kmk.....",
	"...kkkk.kkkk....",
	"................",
	"................",
]

const CLIMBER: Array[String] = [
	"................",
	"...kkkkkkk......",
	"..kvvvvvvvk.....",
	"..kvVvvVvvk.....",
	"..kvvvvvvvkk....",
	"...kvvvvvvvk....",
	"..kvvvvvvvvvk...",
	".kvvvvvvvvvvk...",
	".kvvvvvvvvvvk...",
	"..kvvvvvvvvk....",
	"...kvvkkvvk.....",
	"..kv.k..k.vk....",
	".kvk....kvk.....",
	".kkk....kkk.....",
	"................",
	"................",
]

const TOWER: Array[String] = [
	"................",
	"....kkkkkkkk....",
	"....kxxxxxxk....",
	"....kXxxxxXk....",
	"....kkkkkkkk....",
	"....kxxxxxxk....",
	"....kxkkkkxk....",
	"....kxkYYkxk....",
	"....kxkYYkxk....",
	"....kxkkkkxk....",
	"....kxxxxxxk....",
	"....kxxxxxxk....",
	"....kxkkkkxk....",
	"....kxkYYkxk....",
	"....kxkkkkxk....",
	"....kkkkkkkk....",
]

const ARCHER_PLATFORM: Array[String] = [
	"................",
	"..kkkkkkkkkkk...",
	"..kBBBBBBBBBk...",
	"..kBkkkkkkkBk...",
	"..kBkCCCCCkBk...",
	"..kBkCwwwCkBk...",
	"..kBkCCCCCkBk...",
	"..kBkkkkkkkBk...",
	"..kBBBBBBBBBk...",
	"..kbbbbbbbbbk...",
	"..kbbbbbbbbbk...",
	"..kbkbbbbbkbk...",
	"..kbkbbbbbkbk...",
	"..kbkkkkkkkbk...",
	"..kkkkkkkkkkk...",
	"................",
]

const LUMBER_MILL: Array[String] = [
	"................",
	"...kkkkkkkkkk...",
	"..kBBBBBBBBBBk..",
	"..kBBkBBBBkBBk..",
	"..kBBkBBBBkBBk..",
	"..kBBBBBBBBBBk..",
	"..kbbbbbbbbbbk..",
	"..kbbkbbbbkbbk..",
	"..kbbkbbbbkbbk..",
	"..kbbbbbbbbbbk..",
	"..kbbbbbbbbbbk..",
	"..kbbbbbbbbbbk..",
	"..kbbkbbbbkbbk..",
	"..kkkkkkkkkkkk..",
	"................",
	"................",
]

const QUARRY: Array[String] = [
	"................",
	"...kkkkkkkkk....",
	"..kssssssssssk..",
	"..ksdsssdssssk..",
	"..ksssssssdssk..",
	"..kssdsssssssk..",
	"..ksssssdsssk...",
	"..kssssssssssk..",
	"..ksdsssssdssk..",
	"..kssssssssssk..",
	"..kssdsssssssk..",
	"..ksssssdsssk...",
	"..kkkkkkkkkkkk..",
	"................",
	"................",
	"................",
]

const IRON_MINE: Array[String] = [
	"................",
	"...kkkkkkkkk....",
	"..kddddddddddk..",
	"..kdxxdddxxdk...",
	"..kdxXdddxXdk...",
	"..kdddddddddk...",
	"..kddkkkkkddk...",
	"..kddkdddkddk...",
	"..kddkdddkddk...",
	"..kddkkkkkddk...",
	"..kdddddddddk...",
	"..kdxxdddxxdk...",
	"..kkkkkkkkkkk...",
	"................",
	"................",
	"................",
]

const COMMANDER: Array[String] = [
	"................",
	"......kkkk......",
	".....kppppk.....",
	".....kpkpkk.....",
	".....kpppppk....",
	"....kkkkkkkk....",
	"...kcccccccck...",
	"...kcccccccck...",
	"..kccyccccccck..",
	"..kcccccccccck..",
	"..kcccccccccck..",
	"...kcckkkkcck...",
	"...kcc.k.kcc....",
	"...kkk...kkk....",
	"................",
	"................",
]

const WALL_STONE: Array[String] = [
	"wwwwwssssswwwsss",
	"wsssssssdssssssd",
	"wsssssssdssssssd",
	"wsssssssdssssssd",
	"ssssssssssssssss",
	"dddddddddddddddd",
	"sswwwwssssswwwss",
	"sswssssssssswsss",
	"sswssssssssswsss",
	"sswssssssssswsss",
	"ssssssssssssssss",
	"dddddddddddddddd",
	"wwwssssswwwssssw",
	"wssssssdwsssssdw",
	"wssssssdwsssssdw",
	"wssssssssssssssw",
]

static func _grid_to_image(grid: Array[String]) -> Image:
	var height: int = grid.size()
	var width: int = grid[0].length()
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y: int in range(height):
		for x: int in range(width):
			var key: String = grid[y][x]
			image.set_pixel(x, y, PALETTE.get(key, Color(0, 0, 0, 0)))
	return image


func _initialize() -> void:
	var dir: String = ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var sprites: Dictionary = {
		"archer": ARCHER,
		"enemy_infantry": INFANTRY,
		"enemy_runner": RUNNER,
		"enemy_brute": BRUTE,
		"enemy_shield_bearer": SHIELD_BEARER,
		"enemy_climber": CLIMBER,
		"tower": TOWER,
		"archer_platform": ARCHER_PLATFORM,
		"lumber_mill": LUMBER_MILL,
		"quarry": QUARRY,
		"iron_mine": IRON_MINE,
		"commander": COMMANDER,
		"wall_stone": WALL_STONE,
	}
	for sprite_name: String in sprites:
		var image: Image = _grid_to_image(sprites[sprite_name])
		var error: Error = image.save_png("%s/%s.png" % [dir, sprite_name])
		print("%s: %s" % [sprite_name, error_string(error)])
	quit(0)
