class_name PianoRollPersistence
extends RefCounted

# Save/load piano roll state to user://piano_roll.json.
# Same pattern as BinStore: non-fatal failures, returns defaults on error.

const PATH := "user://piano_roll.json"


static func load_state() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("Piano roll load failed: %s" % error_string(FileAccess.get_open_error()))
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else {}


static func save_state(state: PianoRollState) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Piano roll save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(state.to_dict()))
	f.close()
	return true
