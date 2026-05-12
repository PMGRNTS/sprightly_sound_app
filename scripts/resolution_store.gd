class_name ResolutionStore
extends RefCounted

const PATH := "user://resolution.json"


static func load_size() -> Vector2i:
	var d: Dictionary = _load_dict()
	return Vector2i(int(d.get("w", 0)), int(d.get("h", 0)))


static func load_position() -> Vector2i:
	var d: Dictionary = _load_dict()
	if not d.has("x"):
		return Vector2i(-1, -1)
	return Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))


static func persist(sz: Vector2i, pos: Vector2i = Vector2i(-1, -1)) -> bool:
	var data := {"w": sz.x, "h": sz.y}
	if pos != Vector2i(-1, -1):
		data["x"] = pos.x
		data["y"] = pos.y
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Resolution persist failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true


static func _load_dict() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return {}
	return parsed
