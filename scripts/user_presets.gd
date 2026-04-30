class_name UserPresets
extends RefCounted

# Persistence layer for user-saved presets. Each entry stores a name and
# the v7 sound string (same format produced by SoundData.sound_to_string),
# so saved presets are forward-compatible with the cross-platform codec.
#
# Storage is best-effort, mirroring BinStore: load returns [] on any
# read failure, persist logs and silently returns on write failure. The
# user-presets file is convenience storage, not authoritative state.

const PATH := "user://user_presets.json"


# Read all user presets. Returns [] if the file is missing or malformed.
static func load_all() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("UserPresets load failed to open %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return []
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	return parsed if parsed is Array else []


# Append a new preset, persisting immediately.
static func add(name: String, sound_string: String) -> void:
	var all: Array = load_all()
	all.append({"name": name, "string": sound_string})
	persist(all)


# Remove a preset by 0-based index. No-op if out of range.
static func remove_at(idx: int) -> void:
	var all: Array = load_all()
	if idx < 0 or idx >= all.size():
		return
	all.remove_at(idx)
	persist(all)


# Write the whole list back to disk.
static func persist(entries: Array) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("UserPresets persist failed to open %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return
	f.store_string(JSON.stringify(entries))
	f.close()
