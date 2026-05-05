class_name SoundState
extends RefCounted

# Owns the sound, channels, locks, samples, undo/redo history, and bin.
# A pure data container — no Nodes, no UI, no signals. The controller
# (main.gd) mutates state through this class's methods, then calls
# UIBuilder.refresh_* to redraw. Keeping signals out keeps the data flow
# obvious: every refresh call site is grep-able from the handler that
# triggered it.

const UNDO_MAX := 50
const BIN_MAX := 100


# ── Core state ─────────────────────────────────────────────────────
var sound: Dictionary
var active_channel: int = 0
var locks: Array[Dictionary] = [{}]     # locks[i] = Dictionary keyed by param
var samples: PackedFloat32Array = PackedFloat32Array()
var sound_string: String = ""
var bin: Array[Dictionary] = []

# ── Undo / redo ────────────────────────────────────────────────────
# Snapshots are taken before discrete state replacements (GEN, preset,
# paste, bin-load) — NOT before slider drags, which would flood the stack.
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []

# ── Variation seed ─────────────────────────────────────────────────
# Auto-incrementing seed applied before every preset / GEN. Each click
# yields a fresh take AND every result is reproducible: type any prior
# value into the SpinBox to get that variant back.
var variation_seed: int = 0


func _init() -> void:
	sound = SoundData.default_sound()


# ── Snapshots / undo / redo ────────────────────────────────────────

# Capture (sound, locks, active_channel) as one immutable snapshot.
# Dictionary.duplicate(true) recurses into nested arrays/dicts, so the
# returned dict is fully decoupled from live state.
func snapshot() -> Dictionary:
	return {
		"sound": sound.duplicate(true),
		"locks": locks.duplicate(true),
		"active_channel": active_channel,
	}


# Push current state onto the undo stack and clear redo (new branch taken).
# Called BEFORE any state replacement (GEN, preset, paste, bin-load).
func push_undo() -> void:
	undo_stack.append(snapshot())
	if undo_stack.size() > UNDO_MAX:
		undo_stack.pop_front()
	redo_stack.clear()


# Pop the latest undo onto live state. Returns true if a snapshot was
# applied; false if the undo stack was empty (caller should flash NO UNDO).
func undo() -> bool:
	if undo_stack.is_empty():
		return false
	redo_stack.append(snapshot())
	if redo_stack.size() > UNDO_MAX:
		redo_stack.pop_front()
	_restore(undo_stack.pop_back())
	return true


func redo() -> bool:
	if redo_stack.is_empty():
		return false
	undo_stack.append(snapshot())
	if undo_stack.size() > UNDO_MAX:
		undo_stack.pop_front()
	_restore(redo_stack.pop_back())
	return true


func _restore(snap: Dictionary) -> void:
	sound = snap.sound
	locks = snap.locks
	active_channel = clampi(int(snap.active_channel), 0, sound.channels.size() - 1)


# ── Sound replacement ──────────────────────────────────────────────

# Replace the entire sound, reset locks to empty per channel, jump to
# channel 0. Used by paste, load string, bin-load, user preset.
func replace_sound(new_sound: Dictionary) -> void:
	sound = new_sound
	locks.clear()
	for c in sound.channels:
		locks.append({})
	active_channel = 0


# Apply a patch dict to channel 0 of a fresh single-channel sound.
# Used by patch presets which collapse to a single channel.
func apply_patch_preset(new_patch: Dictionary) -> void:
	var new_sound: Dictionary = {
		"channels": [SoundData.clone_params()],
		"master": SoundData.clone_master(),
	}
	new_sound.channels[0].merge(new_patch, true)
	# Preserve the active channel's locks on the collapsed channel.
	var preserved: Dictionary = locks[active_channel].duplicate(true)
	locks.clear()
	locks.append(preserved)
	active_channel = 0
	sound = new_sound


# ── Channel ops ────────────────────────────────────────────────────

func add_channel() -> bool:
	if sound.channels.size() >= SoundData.MAX_CHANNELS:
		return false
	sound.channels.append(SoundData.clone_params())
	locks.append({})
	active_channel = sound.channels.size() - 1
	return true


func remove_channel(idx: int) -> bool:
	if sound.channels.size() <= 1:
		return false
	sound.channels.remove_at(idx)
	if idx < locks.size():
		locks.remove_at(idx)
	if idx < active_channel:
		active_channel -= 1
	elif idx == active_channel:
		active_channel = max(0, active_channel - 1)
	return true


# ── Variation seed ─────────────────────────────────────────────────

# Seed BEFORE randomize_all reads any randf — same seed = same generated
# sound, every time. Auto-increments so the next click yields a fresh take.
func consume_variation_seed() -> void:
	seed(variation_seed)
	variation_seed = (variation_seed + 1) % 10000


func randomize_variation_seed() -> void:
	variation_seed = randi() % 10000


# ── Bin ops ────────────────────────────────────────────────────────

func add_to_bin(entry: Dictionary) -> void:
	bin.insert(0, entry)
	# Cap at BIN_MAX entries (oldest fall off the end).
	if bin.size() > BIN_MAX:
		bin.resize(BIN_MAX)


func remove_from_bin(id: int) -> void:
	bin.assign(bin.filter(func(e): return int(e.get("id", -1)) != id))


# Find a bin entry by id, or null if missing.
func find_bin_entry(id: int) -> Variant:
	for entry in bin:
		if int(entry.get("id", -1)) == id:
			return entry
	return null


# ── Helpers for read-only access ───────────────────────────────────

func active_channel_locks() -> Dictionary:
	if active_channel < locks.size():
		return locks[active_channel]
	return {}


func active_channel_params() -> Dictionary:
	return sound.channels[active_channel]
