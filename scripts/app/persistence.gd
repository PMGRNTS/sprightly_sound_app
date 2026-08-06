class_name Persistence
extends RefCounted

# Single owner of everything the app writes to user://. Four small JSON
# files behind one code path: _read_json / _write_json do the FileAccess
# paperwork, and each domain below is a thin typed accessor over them.
#
# Failures are non-fatal by design — all four files are convenience
# storage, not authoritative state. A read failure returns the caller's
# fallback; a write failure logs and returns false so the caller can
# surface it ("SAVE FAILED") rather than flash a success it didn't get.

const BIN_PATH          := "user://bin.json"
const THEME_PATH        := "user://theme.json"
const RESOLUTION_PATH   := "user://resolution.json"
const USER_PRESETS_PATH := "user://user_presets.json"


# ── JSON file I/O ──────────────────────────────────────────────────

# Read and parse `path`. Returns `fallback` when the file is missing,
# unreadable, malformed, or parses to a different type than expected —
# so a corrupt bin.json costs the user their bin, not a crash on boot.
static func _read_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Persistence: cannot read %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return fallback
	var raw: String = f.get_as_text()
	f.close()
	# JSON instance rather than JSON.parse_string(): a corrupt file is an
	# expected, handled case here, and the static helper logs it to the
	# console as an engine error every time.
	var json := JSON.new()
	if json.parse(raw) != OK:
		push_warning("Persistence: %s is malformed at line %d (%s) — ignoring it" % [
			path, json.get_error_line(), json.get_error_message()])
		return fallback
	if typeof(json.data) != typeof(fallback):
		return fallback
	return json.data


# Write `data` as JSON to a temp file, then rename it over the target.
# Rename is atomic on every platform we ship to, so an interrupted write
# (crash, full disk, power loss) leaves the previous good file intact
# instead of a half-written one. Returns true only if the data landed.
static func _write_json(path: String, data: Variant) -> bool:
	var tmp_path: String = path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("Persistence: cannot write %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(data))
	var write_err: int = f.get_error()
	f.close()
	if write_err != OK:
		push_warning("Persistence: write failed for %s (%s)" % [tmp_path, error_string(write_err)])
		return false

	var rename_err: int = DirAccess.rename_absolute(tmp_path, path)
	if rename_err != OK:
		push_warning("Persistence: rename failed for %s (%s)" % [path, error_string(rename_err)])
		return false
	return true


# ── Bin ────────────────────────────────────────────────────────────

static func load_bin() -> Array:
	return _read_json(BIN_PATH, [])


static func save_bin(bin: Array) -> bool:
	return _write_json(BIN_PATH, bin)


# ── Theme ──────────────────────────────────────────────────────────
# Stored as an object rather than a bare string so there's room to grow
# (custom themes, accent overrides) without changing the file path.
# "" means no saved choice — caller keeps the default theme.

static func load_theme() -> String:
	var d: Dictionary = _read_json(THEME_PATH, {})
	return String(d.get("name", ""))


static func save_theme(name: String) -> bool:
	return _write_json(THEME_PATH, {"name": name})


# ── Window size / position ─────────────────────────────────────────
# Both are in PIXELS — that's what the Window API reports and expects.
# Vector2i.ZERO means no saved size; (-1, -1) means no saved position.

static func load_resolution() -> Vector2i:
	var d: Dictionary = _read_json(RESOLUTION_PATH, {})
	return Vector2i(int(d.get("w", 0)), int(d.get("h", 0)))


static func load_window_position() -> Vector2i:
	var d: Dictionary = _read_json(RESOLUTION_PATH, {})
	if not d.has("x"):
		return Vector2i(-1, -1)
	return Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))


static func save_resolution(sz: Vector2i, pos: Vector2i = Vector2i(-1, -1)) -> bool:
	var data: Dictionary = {"w": sz.x, "h": sz.y}
	if pos != Vector2i(-1, -1):
		data["x"] = pos.x
		data["y"] = pos.y
	return _write_json(RESOLUTION_PATH, data)


# ── User presets ───────────────────────────────────────────────────
# Each entry is {"name": String, "string": v7 sound string}. Storing the
# sound string (not a param dump) keeps saved presets readable by the
# same codec as copy/paste, so they survive schema changes.

static func load_user_presets() -> Array:
	return _read_json(USER_PRESETS_PATH, [])


static func add_user_preset(name: String, sound_string: String) -> bool:
	var all: Array = load_user_presets()
	all.append({"name": name, "string": sound_string})
	return _write_json(USER_PRESETS_PATH, all)
