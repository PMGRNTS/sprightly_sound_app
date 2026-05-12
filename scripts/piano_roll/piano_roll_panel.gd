class_name PianoRollPanel
extends VBoxContainer

# Toolbar + ScrollContainer + PianoRollDisplay. Owns the display and
# toolbar controls; emits signals upward to the controller (main.gd).
# Note-edit signals from PianoRollDisplay are handled internally —
# they mutate PianoRollState directly, then queue_redraw().

signal sequence_play_requested
signal sequence_stop_requested
signal sequence_export_requested
signal bpm_changed(bpm: int)
signal bars_changed(bars: int)
signal notes_changed

var state: PianoRollState
var display: PianoRollDisplay

var _bpm_spin: SpinBox
var _bars_spin: SpinBox
var _channel_btn: Button
var _play_btn: Button
var _zoom_slider: HSlider


func setup(pr_state: PianoRollState, sound_state: SoundState) -> void:
	state = pr_state

	add_theme_constant_override("separation", 4)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Toolbar
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	add_child(toolbar)

	toolbar.add_child(UIFactory.make_label("BPM", Palette.FONT_SMALL, Palette.TEXT_MUTE, 0.3))
	_bpm_spin = SpinBox.new()
	_bpm_spin.min_value = 40
	_bpm_spin.max_value = 300
	_bpm_spin.step = 1
	_bpm_spin.value = state.bpm
	_bpm_spin.custom_minimum_size = Vector2(70, 22)
	_bpm_spin.value_changed.connect(_on_bpm_changed)
	toolbar.add_child(_bpm_spin)

	toolbar.add_child(UIFactory.make_label("BARS", Palette.FONT_SMALL, Palette.TEXT_MUTE, 0.3))
	_bars_spin = SpinBox.new()
	_bars_spin.min_value = 1
	_bars_spin.max_value = 8
	_bars_spin.step = 1
	_bars_spin.value = state.bars
	_bars_spin.custom_minimum_size = Vector2(56, 22)
	_bars_spin.value_changed.connect(_on_bars_changed)
	toolbar.add_child(_bars_spin)

	_channel_btn = UIFactory.make_action_button("CH 1")
	_channel_btn.custom_minimum_size = Vector2(56, 22)
	_channel_btn.tooltip_text = "Active channel for new notes"
	_channel_btn.pressed.connect(_on_channel_cycle)
	toolbar.add_child(_channel_btn)

	_play_btn = UIFactory.make_action_button("▶ PLAY")
	_play_btn.custom_minimum_size = Vector2(72, 22)
	_play_btn.pressed.connect(func(): sequence_play_requested.emit())
	toolbar.add_child(_play_btn)

	var stop_btn := UIFactory.make_action_button("■ STOP")
	stop_btn.custom_minimum_size = Vector2(64, 22)
	stop_btn.pressed.connect(func(): sequence_stop_requested.emit())
	toolbar.add_child(stop_btn)

	var export_btn := UIFactory.make_action_button("↓ WAV")
	export_btn.custom_minimum_size = Vector2(60, 22)
	export_btn.pressed.connect(func(): sequence_export_requested.emit())
	toolbar.add_child(export_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	toolbar.add_child(UIFactory.make_label("ZOOM", Palette.FONT_SMALL, Palette.TEXT_MUTE, 0.3))
	_zoom_slider = HSlider.new()
	_zoom_slider.min_value = 0.5
	_zoom_slider.max_value = 4.0
	_zoom_slider.step = 0.1
	_zoom_slider.value = 1.0
	_zoom_slider.custom_minimum_size = Vector2(80, 22)
	_zoom_slider.value_changed.connect(_on_zoom_changed)
	toolbar.add_child(_zoom_slider)

	add_child(UIFactory.make_hairline())

	# Display inside a ScrollContainer
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	display = PianoRollDisplay.new()
	display.state = state
	display.active_channel = sound_state.active_channel
	# The display needs a minimum size large enough to show the full grid.
	# It expands horizontally with zoom.
	_update_display_size()
	scroll.add_child(display)

	# Wire note-edit signals → state mutations → redraw
	display.note_added.connect(_on_note_added)
	display.note_removed.connect(_on_note_removed)
	display.note_moved.connect(_on_note_moved)
	display.note_resized.connect(_on_note_resized)

	_update_channel_label(sound_state.active_channel, sound_state.sound.channels.size())


func refresh(sound_state: SoundState) -> void:
	if display == null or state == null:
		return
	display.active_channel = sound_state.active_channel
	_bpm_spin.set_value_no_signal(state.bpm)
	_bars_spin.set_value_no_signal(state.bars)
	_update_channel_label(sound_state.active_channel, sound_state.sound.channels.size())
	_update_display_size()
	display.queue_redraw()


func set_playhead(beat: float) -> void:
	if display != null:
		display.playhead_beat = beat
		display.queue_redraw()


# ── Internal handlers ─────────────────────────────────────────────

func _on_note_added(channel: int, midi: int, beat: float, length: float) -> void:
	state.push_undo()
	state.add_note(channel, midi, beat, length)
	display.queue_redraw()
	notes_changed.emit()

func _on_note_removed(idx: int) -> void:
	state.push_undo()
	state.remove_note(idx)
	display.queue_redraw()
	notes_changed.emit()

func _on_note_moved(idx: int, new_midi: int, new_beat: float) -> void:
	state.move_note(idx, new_midi, new_beat)
	display.queue_redraw()
	notes_changed.emit()

func _on_note_resized(idx: int, new_length: float) -> void:
	state.resize_note(idx, new_length)
	display.queue_redraw()
	notes_changed.emit()

func _on_bpm_changed(value: float) -> void:
	bpm_changed.emit(int(value))

func _on_bars_changed(value: float) -> void:
	bars_changed.emit(int(value))

func _on_channel_cycle() -> void:
	# Cycle through available channels (visual-only; actual channel
	# selection is driven by the SFX editor's channel tabs).
	var next: int = (display.active_channel + 1) % SoundData.MAX_CHANNELS
	display.active_channel = next
	_channel_btn.text = "CH %d" % (next + 1)
	display.queue_redraw()

func _on_zoom_changed(value: float) -> void:
	display.zoom = value
	_update_display_size()
	display.queue_redraw()


func _update_display_size() -> void:
	if display == null or state == null:
		return
	var total_rows: int = PianoRollState.MAX_MIDI - PianoRollState.MIN_MIDI + 1
	var grid_h: float = float(total_rows) * PianoRollDisplay.ROW_HEIGHT
	var grid_w: float = 800.0 * display.zoom
	display.custom_minimum_size = Vector2(PianoRollDisplay.KEY_WIDTH + grid_w, grid_h)


func _update_channel_label(active_ch: int, num_channels: int) -> void:
	if _channel_btn == null:
		return
	display.active_channel = clampi(active_ch, 0, num_channels - 1)
	_channel_btn.text = "CH %d" % (display.active_channel + 1)
