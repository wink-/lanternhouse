extends Node

const TownScene := preload("res://scenes/town/town.tscn")
const WorkshopScene := preload("res://scenes/workshop/workshop.tscn")

func _ready() -> void:
	var ok := await _run_checks()
	print("SMOKE_WORKSHOP_INTERIOR_OK" if ok else "SMOKE_WORKSHOP_INTERIOR_FAILED")
	get_tree().quit(0 if ok else 1)

func _run_checks() -> bool:
	var town := TownScene.instantiate()
	add_child(town)
	await get_tree().process_frame
	if town._building_door_at(Vector2i(25, 17)) != "tinkerer":
		return false
	town.queue_free()
	await get_tree().process_frame

	var workshop := WorkshopScene.instantiate()
	add_child(workshop)
	await get_tree().process_frame
	if workshop.pos != Vector2i(7, 9):
		return false
	if not _interior_layout_ok(workshop):
		return false
	if not _player_sprite_ok(workshop):
		return false
	GameData.set_meta("town_spawn_pos", Vector2i(25, 18))
	GameData.set_meta("town_spawn_facing", Vector2i.UP)
	await get_tree().process_frame
	if GameData.get_meta("town_spawn_pos", Vector2i.ZERO) != Vector2i(25, 18):
		return false
	workshop.queue_free()
	await get_tree().process_frame

	var returned_town := TownScene.instantiate()
	add_child(returned_town)
	await get_tree().process_frame
	var returned_ok: bool = returned_town.pos == Vector2i(25, 18) and returned_town.facing == Vector2i.UP
	returned_town.queue_free()
	return returned_ok

func _interior_layout_ok(interior: Node) -> bool:
	var map_size := Vector2(interior.MAP[0].length() * interior.TILE_SIZE, interior.MAP.size() * interior.TILE_SIZE)
	var expected_origin := ((get_viewport().get_visible_rect().size - map_size) * 0.5).floor()
	expected_origin.x = maxf(0.0, expected_origin.x)
	expected_origin.y = maxf(0.0, expected_origin.y)
	return interior.map_layer.position.is_equal_approx(expected_origin)

func _player_sprite_ok(interior: Node) -> bool:
	var sprite := interior.player_sprite.get_node_or_null("Sprite") as Sprite2D
	if not sprite or not sprite.texture:
		return false
	if interior.player_sprite.has_node("Body") and interior.player_sprite.get_node("Body").visible:
		return false
	if interior.player_sprite.has_node("Face") and interior.player_sprite.get_node("Face").visible:
		return false
	return true
