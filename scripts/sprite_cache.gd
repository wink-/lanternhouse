# SpriteCache — autoload. Checks for PNG sprites, returns Texture2D or null.
# When a sprite exists at the expected path, use it. Otherwise, fall back to colored blocks.
#
# Drop pixel art files into assets/sprites/ with these names:
#   overworld/player.png
#   battle/enemies/slime.png, imp.png, wolf.png, ghoul.png, skeleton.png, ogre.png, wraith.png, drake.png, golem.png
#   battle/party/fighter.png, thief.png, blackbelt.png, redmage.png
#   tiles/water.png, grass.png, forest.png, mountain.png, town.png, path.png, cave.png, bridge.png

extends Node

# In-memory cache so we don't hit disk every frame
var _cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Returns Texture2D if the sprite file exists, null otherwise
func get_sprite(rel_path: String) -> Texture2D:
	if _cache.has(rel_path):
		return _cache[rel_path]

	var full_path := "res://assets/sprites/%s" % rel_path
	if ResourceLoader.exists(full_path):
		var tex: Texture2D = load(full_path)
		_cache[rel_path] = tex
		return tex

	_cache[rel_path] = null
	return null

# Convenience: load overworld player sprite
func player_sprite() -> Texture2D:
	return get_sprite("overworld/player.png")

# Convenience: load enemy sprite
func enemy_sprite(name_lower: String) -> Texture2D:
	return get_sprite("battle/enemies/%s.png" % name_lower)

# Convenience: load party member sprite
func party_sprite(name_lower: String) -> Texture2D:
	return get_sprite("battle/party/%s.png" % name_lower)

# Convenience: load tile sprite
func tile_sprite(name: String) -> Texture2D:
	return get_sprite("tiles/%s.png" % name)
