extends RefCounted

static func load_from_file(path: String, defaults: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Town layout missing: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Town layout could not be opened: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("Town layout is not valid JSON object: %s" % path)
		return {}
	return from_dictionary(parsed, defaults)

static func from_dictionary(layout: Dictionary, defaults: Dictionary) -> Dictionary:
	var cat_fallback: Dictionary = defaults.get("cat", {})
	var cat_data: Dictionary = layout.get("cat", {})
	var doors := parse_doors(layout.get("doors", []))
	if doors.is_empty():
		doors = defaults.get("doors", {}).duplicate(true)

	return {
		"map": layout.get("map", defaults.get("map", [])).duplicate(),
		"buildings": parse_list(layout.get("buildings", defaults.get("buildings", []))),
		"shop_signs": parse_list(layout.get("shop_signs", defaults.get("shop_signs", []))),
		"shop_awnings": parse_list(layout.get("shop_awnings", defaults.get("shop_awnings", []))),
		"props": parse_list(layout.get("props", defaults.get("props", []))),
		"doors": doors,
		"building_interactions": parse_interactions(
			layout.get("building_interactions", defaults.get("building_interactions", {})),
			defaults.get("building_interactions", {})
		),
		"cat_home": array_to_vector2i(cat_data.get("home", cat_fallback.get("home", Vector2i.ZERO)), Vector2i.ZERO),
		"cat_wander_radius": int(cat_data.get("wander_radius", cat_fallback.get("wander_radius", 0))),
	}

static func parse_list(entries: Variant) -> Array:
	var result: Array = []
	if not (entries is Array):
		return result
	for entry: Variant in entries:
		if entry is Dictionary:
			result.append(parse_entry(entry))
	return result

static func parse_entry(entry: Dictionary) -> Dictionary:
	var parsed := entry.duplicate(true)
	if parsed.has("grid"):
		parsed["grid"] = array_to_vector2i(parsed["grid"], Vector2i.ZERO)
	if parsed.has("size"):
		parsed["size"] = array_to_vector2i(parsed["size"], Vector2i(1, 1))
	if parsed.has("offset"):
		parsed["offset"] = array_to_vector2(parsed["offset"], Vector2.ZERO)
	if parsed.has("fallback_region"):
		parsed["fallback_region"] = array_to_rect2i(parsed["fallback_region"], Rect2i())
	return parsed

static func parse_doors(entries: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (entries is Array):
		return result
	for entry: Variant in entries:
		if not (entry is Dictionary):
			continue
		var door_data: Dictionary = entry
		if not door_data.has("grid") or not door_data.has("npc"):
			continue
		result[array_to_vector2i(door_data["grid"], Vector2i.ZERO)] = String(door_data["npc"])
	return result

static func parse_interactions(entries: Variant, fallback: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if not (entries is Dictionary):
		return fallback.duplicate(true)
	for building_id: String in entries:
		var data: Variant = entries[building_id]
		if not (data is Dictionary):
			continue
		var parsed: Dictionary = data.duplicate(true)
		if parsed.has("door_offset"):
			parsed["door_offset"] = array_to_vector2i(parsed["door_offset"], Vector2i.ZERO)
		result[building_id] = parsed
	return result

static func array_to_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return fallback

static func array_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback

static func array_to_rect2i(value: Variant, fallback: Rect2i) -> Rect2i:
	if value is Rect2i:
		return value
	if value is Array and value.size() >= 4:
		return Rect2i(Vector2i(int(value[0]), int(value[1])), Vector2i(int(value[2]), int(value[3])))
	return fallback
