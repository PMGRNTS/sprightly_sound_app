class_name Knob
extends Range

# Rotary knob control. Drop-in replacement for HSlider that takes far less
# screen real estate. Vertical-drag to adjust, right-click to reset, scroll
# wheel and arrow keys to step, alt-click to toggle lock.
#
# `locked` is a purely visual flag — the controller (main.gd) owns the
# truth and mirrors it onto the knob via set_locked. Alt-click emits
# lock_toggled so the controller can flip its own state.

signal reset_requested
signal lock_toggled(is_locked: bool)

const DRAG_SENSITIVITY: float = 0.005
const ARC_START_DEG: float = 135.0
const ARC_SWEEP_DEG: float = 270.0
const SCROLL_STEP_THRESHOLD: float = 1.0
const SCROLL_RESET_MS: int = 200

var locked: bool = false:
	set = set_locked

var _dragging: bool = false
var _scroll_accum: float = 0.0
var _scroll_last_ms: int = 0


func _init() -> void:
	custom_minimum_size = Vector2(32, 32)
	focus_mode = Control.FOCUS_ALL


func _ready() -> void:
	value_changed.connect(func(_v): queue_redraw())


func set_locked(v: bool) -> void:
	if v == locked:
		return
	locked = v
	queue_redraw()


func _draw() -> void:
	var s: Vector2 = size
	var c: Vector2 = s * 0.5
	var r: float = minf(s.x, s.y) * 0.5 - 2.0
	var ring_w: float = maxf(2.0, r * 0.18)

	var start_rad: float = deg_to_rad(ARC_START_DEG)
	var end_rad: float = deg_to_rad(ARC_START_DEG + ARC_SWEEP_DEG)

	# Track (full sweep, dim).
	draw_arc(c, r, start_rad, end_rad, 32, Palette.BORDER, ring_w, true)

	# Active arc, proportional to value position in [min, max].
	var t: float = 0.0
	if max_value > min_value:
		t = (value - min_value) / (max_value - min_value)
	t = clampf(t, 0.0, 1.0)
	var active_end: float = start_rad + (end_rad - start_rad) * t
	if t > 0.0:
		var col: Color = Palette.TEXT_DIM if locked else Palette.ACCENT
		draw_arc(c, r, start_rad, active_end, 32, col, ring_w, true)

	# Indicator pointer at active end.
	var ang: float = active_end
	var inner: Vector2 = c + Vector2(cos(ang), sin(ang)) * (r - ring_w - 2.0)
	var outer: Vector2 = c + Vector2(cos(ang), sin(ang)) * r
	draw_line(inner, outer, Palette.TEXT, 2.0, true)

	# Locked indicator dot.
	if locked:
		draw_circle(Vector2(s.x - 4.0, 4.0), 2.5, Palette.ACCENT)

	# Focus ring.
	if has_focus():
		draw_arc(c, r + 2.0, 0.0, TAU, 36, Palette.BORDER_HI, 1.0, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.alt_pressed:
					set_locked(not locked)
					lock_toggled.emit(locked)
				else:
					_dragging = true
					grab_focus()
				accept_event()
			else:
				_dragging = false
				accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			reset_requested.emit()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_accumulate_scroll(1.0, mb.factor)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_accumulate_scroll(-1.0, mb.factor)
			accept_event()
	elif event is InputEventMouseMotion:
		if not _dragging:
			return
		var mm := event as InputEventMouseMotion
		# Safety: if the left button was released outside our bounds, end drag.
		if not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_dragging = false
			return
		var range_span: float = max_value - min_value
		var delta: float = -mm.relative.y * DRAG_SENSITIVITY * range_span
		_set_snapped(value + delta)
	elif event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		match key.keycode:
			KEY_UP, KEY_RIGHT:
				_step_value(1)
				accept_event()
			KEY_DOWN, KEY_LEFT:
				_step_value(-1)
				accept_event()
			KEY_PAGEUP:
				_step_value(10)
				accept_event()
			KEY_PAGEDOWN:
				_step_value(-10)
				accept_event()
			KEY_HOME:
				_set_snapped(min_value)
				accept_event()
			KEY_END:
				_set_snapped(max_value)
				accept_event()


func _accumulate_scroll(direction: float, factor: float) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _scroll_last_ms > SCROLL_RESET_MS:
		_scroll_accum = 0.0
	_scroll_last_ms = now
	_scroll_accum += direction * maxf(factor, 0.1)
	while _scroll_accum >= SCROLL_STEP_THRESHOLD:
		_scroll_accum -= SCROLL_STEP_THRESHOLD
		_step_value(1)
	while _scroll_accum <= -SCROLL_STEP_THRESHOLD:
		_scroll_accum += SCROLL_STEP_THRESHOLD
		_step_value(-1)


func _step_value(steps: int) -> void:
	var s: float = step if step > 0.0 else (max_value - min_value) * 0.01
	_set_snapped(value + s * steps)


func _set_snapped(v: float) -> void:
	var snapped_v: float = v
	if step > 0.0:
		snapped_v = snappedf(v, step)
	var clamped: float = clampf(snapped_v, min_value, max_value)
	if clamped != value:
		value = clamped
