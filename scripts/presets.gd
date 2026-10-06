class_name Presets
extends PresetsHelpers

# Dispatcher for the preset library. The actual preset functions live in
# scripts/presets/presets_<group>.gd; the registry mapping name → group/fn
# lives in scripts/presets/registry.json.
#
# `extends PresetsHelpers` re-exposes effective_locks, randomize_all,
# _apply_target, _off_with — used directly by main.gd. All preset groups
# also extend PresetsHelpers for the same reason.
#
# Patch presets respect the user's lock map; sound presets replace the
# entire Sound (used for layered, multi-channel SFX).


const REGISTRY_PATH := "res://scripts/presets/registry.json"

# Group → script mapping. Adding a new group is a one-line addition here
# plus a new presets_<group>.gd file.
const GROUP_CLASSES: Dictionary = {
	"FIREARM": preload("res://scripts/presets/presets_firearm.gd"),
	"MELEE":   preload("res://scripts/presets/presets_melee.gd"),
	"FOLEY":   preload("res://scripts/presets/presets_foley.gd"),
	"IMPACT":  preload("res://scripts/presets/presets_impact.gd"),
	"WEATHER": preload("res://scripts/presets/presets_weather.gd"),
	"ANIMAL":  preload("res://scripts/presets/presets_animal.gd"),
	"MAGIC":   preload("res://scripts/presets/presets_magic.gd"),
	"MONSTER": preload("res://scripts/presets/presets_monster.gd"),
	"SCIFI":   preload("res://scripts/presets/presets_scifi.gd"),
	"MACHINE": preload("res://scripts/presets/presets_machine.gd"),
	"UI":      preload("res://scripts/presets/presets_ui.gd"),
	"GAME":    preload("res://scripts/presets/presets_game.gd"),
}

# Loaded once from registry.json at first class access. UI walks this to
# render preset buttons.
static var REGISTRY: Array = _load_registry()


static func _load_registry() -> Array:
	if not FileAccess.file_exists(REGISTRY_PATH):
		push_error("Preset registry not found: %s" % REGISTRY_PATH)
		return []
	var f := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if f == null:
		push_error("Failed to open preset registry: %s" % error_string(FileAccess.get_open_error()))
		return []
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (data is Array):
		push_error("Preset registry is not a JSON array")
		return []
	return data


# Dispatch a preset via Callable against the group's script. `params` and
# `locked` are only used by patch presets; sound presets ignore them.
static func run_preset(entry: Dictionary, params: Dictionary, locked: Dictionary) -> Variant:
	var group: String = String(entry.get("group", ""))
	if not GROUP_CLASSES.has(group):
		push_warning("Unknown preset group: %s" % group)
		return null
	var script: Script = GROUP_CLASSES[group]
	var c := Callable(script, entry.fn)
	if not c.is_valid():
		push_warning("Unknown preset fn: %s in group %s" % [entry.fn, group])
		return null
	if entry.kind == "sound":
		return c.call()
	return c.call(params, locked)
