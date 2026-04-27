extends Control

# Main UI controller for the SFX generator. Builds the entire control tree
# in code so the layout is readable end-to-end without an editor scene.
#
# Architecture:
#   • State (sound, locks, samples, bin) is plain dicts/arrays — no Resource
#     subclasses, so saved sound strings are byte-identical to the JS port.
#   • The module list is built once. Switching channels just rewrites the
#     slider values; we don't tear down and rebuild controls per click.
#   • Channel tabs, mix rows, and bin rows ARE rebuilt on change because
#     their counts are dynamic.

# ── Palette ────────────────────────────────────────────────────────
const COLOR_BG          := Color("#14110d")
const COLOR_PANEL       := Color("#1c1814")
const COLOR_INSET       := Color("#0e0b08")
const COLOR_BORDER      := Color("#3a342a")
const COLOR_BORDER_HI   := Color("#5c5345")
const COLOR_TEXT        := Color("#e8dcc4")
const COLOR_TEXT_MUTE   := Color("#8a8275")
const COLOR_TEXT_DIM    := Color("#5c5345")
const COLOR_ACCENT      := Color("#ff8c1a")

const BIN_PATH := "user://bin.json"

# ── State ──────────────────────────────────────────────────────────
var sound: Dictionary
var active_channel: int = 0
var locks: Array = [{}]                 # locks[i] = Dictionary keyed by param
var samples: PackedFloat32Array = PackedFloat32Array()
var bin: Array = []
var sound_string: String = ""
var status_token: int = 0               # increments per flash to ignore stale resets

# ── Persistent nodes ───────────────────────────────────────────────
var audio_player: AudioStreamPlayer
var save_dialog: FileDialog

var status_label: Label
var waveform: WaveformDisplay
var waveform_info_left: Label
var waveform_info_right: Label

var channel_tabs_container: HBoxContainer
var modules_container: VBoxContainer
var mix_container: VBoxContainer
var master_v_slider: HSlider
var master_v_label: Label
var verb_mix_slider: HSlider
var verb_mix_label: Label
var verb_size_slider: HSlider
var verb_size_label: Label
var sound_string_input: LineEdit
var bin_container: VBoxContainer
var bin_count_label: Label

# Cached references per param key — keyed by param name string.
var param_sliders: Dictionary = {}      # key -> HSlider
var param_value_labels: Dictionary = {} # key -> Label
var param_lock_buttons: Dictionary = {} # key -> Button
var module_panels: Dictionary = {}      # mod_key -> PanelContainer (for dim)
var module_check_buttons: Dictionary = {} # enable_key -> Button (acts as checkbox)
var module_lock_buttons: Dictionary = {}  # enable_key -> Button
var preset_buttons_root: VBoxContainer


# ── Lifecycle ──────────────────────────────────────────────────────
func _ready() -> void:
	sound = SoundData.default_sound()

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.wav", "WAV audio")
	save_dialog.size = Vector2i(720, 520)
	save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(save_dialog)

	_build_ui()
	_load_bin()
	_re_render()
	_refresh_channel_tabs()
	_refresh_mix_rows()
	_refresh_module_values()
	_refresh_master_values()
	_refresh_bin_list()


# ── UI construction ────────────────────────────────────────────────
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 14)
	margin.add_child(root_v)

	root_v.add_child(_build_header())
	root_v.add_child(_build_waveform())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(body)

	body.add_child(_build_left_column())
	body.add_child(_build_right_column())

	root_v.add_child(_build_footer())


func _build_header() -> Control:
	var hdr := HBoxContainer.new()
	hdr.alignment = BoxContainer.ALIGNMENT_BEGIN

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(left)

	var sub := _make_label("// BUFFER GENERATOR · v3.0", 10, COLOR_TEXT_MUTE, 0.4)
	left.add_child(sub)

	var title := _make_label("GODOT_SFX", 24, COLOR_TEXT, 0.08)
	title.add_theme_font_size_override("font_size", 26)
	left.add_child(title)

	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_vertical = Control.SIZE_SHRINK_END
	hdr.add_child(right)

	right.add_child(_make_label("STATUS", 10, COLOR_TEXT_MUTE, 0.3))

	status_label = Label.new()
	status_label.text = "READY"
	status_label.custom_minimum_size = Vector2(120, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", COLOR_ACCENT)
	status_label.add_theme_font_size_override("font_size", 12)
	_set_label_letter_spacing(status_label, 0.2)
	_apply_panel_style(status_label, COLOR_BG, COLOR_ACCENT)
	right.add_child(status_label)

	# Bottom border
	var border_below := ColorRect.new()
	border_below.color = COLOR_BORDER
	border_below.custom_minimum_size = Vector2(0, 1)
	border_below.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.add_child(hdr)
	v.add_child(border_below)
	return v


func _build_waveform() -> Control:
	var panel := PanelContainer.new()
	_apply_panel_style(panel, COLOR_INSET, COLOR_BORDER)
	panel.custom_minimum_size = Vector2(0, 180)

	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(holder)

	waveform = WaveformDisplay.new()
	waveform.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(waveform)

	waveform_info_left = _make_label("WAVEFORM", 10, COLOR_TEXT_MUTE, 0.25)
	waveform_info_left.position = Vector2(10, 6)
	waveform_info_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(waveform_info_left)

	waveform_info_right = _make_label("", 10, COLOR_TEXT_MUTE, 0.25)
	waveform_info_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	waveform_info_right.position = Vector2(-260, 6)
	waveform_info_right.size = Vector2(250, 16)
	waveform_info_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	waveform_info_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(waveform_info_right)

	return panel


# ── Left column: channel tabs + module list ────────────────────────
func _build_left_column() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 3.0
	v.add_theme_constant_override("separation", 8)

	channel_tabs_container = HBoxContainer.new()
	channel_tabs_container.add_theme_constant_override("separation", 4)
	v.add_child(channel_tabs_container)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	modules_container = VBoxContainer.new()
	modules_container.add_theme_constant_override("separation", 6)
	modules_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(modules_container)

	for mod in SoundData.MODULES:
		modules_container.add_child(_make_module_panel(mod))

	return v


func _make_module_panel(mod: Dictionary) -> Control:
	var panel := PanelContainer.new()
	_apply_panel_style(panel, COLOR_PANEL, COLOR_BORDER)
	module_panels[mod.key] = panel

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	v.add_child(_wrap_padded(header, 10, 10, 6, 6))

	# Border under header
	var hdr_border := ColorRect.new()
	hdr_border.color = COLOR_BORDER
	hdr_border.custom_minimum_size = Vector2(0, 1)
	hdr_border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(hdr_border)

	var enable_key: String = mod.enable_key
	var is_toggleable: bool = enable_key != ""

	if is_toggleable:
		var check := _make_check_button("", false)
		check.custom_minimum_size = Vector2(20, 20)
		check.toggled.connect(_on_module_toggled.bind(enable_key))
		header.add_child(check)
		module_check_buttons[enable_key] = check
	else:
		# Always-on indicator
		var indicator := ColorRect.new()
		indicator.color = Color("#332a1f")
		indicator.custom_minimum_size = Vector2(20, 20)
		var inner := ColorRect.new()
		inner.color = COLOR_ACCENT
		inner.set_anchors_preset(Control.PRESET_CENTER)
		inner.position = Vector2(7, 7)
		inner.size = Vector2(6, 6)
		indicator.add_child(inner)
		header.add_child(indicator)

	var title := _make_label(mod.title, 12, COLOR_TEXT, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	if is_toggleable:
		var lock_btn := _make_lock_button()
		lock_btn.pressed.connect(_on_module_lock_pressed.bind(mod))
		header.add_child(lock_btn)
		module_lock_buttons[enable_key] = lock_btn

	# Body: param rows
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 0)
	v.add_child(_wrap_padded(body, 4, 4, 4, 6))

	for pk in mod.params:
		body.add_child(_make_param_row(pk))

	return panel


# A single parameter slider with lock + reset.
func _make_param_row(param_key: String) -> Control:
	var def: Dictionary = SoundData.PARAM_DEFS[param_key]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 22)

	var lock_btn := _make_lock_button()
	lock_btn.pressed.connect(_on_param_lock_pressed.bind(param_key))
	row.add_child(lock_btn)
	param_lock_buttons[param_key] = lock_btn

	var label_btn := Button.new()
	label_btn.text = def.label
	label_btn.flat = true
	label_btn.custom_minimum_size = Vector2(96, 22)
	label_btn.add_theme_color_override("font_color", COLOR_TEXT_MUTE)
	label_btn.add_theme_color_override("font_hover_color", COLOR_ACCENT)
	label_btn.add_theme_font_size_override("font_size", 11)
	label_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_btn.tooltip_text = "Click to reset to default"
	label_btn.pressed.connect(_on_param_reset.bind(param_key))
	row.add_child(label_btn)

	var slider := HSlider.new()
	slider.min_value = def.min
	slider.max_value = def.max
	slider.step = def.step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(120, 22)
	slider.value_changed.connect(_on_param_slider_changed.bind(param_key))
	row.add_child(slider)
	param_sliders[param_key] = slider

	var value_label := Label.new()
	value_label.text = "—"
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.custom_minimum_size = Vector2(72, 22)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	param_value_labels[param_key] = value_label

	return row


# ── Right column: master, presets, actions, sound string, bin ──────
func _build_right_column() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 2.0
	v.custom_minimum_size = Vector2(420, 0)

	v.add_child(_build_master_panel())
	v.add_child(_build_presets_panel())
	v.add_child(_build_actions_panel())
	v.add_child(_build_sound_string_panel())
	v.add_child(_build_bin_panel())

	return v


func _build_master_panel() -> Control:
	var panel := _make_section_panel("MASTER")
	var body: VBoxContainer = panel.get_meta("body")

	body.add_child(_make_label("MIX", 9, COLOR_TEXT_DIM, 0.3))

	mix_container = VBoxContainer.new()
	mix_container.add_theme_constant_override("separation", 4)
	body.add_child(mix_container)

	var output_border := ColorRect.new()
	output_border.color = COLOR_BORDER
	output_border.custom_minimum_size = Vector2(0, 1)
	output_border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_wrap_padded(output_border, 0, 0, 8, 0))
	body.add_child(_make_label("OUTPUT", 9, COLOR_TEXT_DIM, 0.3))

	# Master sliders
	var mv := _make_master_row("VOLUME", 0.0, 1.0, 0.01)
	master_v_slider = mv["slider"]
	master_v_label = mv["value"]
	master_v_slider.value_changed.connect(_on_master_changed.bind("masterVolume"))
	body.add_child(mv["row"])

	var rm := _make_master_row("VERB MIX", 0.0, 1.0, 0.01)
	verb_mix_slider = rm["slider"]
	verb_mix_label = rm["value"]
	verb_mix_slider.value_changed.connect(_on_master_changed.bind("reverbMix"))
	body.add_child(rm["row"])

	var rs := _make_master_row("VERB SIZE", 0.0, 1.0, 0.01)
	verb_size_slider = rs["slider"]
	verb_size_label = rs["value"]
	verb_size_slider.value_changed.connect(_on_master_changed.bind("reverbSize"))
	body.add_child(rs["row"])

	return panel


func _make_master_row(label_text: String, lo: float, hi: float, st: float) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := _make_label(label_text, 10, COLOR_TEXT_MUTE, 0.2)
	lbl.custom_minimum_size = Vector2(80, 22)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = st
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value := Label.new()
	value.text = "—"
	value.custom_minimum_size = Vector2(48, 22)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_color_override("font_color", COLOR_TEXT)
	value.add_theme_font_size_override("font_size", 10)
	row.add_child(value)

	return {"row": row, "slider": slider, "value": value}


func _build_presets_panel() -> Control:
	var panel := _make_section_panel("PRESETS")
	var body: VBoxContainer = panel.get_meta("body")
	preset_buttons_root = VBoxContainer.new()
	preset_buttons_root.add_theme_constant_override("separation", 8)
	body.add_child(preset_buttons_root)

	var groups: Array = ["SHOOTER", "ARCADE"]
	for gi in groups.size():
		var group_name: String = groups[gi]
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		preset_buttons_root.add_child(col)

		col.add_child(_make_label(group_name, 9, COLOR_TEXT_DIM, 0.3))

		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		col.add_child(grid)

		for entry in Presets.REGISTRY:
			if entry.group != group_name:
				continue
			var btn := _make_action_button(entry.name)
			btn.pressed.connect(_on_preset_pressed.bind(entry))
			grid.add_child(btn)

	return panel


func _build_actions_panel() -> Control:
	var panel := _make_section_panel("ACTIONS")
	var body: VBoxContainer = panel.get_meta("body")

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)

	var gen := _make_action_button("⚄ GEN", true)
	gen.pressed.connect(_on_generate_pressed)
	grid.add_child(gen)

	var play := _make_action_button("▶ PLAY")
	play.pressed.connect(_on_play_pressed)
	grid.add_child(play)

	var wav := _make_action_button("↓ WAV")
	wav.pressed.connect(_on_export_pressed)
	grid.add_child(wav)

	return panel


func _build_sound_string_panel() -> Control:
	var panel := _make_section_panel("SOUND STRING")
	var body: VBoxContainer = panel.get_meta("body")

	sound_string_input = LineEdit.new()
	sound_string_input.placeholder_text = "sfx7:..."
	sound_string_input.add_theme_color_override("font_color", COLOR_TEXT)
	sound_string_input.add_theme_color_override("font_placeholder_color", COLOR_TEXT_DIM)
	sound_string_input.add_theme_font_size_override("font_size", 11)
	_apply_lineedit_style(sound_string_input)
	body.add_child(sound_string_input)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)

	var copy_btn := _make_action_button("⧉ COPY")
	copy_btn.pressed.connect(_on_copy_pressed)
	grid.add_child(copy_btn)

	var paste_btn := _make_action_button("⏎ PASTE")
	paste_btn.pressed.connect(_on_paste_pressed)
	grid.add_child(paste_btn)

	var load_btn := _make_action_button("LOAD")
	load_btn.pressed.connect(_on_load_string_pressed)
	grid.add_child(load_btn)

	return panel


func _build_bin_panel() -> Control:
	var panel := _make_section_panel("BIN [0]", true)
	var body: VBoxContainer = panel.get_meta("body")
	bin_count_label = panel.get_meta("title")

	var save_btn := _make_action_button("+ SAVE")
	save_btn.pressed.connect(_on_save_to_bin_pressed)
	panel.get_meta("title_row").add_child(save_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 200)
	body.add_child(scroll)

	bin_container = VBoxContainer.new()
	bin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bin_container)

	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return panel


func _build_footer() -> Control:
	var border := ColorRect.new()
	border.color = COLOR_BORDER
	border.custom_minimum_size = Vector2(0, 1)
	border.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var foot := _make_label(
		"UP TO 4 CHANNELS · MIX & REVERB IN MASTER · LOCK PARAMS OR MODULES TO HOLD THEM THROUGH GEN · BIN PERSISTS",
		10, COLOR_TEXT_DIM, 0.3
	)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(border)
	v.add_child(foot)
	return v


# ── UI helpers ─────────────────────────────────────────────────────

func _make_label(text: String, font_size: int, color: Color, letter_spacing: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if letter_spacing > 0.0:
		_set_label_letter_spacing(l, letter_spacing)
	return l


# Approximates the JS letter-spacing by injecting non-breaking spaces between
# characters. Letter-spacing as a font setting requires a custom font setup.
func _set_label_letter_spacing(_l: Label, _spacing_em: float) -> void:
	# No-op — left in place so we have a single place to upgrade later if we
	# add a custom font with adjustable spacing.
	pass


func _wrap_padded(child: Control, l: int, r: int, t: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_bottom", b)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(child)
	return m


# Returns a PanelContainer whose body is a child VBoxContainer. The panel
# carries metadata so callers can append into the body and (optionally) the
# title row.
func _make_section_panel(title_text: String, _flexible_height: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	_apply_panel_style(panel, COLOR_PANEL, COLOR_BORDER)

	var v := VBoxContainer.new()
	panel.add_child(v)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	v.add_child(_wrap_padded(title_row, 14, 14, 8, 8))

	var title := _make_label(title_text, 10, COLOR_TEXT_MUTE, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var border := ColorRect.new()
	border.color = COLOR_BORDER
	border.custom_minimum_size = Vector2(0, 1)
	border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(border)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	v.add_child(_wrap_padded(body, 12, 12, 8, 10))

	panel.set_meta("body", body)
	panel.set_meta("title", title)
	panel.set_meta("title_row", title_row)
	return panel


func _make_action_button(text: String, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_color_override("font_color", COLOR_TEXT)
	b.add_theme_color_override("font_hover_color", COLOR_BG)
	b.add_theme_color_override("font_pressed_color", COLOR_BG)
	b.add_theme_font_size_override("font_size", 11)
	b.custom_minimum_size = Vector2(0, 26)

	var normal := _make_stylebox(Color("#261f17") if primary else Color(0, 0, 0, 0), COLOR_BORDER_HI)
	var hover := _make_stylebox(COLOR_ACCENT, COLOR_ACCENT)
	var pressed := _make_stylebox(COLOR_ACCENT, COLOR_ACCENT)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", normal)
	return b


func _make_lock_button() -> Button:
	var b := Button.new()
	b.text = "🔒"
	b.tooltip_text = "Lock to preserve while randomizing"
	b.custom_minimum_size = Vector2(22, 22)
	b.add_theme_font_size_override("font_size", 10)
	b.toggle_mode = false
	_apply_button_style(b, false)
	return b


func _apply_button_style(b: Button, locked: bool) -> void:
	var bg: Color = COLOR_ACCENT if locked else Color(0, 0, 0, 0)
	var border: Color = COLOR_ACCENT if locked else COLOR_BORDER_HI
	var fg: Color = COLOR_BG if locked else COLOR_TEXT_DIM

	var normal := _make_stylebox(bg, border)
	var hover := _make_stylebox(COLOR_ACCENT, COLOR_ACCENT)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", COLOR_BG)
	b.text = "🔒" if locked else "🔓"


# Custom checkbox-style toggle button — the React app uses a 16px box that
# fills with accent color when on, so we replicate it instead of the default
# Godot CheckBox (which doesn't accept the same styling).
func _make_check_button(text: String, on: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = on
	_apply_check_style(b, on)
	return b


func _apply_check_style(b: Button, on: bool) -> void:
	var bg: Color = COLOR_ACCENT if on else Color(0, 0, 0, 0)
	var fg: Color = COLOR_BG if on else COLOR_TEXT_MUTE
	var border: Color = COLOR_ACCENT if on else COLOR_BORDER_HI
	var normal := _make_stylebox(bg, border)
	var hover := _make_stylebox(bg.lightened(0.05) if on else COLOR_BORDER, border)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", fg)
	b.text = "■" if on else " "
	b.add_theme_font_size_override("font_size", 10)


func _make_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


func _apply_panel_style(node: Control, bg: Color, border: Color) -> void:
	var s := _make_stylebox(bg, border)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	# PanelContainer uses "panel"; Label uses "normal".
	if node is PanelContainer:
		node.add_theme_stylebox_override("panel", s)
	else:
		node.add_theme_stylebox_override("normal", s)


func _apply_lineedit_style(le: LineEdit) -> void:
	var n := _make_stylebox(COLOR_INSET, COLOR_BORDER)
	var f := _make_stylebox(COLOR_INSET, COLOR_ACCENT)
	le.add_theme_stylebox_override("normal", n)
	le.add_theme_stylebox_override("focus", f)


# ── Refresh helpers ────────────────────────────────────────────────

func _re_render() -> void:
	samples = Synth.render_sound(sound)
	if waveform:
		waveform.set_samples(samples)
	sound_string = SoundData.sound_to_string(sound)
	if sound_string_input and not sound_string_input.has_focus():
		sound_string_input.text = sound_string
	_refresh_waveform_info()


func _refresh_waveform_info() -> void:
	if waveform_info_left == null:
		return
	var ms: int = int(round(float(samples.size()) / float(SoundData.SAMPLE_RATE) * 1000.0))
	waveform_info_left.text = "WAVEFORM · %d SMP · %dms · %dCH" % [samples.size(), ms, sound.channels.size()]
	var ch: Dictionary = sound.channels[active_channel]
	var mode_idx: int = clampi(int(ch.mode), 0, SoundData.MODES.size() - 1)
	waveform_info_right.text = "CH%d · %s @ %dHz" % [active_channel + 1, SoundData.MODES[mode_idx], int(round(float(ch.pitch)))]


func _refresh_channel_tabs() -> void:
	for c in channel_tabs_container.get_children():
		c.queue_free()

	for i in sound.channels.size():
		var ch_dict: Dictionary = sound.channels[i]
		var btn := Button.new()
		btn.text = "CH %d" % (i + 1)
		btn.custom_minimum_size = Vector2(60, 28)
		btn.add_theme_font_size_override("font_size", 11)

		var active: bool = i == active_channel
		var bg: Color = COLOR_ACCENT if active else Color(0, 0, 0, 0)
		var fg: Color = COLOR_BG if active else COLOR_TEXT
		var border: Color = COLOR_ACCENT if (active or bool(ch_dict.get("soloed", false))) else COLOR_BORDER
		var normal := _make_stylebox(bg, border)
		var hover := _make_stylebox(COLOR_ACCENT.lightened(0.05) if active else Color(1, 0.55, 0.1, 0.08), border)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", normal)
		btn.add_theme_stylebox_override("focus", normal)
		btn.add_theme_color_override("font_color", fg)
		btn.add_theme_color_override("font_hover_color", fg)
		btn.modulate = Color(1, 1, 1, 0.5) if bool(ch_dict.get("muted", false)) else Color.WHITE
		btn.pressed.connect(_on_channel_tab_pressed.bind(i))
		channel_tabs_container.add_child(btn)

	if sound.channels.size() < SoundData.MAX_CHANNELS:
		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(40, 28)
		add_btn.add_theme_font_size_override("font_size", 14)
		add_btn.tooltip_text = "Add channel"
		var n := _make_stylebox(Color(0, 0, 0, 0), COLOR_BORDER)
		var h := _make_stylebox(Color(0, 0, 0, 0), COLOR_ACCENT)
		add_btn.add_theme_stylebox_override("normal", n)
		add_btn.add_theme_stylebox_override("hover", h)
		add_btn.add_theme_stylebox_override("pressed", n)
		add_btn.add_theme_stylebox_override("focus", n)
		add_btn.add_theme_color_override("font_color", COLOR_TEXT_MUTE)
		add_btn.add_theme_color_override("font_hover_color", COLOR_ACCENT)
		add_btn.pressed.connect(_on_add_channel_pressed)
		channel_tabs_container.add_child(add_btn)


func _refresh_mix_rows() -> void:
	for c in mix_container.get_children():
		c.queue_free()

	for i in sound.channels.size():
		mix_container.add_child(_make_mix_row(i))


func _make_mix_row(i: int) -> Control:
	var ch_dict: Dictionary = sound.channels[i]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var label_btn := Button.new()
	label_btn.text = "CH%d" % (i + 1)
	label_btn.flat = true
	label_btn.custom_minimum_size = Vector2(40, 22)
	label_btn.add_theme_color_override("font_color", COLOR_ACCENT if i == active_channel else COLOR_TEXT_MUTE)
	label_btn.add_theme_color_override("font_hover_color", COLOR_ACCENT)
	label_btn.add_theme_font_size_override("font_size", 10)
	label_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_btn.pressed.connect(_on_channel_tab_pressed.bind(i))
	row.add_child(label_btn)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = float(ch_dict.get("level", 1.0))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_channel_level_changed.bind(i))
	row.add_child(slider)

	var muted: bool = bool(ch_dict.get("muted", false))
	var mute_btn := _make_mini_btn("M", muted)
	mute_btn.tooltip_text = "Unmute" if muted else "Mute"
	mute_btn.pressed.connect(_on_channel_mute_pressed.bind(i))
	row.add_child(mute_btn)

	var soloed: bool = bool(ch_dict.get("soloed", false))
	var solo_btn := _make_mini_btn("S", soloed)
	solo_btn.tooltip_text = "Unsolo" if soloed else "Solo"
	solo_btn.pressed.connect(_on_channel_solo_pressed.bind(i))
	row.add_child(solo_btn)

	if sound.channels.size() > 1:
		var del_btn := _make_mini_btn("×", false)
		del_btn.tooltip_text = "Remove channel"
		del_btn.pressed.connect(_on_channel_delete_pressed.bind(i))
		row.add_child(del_btn)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(22, 22)
		row.add_child(spacer)

	return row


func _make_mini_btn(text: String, on: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(22, 22)
	b.add_theme_font_size_override("font_size", 10)
	var bg: Color = COLOR_ACCENT if on else Color(0, 0, 0, 0)
	var fg: Color = COLOR_BG if on else COLOR_TEXT_MUTE
	var border: Color = COLOR_ACCENT if on else COLOR_BORDER_HI
	var normal := _make_stylebox(bg, border)
	var hover := _make_stylebox(COLOR_ACCENT, COLOR_ACCENT)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", COLOR_BG)
	return b


# Update slider values + lock states for the active channel WITHOUT
# triggering signal emission cascades (which would cause feedback loops).
func _refresh_module_values() -> void:
	var ch_dict: Dictionary = sound.channels[active_channel]
	var ch_locks: Dictionary = locks[active_channel] if active_channel < locks.size() else {}

	for key in param_sliders.keys():
		var slider: HSlider = param_sliders[key]
		var v: float = float(ch_dict.get(key, 0.0))
		# set_value_no_signal avoids the round-trip back into _on_param_slider_changed.
		slider.set_value_no_signal(v)
		var label: Label = param_value_labels[key]
		label.text = SoundData.format_value(key, v)
		var lock_btn: Button = param_lock_buttons[key]
		_apply_button_style(lock_btn, bool(ch_locks.get(key, false)))

	for mod in SoundData.MODULES:
		var ek: String = mod.enable_key
		if ek == "":
			continue
		var enabled: bool = bool(ch_dict.get(ek, false))
		var check_btn: Button = module_check_buttons[ek]
		check_btn.set_pressed_no_signal(enabled)
		_apply_check_style(check_btn, enabled)
		var lock_btn: Button = module_lock_buttons[ek]
		_apply_button_style(lock_btn, bool(ch_locks.get(ek, false)))

		# Dim the panel when the module is disabled.
		var panel: Control = module_panels[mod.key]
		panel.modulate = Color(1, 1, 1, 0.55) if (mod.enable_key != "" and not enabled) else Color.WHITE


func _refresh_master_values() -> void:
	if master_v_slider == null:
		return
	master_v_slider.set_value_no_signal(float(sound.master.masterVolume))
	master_v_label.text = "%.2f" % float(sound.master.masterVolume)
	verb_mix_slider.set_value_no_signal(float(sound.master.reverbMix))
	verb_mix_label.text = "%.2f" % float(sound.master.reverbMix)
	verb_size_slider.set_value_no_signal(float(sound.master.reverbSize))
	verb_size_label.text = "%.2f" % float(sound.master.reverbSize)


func _refresh_bin_list() -> void:
	for c in bin_container.get_children():
		c.queue_free()

	bin_count_label.text = "BIN [%d]" % bin.size()

	if bin.is_empty():
		var empty := _make_label("EMPTY · SAVE A SOUND", 11, COLOR_TEXT_DIM, 0.3)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bin_container.add_child(_wrap_padded(empty, 0, 0, 24, 24))
		return

	for entry in bin:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := _make_label(entry.get("name", "—"), 11, COLOR_TEXT, 0.1)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var play_btn := Button.new()
		play_btn.text = "▶"
		play_btn.flat = true
		play_btn.tooltip_text = "Load and play"
		play_btn.add_theme_color_override("font_color", COLOR_ACCENT)
		play_btn.custom_minimum_size = Vector2(22, 22)
		play_btn.pressed.connect(_on_bin_load_pressed.bind(entry.get("id", 0)))
		row.add_child(play_btn)

		var del_btn := Button.new()
		del_btn.text = "×"
		del_btn.flat = true
		del_btn.tooltip_text = "Delete"
		del_btn.add_theme_color_override("font_color", COLOR_TEXT_MUTE)
		del_btn.add_theme_color_override("font_hover_color", COLOR_ACCENT)
		del_btn.custom_minimum_size = Vector2(22, 22)
		del_btn.pressed.connect(_on_bin_delete_pressed.bind(entry.get("id", 0)))
		row.add_child(del_btn)

		var separator := ColorRect.new()
		separator.color = Color("#221d17")
		separator.custom_minimum_size = Vector2(0, 1)
		separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(_wrap_padded(row, 12, 12, 6, 6))
		v.add_child(separator)
		bin_container.add_child(v)


# ── Param + module handlers ────────────────────────────────────────

func _on_param_slider_changed(value: float, key: String) -> void:
	# Step is enforced by HSlider.step; the def may also store ints.
	var def: Dictionary = SoundData.PARAM_DEFS[key]
	var stored_value: Variant = value
	if def.has("step") and def.step >= 1.0:
		stored_value = int(round(value))

	# Booleans are not addressed here — only modules toggle bools, and the
	# default channel dict already has int/float for everything else.
	sound.channels[active_channel][key] = stored_value
	param_value_labels[key].text = SoundData.format_value(key, value)
	_re_render()
	# Keep the channel-tab right-side header info in sync.
	_refresh_waveform_info()


func _on_param_lock_pressed(key: String) -> void:
	var cur: Dictionary = locks[active_channel]
	cur[key] = not bool(cur.get(key, false))
	_apply_button_style(param_lock_buttons[key], bool(cur[key]))


func _on_param_reset(key: String) -> void:
	var def_value: Variant = SoundData.DEFAULT_PARAMS[key]
	sound.channels[active_channel][key] = def_value
	# Slider value (always a float for the slider control)
	var slider: HSlider = param_sliders[key]
	slider.set_value_no_signal(float(def_value))
	param_value_labels[key].text = SoundData.format_value(key, float(def_value))
	_re_render()


func _on_module_toggled(pressed: bool, enable_key: String) -> void:
	sound.channels[active_channel][enable_key] = pressed
	# Re-style and re-dim
	_apply_check_style(module_check_buttons[enable_key], pressed)
	for mod in SoundData.MODULES:
		if mod.enable_key == enable_key:
			module_panels[mod.key].modulate = Color(1, 1, 1, 0.55) if not pressed else Color.WHITE
			break
	_re_render()


# Module-level lock: locks the enable flag plus every param in the module.
func _on_module_lock_pressed(mod: Dictionary) -> void:
	if mod.enable_key == "":
		return
	var cur: Dictionary = locks[active_channel]
	var will_lock: bool = not bool(cur.get(mod.enable_key, false))
	cur[mod.enable_key] = will_lock
	for p in mod.params:
		cur[p] = will_lock
	_apply_button_style(module_lock_buttons[mod.enable_key], will_lock)
	for p in mod.params:
		_apply_button_style(param_lock_buttons[p], will_lock)


# ── Channel handlers ───────────────────────────────────────────────

func _on_channel_tab_pressed(idx: int) -> void:
	active_channel = idx
	_refresh_channel_tabs()
	_refresh_mix_rows()
	_refresh_module_values()
	_refresh_waveform_info()


func _on_add_channel_pressed() -> void:
	if sound.channels.size() >= SoundData.MAX_CHANNELS:
		return
	sound.channels.append(SoundData.clone_params())
	locks.append({})
	active_channel = sound.channels.size() - 1
	_flash_status("+ CH %d" % (active_channel + 1))
	_refresh_channel_tabs()
	_refresh_mix_rows()
	_refresh_module_values()
	_re_render()


func _on_channel_delete_pressed(idx: int) -> void:
	if sound.channels.size() <= 1:
		return
	sound.channels.remove_at(idx)
	if idx < locks.size():
		locks.remove_at(idx)
	if idx < active_channel:
		active_channel -= 1
	elif idx == active_channel:
		active_channel = max(0, active_channel - 1)
	_refresh_channel_tabs()
	_refresh_mix_rows()
	_refresh_module_values()
	_re_render()


func _on_channel_level_changed(value: float, idx: int) -> void:
	sound.channels[idx]["level"] = value
	_re_render()


func _on_channel_mute_pressed(idx: int) -> void:
	sound.channels[idx]["muted"] = not bool(sound.channels[idx].get("muted", false))
	_refresh_mix_rows()
	_refresh_channel_tabs()
	_re_render()


func _on_channel_solo_pressed(idx: int) -> void:
	sound.channels[idx]["soloed"] = not bool(sound.channels[idx].get("soloed", false))
	_refresh_mix_rows()
	_refresh_channel_tabs()
	_re_render()


# ── Master handlers ────────────────────────────────────────────────

func _on_master_changed(value: float, key: String) -> void:
	sound.master[key] = value
	match key:
		"masterVolume":
			master_v_label.text = "%.2f" % value
		"reverbMix":
			verb_mix_label.text = "%.2f" % value
		"reverbSize":
			verb_size_label.text = "%.2f" % value
	_re_render()


# ── Action handlers ────────────────────────────────────────────────

func _on_generate_pressed() -> void:
	var ch: Dictionary = sound.channels[active_channel]
	var ch_locks: Dictionary = Presets.effective_locks(locks[active_channel])
	var new_patch: Dictionary = Presets.randomize_all(ch, ch_locks)
	sound.channels[active_channel] = new_patch
	_apply_and_play("GEN")
	_refresh_module_values()


func _on_play_pressed() -> void:
	_play_samples(samples)


func _on_export_pressed() -> void:
	if samples.is_empty():
		_flash_status("EMPTY")
		return
	save_dialog.current_file = "sfx_%s.wav" % Time.get_ticks_msec()
	save_dialog.popup_centered()


func _on_save_file_selected(path: String) -> void:
	var bytes: PackedByteArray = SoundData.encode_wav(samples)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_flash_status("WRITE FAIL")
		return
	f.store_buffer(bytes)
	f.close()
	_flash_status("EXPORTED")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(sound_string)
	_flash_status("COPIED")


func _on_paste_pressed() -> void:
	var text := DisplayServer.clipboard_get()
	var s = SoundData.sound_from_string(text)
	if s == null:
		_flash_status("INVALID")
		return
	_replace_sound(s, "PASTED")


func _on_load_string_pressed() -> void:
	var s = SoundData.sound_from_string(sound_string_input.text)
	if s == null:
		_flash_status("INVALID")
		return
	_replace_sound(s, "LOADED")


func _on_preset_pressed(entry: Dictionary) -> void:
	if entry.kind == "sound":
		var s = Presets.run_preset(entry, {}, {})
		_replace_sound(s, entry.name)
		return

	var ch: Dictionary = sound.channels[active_channel]
	var ch_locks: Dictionary = Presets.effective_locks(locks[active_channel])
	var new_patch = Presets.run_preset(entry, ch, ch_locks)
	# Patch presets collapse to a single-channel sound (matches JS behavior).
	var new_sound: Dictionary = {
		"channels": [SoundData.clone_params()],
		"master": SoundData.clone_master(),
	}
	new_sound.channels[0].merge(new_patch, true)
	locks = [locks[active_channel].duplicate(true)]
	active_channel = 0
	sound = new_sound
	_apply_and_play(entry.name)
	_refresh_channel_tabs()
	_refresh_mix_rows()
	_refresh_module_values()
	_refresh_master_values()


# ── Bin handlers ───────────────────────────────────────────────────

func _on_save_to_bin_pressed() -> void:
	var id: int = Time.get_ticks_msec()
	var entry: Dictionary = {
		"id": id,
		"name": "sfx_%dch_%s" % [sound.channels.size(), str(id).right(5)],
		"string": sound_string,
	}
	bin = [entry] + bin
	# Cap at 100 entries (oldest fall off the end).
	if bin.size() > 100:
		bin.resize(100)
	_persist_bin()
	_refresh_bin_list()
	_flash_status("SAVED")


func _on_bin_load_pressed(id: int) -> void:
	for entry in bin:
		if int(entry.get("id", -1)) != id:
			continue
		var s = SoundData.sound_from_string(entry.string)
		if s == null:
			_flash_status("CORRUPT")
			return
		_replace_sound(s, "LOADED")
		return


func _on_bin_delete_pressed(id: int) -> void:
	bin = bin.filter(func(e): return int(e.get("id", -1)) != id)
	_persist_bin()
	_refresh_bin_list()


func _persist_bin() -> void:
	var f := FileAccess.open(BIN_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(bin))
	f.close()


func _load_bin() -> void:
	if not FileAccess.file_exists(BIN_PATH):
		return
	var f := FileAccess.open(BIN_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Array:
		bin = parsed


# ── Sound-level helpers ────────────────────────────────────────────

func _replace_sound(new_sound: Dictionary, label: String) -> void:
	sound = new_sound
	locks = []
	for c in sound.channels:
		locks.append({})
	active_channel = 0
	_apply_and_play(label)
	_refresh_channel_tabs()
	_refresh_mix_rows()
	_refresh_module_values()
	_refresh_master_values()


func _apply_and_play(label: String) -> void:
	_re_render()
	_flash_status(label)
	_play_samples(samples)


# ── Audio playback ─────────────────────────────────────────────────

func _play_samples(buf: PackedFloat32Array) -> void:
	if buf.is_empty():
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SoundData.SAMPLE_RATE
	stream.stereo = false
	# Encode the samples as 16-bit little-endian PCM (no header — AudioStreamWAV
	# wants raw sample bytes, unlike our WAV exporter).
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v: float = clamp(buf[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	stream.data = bytes
	audio_player.stop()
	audio_player.stream = stream
	audio_player.play()


# ── Status flash ───────────────────────────────────────────────────

func _flash_status(msg: String) -> void:
	status_label.text = msg
	# Filled-pill state when transient, hollow when "READY".
	_apply_panel_style(status_label, COLOR_ACCENT, COLOR_ACCENT)
	status_label.add_theme_color_override("font_color", COLOR_BG)
	status_token += 1
	var token := status_token
	get_tree().create_timer(1.4).timeout.connect(func():
		if token != status_token:
			return
		status_label.text = "READY"
		_apply_panel_style(status_label, COLOR_BG, COLOR_ACCENT)
		status_label.add_theme_color_override("font_color", COLOR_ACCENT)
	)


# ── Input ──────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# Spacebar replays the current sound (matches the React app's `play_sound`
	# action). Skipped when a text field is focused so users can type spaces.
	if event.is_action_pressed("play_sound") and not _line_edit_focused():
		_on_play_pressed()


func _line_edit_focused() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and f is LineEdit
