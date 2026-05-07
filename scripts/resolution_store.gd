class_name ResolutionStore
extends RefCounted

const PATH := "user://resolution.json"


static func load_size() -> Vector2i:
	if not FileAccess.file_exists(PATH):
		return Vector2i.ZERO
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return Vector2i.ZERO
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return Vector2i.ZERO
	return Vector2i(int(parsed.get("w", 0)), int(parsed.get("h", 0)))


static func persist(sz: Vector2i) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Resolution persist failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify({"w": sz.x, "h": sz.y}))
	f.close()
	return true
