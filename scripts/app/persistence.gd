class_name Persistence
extends RefCounted

# Thin facade over BinStore + UserPresets. Keeps main.gd from talking to
# two persistence modules directly. The save-preset DIALOG construction
# lives in UIBuilder (it's UI), but the save action — extracting the
# string and persisting — lives here.
#
# Atomic-write upgrades, schema versioning, and parse-validation on load
# are deferred to the Robustness workstream.


static func load_bin() -> Array:
	return BinStore.load_bin()


static func save_bin(bin: Array) -> bool:
	return BinStore.persist(bin)


static func load_user_presets() -> Array:
	return UserPresets.load_all()


# Append a new user preset under `name` carrying the v7 sound `string`.
static func add_user_preset(name: String, sound_string: String) -> void:
	UserPresets.add(name, sound_string)


# Theme name persistence. Empty string means "no saved choice" — caller
# falls back to the default theme.
static func load_theme() -> String:
	return ThemeStore.load_name()


static func save_theme(name: String) -> bool:
	return ThemeStore.persist(name)
