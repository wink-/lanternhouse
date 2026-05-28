# SpriteCache — autoload. Resolves named sprite assets and caches Texture2D resources.
# When a sprite exists at the expected path, use it. Otherwise, return null so scenes
# can keep their lightweight fallback rendering.

extends Node

const ASSET_PATHS := {
	"overworld.player": "overworld/player.png",
	"town.atlas": "tiles/lanternhouse_town.png",
	"town.ground": "tiles/lanternhouse_town_readable.png",
	"town.vendor.buildings": "vendor/quiet_village/Buildings.png",
	"town.vendor.props": "vendor/quiet_village/Props.png",
	"town.home.interior": "interiors/town/home_interior.png",
	"tiles.overworld": "tiles/lanternhouse_overworld.png",
}

var _cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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

func get_asset(asset_key: String) -> Texture2D:
	var rel_path := resolve_asset_path(asset_key)
	if rel_path == "":
		return null
	return get_sprite(rel_path)

func resolve_asset_path(asset_key: String) -> String:
	if ASSET_PATHS.has(asset_key):
		return ASSET_PATHS[asset_key]

	var parts := asset_key.split(".")
	if parts.size() < 2:
		return ""
	match parts[0]:
		"battle":
			if parts.size() == 3 and parts[1] == "enemy":
				return "battle/enemies/%s.png" % parts[2]
			if parts.size() == 3 and parts[1] == "party":
				return "battle/party/%s.png" % parts[2]
		"character":
			if parts.size() == 4 and parts[2] == "rotation":
				return "characters/%s/rotations/%s.png" % [parts[1], parts[3]]
			if parts.size() == 5 and parts[2] == "walk":
				return "characters/%s/walk/%s/%s.png" % [parts[1], parts[3], parts[4]]
		"town":
			if parts.size() == 3 and parts[1] == "building":
				return "town/shops/buildings/%s.png" % parts[2]
			if parts.size() == 3 and parts[1] == "awning":
				return "town/shops/awnings/%s.png" % parts[2]
			if parts.size() == 3 and parts[1] == "sign":
				return "town/shops/signs/%s.png" % parts[2]
			if parts.size() == 3 and parts[1] == "prop":
				return "town/props/%s.png" % parts[2]
	return ""

func player_sprite() -> Texture2D:
	return get_asset("overworld.player")

func enemy_sprite(name_lower: String) -> Texture2D:
	return get_asset("battle.enemy.%s" % name_lower)

func party_sprite(name_lower: String) -> Texture2D:
	return get_asset("battle.party.%s" % name_lower)

func tile_sprite(tile_id: String) -> Texture2D:
	return get_sprite("tiles/%s.png" % tile_id)

func town_building(building_id: String) -> Texture2D:
	return get_asset("town.building.%s" % building_id)

func town_awning(awning_id: String) -> Texture2D:
	return get_asset("town.awning.%s" % awning_id)

func town_sign(sign_id: String) -> Texture2D:
	return get_asset("town.sign.%s" % sign_id)

func town_prop(prop_id: String) -> Texture2D:
	return get_asset("town.prop.%s" % prop_id)

func character_rotation(character_id: String, direction: String) -> Texture2D:
	return get_asset("character.%s.rotation.%s" % [character_id, direction])

func character_walk_frame(character_id: String, direction: String, frame: int) -> Texture2D:
	return get_asset("character.%s.walk.%s.%d" % [character_id, direction, frame])
