class_name PianoRollDisplay
extends Control

# Custom-drawn piano roll grid with mouse interaction. Analogous to
# WaveformDisplay: a single Control that draws everything in _draw()
# and handles input via _gui_input(). No child nodes.

signal note_added(channel: int, midi: int, beat: float, length: float)
signal note_removed(idx: int)
signal note_moved(idx: int, new_midi: int, new_beat: float)
signal note_resized(idx: int, new_length: float)

const KEY_WIDTH := 36.0
const ROW_HEIGHT := 14.0
const RESIZE_HANDLE_PX := 6.0

const CHANNEL_COLORS: Array[Color] = [
	Color("#c9882d"),  # replaced at draw time with Palette.ACCENT
	Color("#6b9bb5"),
	Color("#8aa674"),
	Color("#b58aaa"),
]

var state: PianoRollState
var active_channel: int = 0
var playhead_beat: float = -1.0
var zoom: float = 1.0

# Drag state machine
enum DragMode { NONE, MOVE, RESIZE }
var _drag_mode: DragMode = DragMode.NONE
var _drag_note_idx: int = -1
var _drag_start_midi: int = 0
var _drag_start_beat: float = 0.0
var _drag_mouse_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _draw() -> void:
	if state == null:
		return
	var sz: Vector2 = size
	if sz.x <= KEY_WIDTH or sz.y <= 0:
		return

	var grid_w: float = sz.x - KEY_WIDTH
	var total_rows: int = PianoRollState.MAX_MIDI - PianoRollState.MIN_MIDI + 1
	var beats: float = state.total_beats()
	var px_per_beat: float = (grid_w / beats) * zoom

	# Visible region — only draw what the ScrollContainer actually shows.
	var vis_y0: float = 0.0
	var vis_y1: float = sz.y
	var vis_x0: float = 0.0
	var vis_x1: float = sz.x
	var scroll := get_parent() as ScrollContainer
	if scroll:
		vis_y0 = float(scroll.scroll_vertical)
		vis_y1 = vis_y0 + scroll.size.y
		vis_x0 = float(scroll.scroll_horizontal)
		vis_x1 = vis_x0 + scroll.size.x

	var row_start: int = maxi(0, int(vis_y0 / ROW_HEIGHT) - 1)
	var row_end: int = mini(total_rows, int(vis_y1 / ROW_HEIGHT) + 2)

	# Background (full — Godot clips to viewport anyway)
	draw_rect(Rect2(Vector2.ZERO, sz), Palette.INSET, true)

	# Piano keys column — visible rows only
	draw_rect(Rect2(0, vis_y0, KEY_WIDTH, vis_y1 - vis_y0), Palette.PANEL, true)
	for row in range(row_start, row_end):
		var midi: int = PianoRollState.MAX_MIDI - row
		var y: float = float(row) * ROW_HEIGHT
		var is_black: bool = _is_black_key(midi)
		var key_color: Color = Palette.BG if is_black else Palette.PANEL
		draw_rect(Rect2(0, y, KEY_WIDTH, ROW_HEIGHT), key_color, true)
		if midi % 12 == 0:
			draw_string(ThemeDB.fallback_font, Vector2(2, y + ROW_HEIGHT - 2),
				PianoRollState.midi_to_name(midi), HORIZONTAL_ALIGNMENT_LEFT,
				KEY_WIDTH - 4, Palette.FONT_SMALL - 1, Palette.TEXT_MUTE)
		draw_line(Vector2(0, y), Vector2(KEY_WIDTH, y), Palette.BORDER, 1.0)

	# Key column right edge
	draw_line(Vector2(KEY_WIDTH, vis_y0), Vector2(KEY_WIDTH, vis_y1), Palette.BORDER_HI, 1.0)

	# Vertical grid lines — skip lines outside visible x range
	var sixteenth: float = 0.25
	var first_step: float = maxf(0.0, floorf((vis_x0 - KEY_WIDTH) / px_per_beat / sixteenth) * sixteenth)
	var step: float = first_step
	while step <= beats:
		var x: float = KEY_WIDTH + step * px_per_beat
		if x > vis_x1:
			break
		if x >= vis_x0 - 1.0:
			var is_bar: bool = fmod(step, 4.0) < 0.001
			var is_beat_line: bool = fmod(step, 1.0) < 0.001
			var col: Color = Palette.BORDER_HI if is_bar else (Palette.BORDER if is_beat_line else Palette.SEPARATOR)
			var w: float = 2.0 if is_bar else 1.0
			draw_line(Vector2(x, vis_y0), Vector2(x, vis_y1), col, w)
		step += sixteenth

	# Horizontal pitch rows — visible rows only
	for row in range(row_start, row_end + 1):
		var y: float = float(row) * ROW_HEIGHT
		var midi: int = PianoRollState.MAX_MIDI - row
		var is_black: bool = _is_black_key(midi + 1) if row < total_rows else false
		if is_black and row < total_rows:
			var row_bg: Color = Color(Palette.BG.r, Palette.BG.g, Palette.BG.b, 0.15)
			draw_rect(Rect2(KEY_WIDTH, y, vis_x1 - KEY_WIDTH, ROW_HEIGHT), row_bg, true)
		draw_line(Vector2(KEY_WIDTH, y), Vector2(vis_x1, y), Palette.SEPARATOR, 1.0)

	# Notes — skip those entirely outside the visible region
	for i in state.notes.size():
		var n: Dictionary = state.notes[i]
		var note_rect: Rect2 = _note_rect(n, px_per_beat, total_rows)
		if note_rect.end.x < vis_x0 or note_rect.position.x > vis_x1:
			continue
		if note_rect.end.y < vis_y0 or note_rect.position.y > vis_y1:
			continue
		var ch: int = int(n.channel)
		var col: Color = _channel_color(ch)
		if ch != active_channel:
			col = Color(col.r, col.g, col.b, 0.4)
		draw_rect(note_rect, col, true)
		draw_rect(note_rect, col.lightened(0.3), false, 1.0)
		var handle_x: float = note_rect.end.x - RESIZE_HANDLE_PX
		if note_rect.size.x > RESIZE_HANDLE_PX * 2:
			draw_line(
				Vector2(handle_x, note_rect.position.y + 2),
				Vector2(handle_x, note_rect.end.y - 2),
				col.lightened(0.5), 1.0)

	# Playhead
	if playhead_beat >= 0.0:
		var px: float = KEY_WIDTH + playhead_beat * px_per_beat
		if px >= vis_x0 and px <= vis_x1:
			draw_line(Vector2(px, vis_y0), Vector2(px, vis_y1), Palette.ACCENT, 2.0)


func _gui_input(event: InputEvent) -> void:
	if state == null:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _drag_mode != DragMode.NONE:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_mouse_button(e: InputEventMouseButton) -> void:
	var pos: Vector2 = e.position
	if pos.x < KEY_WIDTH:
		return

	var px_per_beat: float = _px_per_beat()
	var total_rows: int = PianoRollState.MAX_MIDI - PianoRollState.MIN_MIDI + 1

	if e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			var beat: float = (pos.x - KEY_WIDTH) / px_per_beat
			var midi: int = PianoRollState.MAX_MIDI - int(pos.y / ROW_HEIGHT)
			var hit: int = _hit_test(pos, px_per_beat, total_rows)

			if hit >= 0:
				var n: Dictionary = state.notes[hit]
				var nr: Rect2 = _note_rect(n, px_per_beat, total_rows)
				if pos.x >= nr.end.x - RESIZE_HANDLE_PX:
					_drag_mode = DragMode.RESIZE
					_drag_note_idx = hit
					_drag_start_beat = float(n.length)
					_drag_mouse_start = pos
				else:
					_drag_mode = DragMode.MOVE
					_drag_note_idx = hit
					_drag_start_midi = int(n.midi)
					_drag_start_beat = float(n.beat)
					_drag_mouse_start = pos
			else:
				var snapped: float = PianoRollState.snap_beat(beat)
				note_added.emit(active_channel, midi, snapped, PianoRollState.SNAP_DIVISOR)
		else:
			_drag_mode = DragMode.NONE
			_drag_note_idx = -1

	elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
		var hit: int = _hit_test(pos, px_per_beat, total_rows)
		if hit >= 0:
			note_removed.emit(hit)


func _handle_mouse_motion(e: InputEventMouseMotion) -> void:
	var pos: Vector2 = e.position
	var px_per_beat: float = _px_per_beat()

	if _drag_note_idx < 0 or _drag_note_idx >= state.notes.size():
		_drag_mode = DragMode.NONE
		return

	match _drag_mode:
		DragMode.MOVE:
			var dx_beats: float = (pos.x - _drag_mouse_start.x) / px_per_beat
			var dy_rows: int = -int(round((pos.y - _drag_mouse_start.y) / ROW_HEIGHT))
			var new_beat: float = PianoRollState.snap_beat(_drag_start_beat + dx_beats)
			var new_midi: int = _drag_start_midi + dy_rows
			note_moved.emit(_drag_note_idx, new_midi, new_beat)
		DragMode.RESIZE:
			var dx_beats: float = (pos.x - _drag_mouse_start.x) / px_per_beat
			var new_length: float = PianoRollState.snap_beat(_drag_start_beat + dx_beats)
			new_length = maxf(new_length, PianoRollState.MIN_BEAT_LENGTH)
			note_resized.emit(_drag_note_idx, new_length)


# ── Coordinate helpers ────────────────────────────────────────────

func _px_per_beat() -> float:
	var grid_w: float = size.x - KEY_WIDTH
	return (grid_w / state.total_beats()) * zoom


func _note_rect(n: Dictionary, px_per_beat: float, _total_rows: int) -> Rect2:
	var row: int = PianoRollState.MAX_MIDI - int(n.midi)
	var x: float = KEY_WIDTH + float(n.beat) * px_per_beat
	var y: float = float(row) * ROW_HEIGHT
	var w: float = float(n.length) * px_per_beat
	return Rect2(x, y, w, ROW_HEIGHT)


func _hit_test(pos: Vector2, px_per_beat: float, total_rows: int) -> int:
	for i in range(state.notes.size() - 1, -1, -1):
		var nr: Rect2 = _note_rect(state.notes[i], px_per_beat, total_rows)
		if nr.has_point(pos):
			return i
	return -1


static func _is_black_key(midi: int) -> bool:
	var n: int = midi % 12
	return n == 1 or n == 3 or n == 6 or n == 8 or n == 10


func _channel_color(ch: int) -> Color:
	if ch == 0:
		return Palette.ACCENT
	if ch < CHANNEL_COLORS.size():
		return CHANNEL_COLORS[ch]
	return Palette.TEXT_MUTE
