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
