class_name BinStore
extends RefCounted

# Disk persistence for the user's saved sound bin. The bin itself is just
# an Array of Dictionaries kept on the main controller — this class only
# moves it to/from `user://bin.json` so save/load stays free of
# FileAccess paperwork at the call site.
#
# Failures are non-fatal: load returns [] if the file is missing or
# malformed, persist logs a warning and silently returns. The bin is
# convenience storage, not authoritative state.

const PATH := "user://bin.json"


# Read the bin from disk. Returns [] when no file exists, the file is
# unreadable, or the JSON doesn't deserialize to an Array.
static func load_bin() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("Bin load failed to open %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return []
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	return parsed if parsed is Array else []


# Write the bin to disk. Returns true on success, false on failure.
# Failure is non-fatal — losing the bin file is recoverable, crashing
# the app is not — but the boolean lets callers surface the failure to
# the user instead of silently flashing "SAVED".
static func persist(bin: Array) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Bin persist failed to open %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(bin))
	f.close()
	return true
