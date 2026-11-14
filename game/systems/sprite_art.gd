## Loads the pixel-art sprites from res://art/sprites and keeps them in memory (asset loader).
class_name SpriteArt
extends RefCounted

const DIR: String = "res://art/sprites/"
static var _cache: Dictionary = {}


static func texture(sprite_name: String) -> Texture2D:
	if not _cache.has(sprite_name):
		_cache[sprite_name] = load(DIR + sprite_name + ".png") as Texture2D
	return _cache[sprite_name]
