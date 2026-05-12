class_name PianoRollState
extends RefCounted

# Pure data container for the piano roll sequencer. Same pattern as
# SoundState: no signals, no UI. The controller (main.gd) mutates state
# through methods here, then calls UIBuilder refresh to redraw.

const UNDO_MAX := 50
const MIN_MIDI := 36   # C2
const MAX_MIDI := 96   # C7
const MIN_BEAT_LENGTH := 0.25
const SNAP_DIVISOR := 0.25  # snap to 16th notes


var bpm: int = 120
var bars: int = 2
var notes: Array[Dictionary] = []  # {channel, midi, beat, length}

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []


func total_beats() -> float:
	return float(bars) * 4.0


# ── Note CRUD ─────────────────────────────────────────────────────

func add_note(channel: int, midi: int, beat: float, length: float) -> void:
	midi = clampi(midi, MIN_MIDI, MAX_MIDI)
	beat = snap_beat(beat)
	length = maxf(length, MIN_BEAT_LENGTH)
	if beat + length > total_beats():
		length = total_beats() - beat
	if length < MIN_BEAT_LENGTH:
		return
	notes.append({"channel": channel, "midi": midi, "beat": beat, "length": length})


func remove_note(idx: int) -> void:
	if idx >= 0 and idx < notes.size():
		notes.remove_at(idx)


func move_note(idx: int, new_midi: int, new_beat: float) -> void:
	if idx < 0 or idx >= notes.size():
		return
	var n: Dictionary = notes[idx]
	n.midi = clampi(new_midi, MIN_MIDI, MAX_MIDI)
	n.beat = snap_beat(clampf(new_beat, 0.0, total_beats() - n.length))


func resize_note(idx: int, new_length: float) -> void:
	if idx < 0 or idx >= notes.size():
		return
	var n: Dictionary = notes[idx]
	new_length = maxf(new_length, MIN_BEAT_LENGTH)
	if n.beat + new_length > total_beats():
		new_length = total_beats() - n.beat
	n.length = new_length


# Find the note index at a given (midi, beat). Returns -1 if none.
func note_at(midi: int, beat: float) -> int:
	for i in range(notes.size() - 1, -1, -1):
		var n: Dictionary = notes[i]
		if n.midi == midi and beat >= n.beat and beat < n.beat + n.length:
			return i
	return -1


# ── Helpers ───────────────────────────────────────────────────────

static func snap_beat(beat: float) -> float:
	return snappedf(maxf(beat, 0.0), SNAP_DIVISOR)


static func midi_to_hz(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)


static func midi_to_name(midi: int) -> String:
	const NAMES: Array[String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var octave: int = (midi / 12) - 1
	var note_idx: int = midi % 12
	return "%s%d" % [NAMES[note_idx], octave]


# ── Undo / redo ───────────────────────────────────────────────────

func snapshot() -> Dictionary:
	var note_copies: Array[Dictionary] = []
	for n in notes:
		note_copies.append(n.duplicate())
	return {"bpm": bpm, "bars": bars, "notes": note_copies}


func push_undo() -> void:
	undo_stack.append(snapshot())
	if undo_stack.size() > UNDO_MAX:
		undo_stack.pop_front()
	redo_stack.clear()


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
	bpm = int(snap.bpm)
	bars = int(snap.bars)
	notes.clear()
	for n in snap.notes:
		notes.append(n)


# ── Serialization ─────────────────────────────────────────────────

func to_dict() -> Dictionary:
	var note_arr: Array = []
	for n in notes:
		note_arr.append({"channel": n.channel, "midi": n.midi, "beat": n.beat, "length": n.length})
	return {"bpm": bpm, "bars": bars, "notes": note_arr}


func from_dict(d: Dictionary) -> void:
	bpm = clampi(int(d.get("bpm", 120)), 40, 300)
	bars = clampi(int(d.get("bars", 2)), 1, 8)
	notes.clear()
	var raw_notes: Variant = d.get("notes", [])
	if raw_notes is Array:
		for n in raw_notes:
			if n is Dictionary and n.has("channel") and n.has("midi") and n.has("beat") and n.has("length"):
				add_note(int(n.channel), int(n.midi), float(n.beat), float(n.length))
