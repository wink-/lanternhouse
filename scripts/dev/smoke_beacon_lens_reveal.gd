extends Node

const OverworldScene := preload("res://scenes/overworld/overworld.tscn")

func _ready() -> void:
	var ok := await _run_checks()
	print("SMOKE_BEACON_LENS_REVEAL_OK" if ok else "SMOKE_BEACON_LENS_REVEAL_FAILED")
	get_tree().quit(0 if ok else 1)

func _run_checks() -> bool:
	_reset_state()
	var overworld := OverworldScene.instantiate()
	add_child(overworld)
	await get_tree().process_frame
	var beacon_pos: Vector2i = overworld.BEACON_POSITIONS["lighthouse"]
	var far_tile: Vector2i = beacon_pos + Vector2i(overworld.FOG_BEACON_RADIUS + 2, 0)
	overworld._interact_beacon("lighthouse", beacon_pos)
	var used_charge: bool = GameData.get_meta("beacon_lens_charges", -1) == 0
	var far_revealed: bool = GameData.explored_tiles.has(str(far_tile))
	var lit: bool = GameData.beacon_states.get(str(beacon_pos), false)
	overworld.queue_free()
	await get_tree().process_frame
	return used_charge and far_revealed and lit

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.beacon_states.clear()
	GameData.beacon_lit = false
	GameData.explored_tiles.clear()
	GameData.active_quests.clear()
	GameData.accept_quest("the_dead_wick")
	GameData.set_meta("beacon_lens_charges", 1)
