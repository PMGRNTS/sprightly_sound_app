class_name ThemeStore
extends RefCounted

# Disk persistence for the user's selected colour theme. Stored as a
# single JSON object so we have room to grow (custom themes, accent
# overrides, etc.) without changing the file path.
#
# Failures are non-fatal: load returns "" if the file is missing or
# malformed (caller falls back to the default theme), persist logs a
# warning and returns false.

const PATH := "user://theme.json"


# Read the saved theme name from disk. Returns "" when no file exists,
# the file is unreadable, or the JSON doesn't contain a "name" string.
static func load_name() -> String:
	if not FileAccess.file_exists(PATH):
		return ""
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("Theme load failed to open %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return ""
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return ""
	return String(parsed.get("name", ""))


# Persist the active theme name. Returns true on success.
static func persist(name: String) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Theme persist failed to open %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify({"name": name}))
	f.close()
	return true
