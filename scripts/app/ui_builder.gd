class_name UIBuilder
extends RefCounted

# Owns UI construction + refresh logic. Holds the cached node references
# (param_knobs, module_panels, etc.) needed to update controls in place
# rather than tearing down and rebuilding on every state change.
#
# Wiring model: build_ui() takes the host Control (which is also the
# controller — main.gd) and connects UI signals directly to its handlers
# via `host._on_X.bind(...)`. UIBuilder is not a reusable component;
# it's tightly coupled to main.gd's handler API by design.
#
# State reads: refresh_* methods read directly from `state` (SoundState).
# State mutations: never happen here — main.gd handlers mutate state and
# then call the appropriate refresh_*.

# Module pairing for the 2-column grid. Five rows × two cols puts every
# module on one screen at 1280×900 with no scrolling.
const MODULE_ROW_PAIRS := [
	["source",   "amp"],
	["filter",   "pitchEnv"],
	["vibrato",  "tremolo"],
	["arpeggio", "delay"],
	["drive",    "crush"],
]


var _state: SoundState
var _host: Control                       # main.gd — also the controller for signal binds

# Persistent UI references (built once)
var status_label: Label
var waveform: WaveformDisplay
var waveform_info_left: Label
var waveform_info_right: Label
var onomatopoeia_input: LineEdit
var sound_string_input: LineEdit
var bin_search_input: LineEdit
var bin_search_query: String = ""
var bin_count_label: Label
var bin_container: VBoxContainer
var variation_seed_input: SpinBox
var channel_tabs_container: HBoxContainer
var modules_container: GridContainer
var mix_container: VBoxContainer
var master_v_knob: Knob
var master_v_label: Label
var verb_mix_knob: Knob
var verb_mix_label: Label
var verb_size_knob: Knob
var verb_size_label: Label
var preset_buttons_root: VBoxContainer

# Cached references per param key — keyed by param name string.
var param_knobs: Dictionary[String, Knob] = {}
var param_value_labels: Dictionary[String, Label] = {}
var module_panels: Dictionary[String, PanelContainer] = {}
var module_check_buttons: Dictionary[String, Button] = {}
var module_lock_buttons: Dictionary[String, Button] = {}

# Preset panel state
var preset_active_group: String = ""
var preset_tab_buttons: Dictionary[String, Button] = {}
var preset_grids: Dictionary[String, GridContainer] = {}

# Save-preset dialog (lazily built on first use).
var _save_preset_dialog: ConfirmationDialog
var _save_preset_name_input: LineEdit

# Status flash token (incremented per flash so stale resets are ignored).
var _status_token: int = 0


func _init(host: Control, state: SoundState) -> void:
	_host = host
	_state = state


# ── Top-level build ─────────────────────────────────────────────────

func build_ui() -> void:
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_host.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", Palette.WINDOW_MARGIN_H)
	margin.add_theme_constant_override("margin_right", Palette.WINDOW_MARGIN_H)
	margin.add_theme_constant_override("margin_top", Palette.WINDOW_MARGIN_V)
	margin.add_theme_constant_override("margin_bottom", Palette.WINDOW_MARGIN_V)
	_host.add_child(margin)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 8)
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
	hdr.add_theme_constant_override("separation", 16)

	var left := VBoxContainer.new()
	hdr.add_child(left)

	var sub := UIFactory.make_label("// BUFFER GENERATOR · v3.0", 10, Palette.TEXT_MUTE, 0.4)
	left.add_child(sub)

	var title := UIFactory.make_label("GODOT_SFX", 24, Palette.TEXT, 0.08)
	title.add_theme_font_size_override("font_size", Palette.FONT_TITLE)
	left.add_child(title)

	# Onomatopoeia input. Type a word, hit Enter or click → to convert.
	# Eats the dead horizontal space between the title and STATUS pill.
	var ono_box := HBoxContainer.new()
	ono_box.add_theme_constant_override("separation", 6)
	ono_box.size_flags_vertical = Control.SIZE_SHRINK_END
	ono_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(ono_box)

	ono_box.add_child(UIFactory.make_label("SAY", Palette.FONT_SMALL, Palette.TEXT_MUTE, 0.3))

	onomatopoeia_input = LineEdit.new()
	onomatopoeia_input.placeholder_text = "BOOM · tick · whoosh · zap"
	onomatopoeia_input.add_theme_color_override("font_color", Palette.TEXT)
	onomatopoeia_input.add_theme_color_override("font_placeholder_color", Palette.TEXT_DIM)
	onomatopoeia_input.add_theme_font_size_override("font_size", Palette.FONT_VALUE)
	onomatopoeia_input.custom_minimum_size = Palette.HEADER_INPUT_SIZE
	onomatopoeia_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.apply_lineedit_style(onomatopoeia_input)
	onomatopoeia_input.text_submitted.connect(_host._on_onomatopoeia_submitted)
	ono_box.add_child(onomatopoeia_input)

	var apply_btn := UIFactory.make_action_button("→", true)
	apply_btn.tooltip_text = "Convert text to sound parameters"
	apply_btn.custom_minimum_size = Palette.HEADER_BTN_SIZE
	apply_btn.pressed.connect(_host._on_onomatopoeia_apply_pressed)
	ono_box.add_child(apply_btn)

	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_vertical = Control.SIZE_SHRINK_END
	hdr.add_child(right)

	right.add_child(UIFactory.make_label("STATUS", 10, Palette.TEXT_MUTE, 0.3))

	status_label = UIFactory.make_status_pill("READY")
	right.add_child(status_label)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.add_child(hdr)
	v.add_child(UIFactory.make_hairline())
	return v


func _build_waveform() -> Control:
	var panel := PanelContainer.new()
	UIFactory.apply_panel_style(panel, Palette.INSET, Palette.BORDER)
	panel.custom_minimum_size = Palette.WAVEFORM_PANEL_MIN

	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(holder)

	waveform = WaveformDisplay.new()
	waveform.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(waveform)

	waveform_info_left = UIFactory.make_label("WAVEFORM", 10, Palette.TEXT_MUTE, 0.25)
	waveform_info_left.position = Palette.WAVEFORM_INFO_LEFT_POS
	waveform_info_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(waveform_info_left)

	waveform_info_right = UIFactory.make_label("", 10, Palette.TEXT_MUTE, 0.25)
	waveform_info_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	waveform_info_right.position = Palette.WAVEFORM_INFO_RIGHT_POS
	waveform_info_right.size = Palette.WAVEFORM_INFO_RIGHT_SIZE
	waveform_info_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	waveform_info_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(waveform_info_right)

	return panel


# ── Left column ────────────────────────────────────────────────────

func _build_left_column() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 3.0
	v.add_theme_constant_override("separation", 8)

	channel_tabs_container = HBoxContainer.new()
	channel_tabs_container.add_theme_constant_override("separation", 4)
	v.add_child(channel_tabs_container)

	# 2-column grid replaces the prior ScrollContainer + VBox. Five rows of
	# paired modules fit the viewport at default resolution.
	modules_container = GridContainer.new()
	modules_container.columns = 2
	modules_container.add_theme_constant_override("h_separation", 6)
	modules_container.add_theme_constant_override("v_separation", 4)
	modules_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modules_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(modules_container)

	var by_key: Dictionary = {}
	for mod in SoundData.MODULES:
		by_key[mod.key] = mod
	for pair in MODULE_ROW_PAIRS:
		for k in pair:
			modules_container.add_child(_make_module_panel(by_key[k]))

	return v


func _make_module_panel(mod: Dictionary) -> Control:
	var panel := PanelContainer.new()
	UIFactory.apply_panel_style(panel, Palette.PANEL, Palette.BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	module_panels[mod.key] = panel

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	v.add_child(UIFactory.wrap_padded(header, 6, 6, 3, 3))

	v.add_child(UIFactory.make_hairline())

	var enable_key: String = mod.enable_key
	var is_toggleable: bool = enable_key != ""

	if is_toggleable:
		var check := UIFactory.make_check_button("", false)
		check.custom_minimum_size = Palette.MODULE_CHECK_SIZE
		check.toggled.connect(_host._on_module_toggled.bind(enable_key))
		header.add_child(check)
		module_check_buttons[enable_key] = check
	else:
		header.add_child(UIFactory.make_module_indicator())

	var title := UIFactory.make_label(mod.title, Palette.FONT_LABEL, Palette.TEXT, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	if is_toggleable:
		var lock_btn := UIFactory.make_lock_button()
		lock_btn.pressed.connect(_host._on_module_lock_pressed.bind(mod))
		header.add_child(lock_btn)
		module_lock_buttons[enable_key] = lock_btn

	# Body: horizontal row of knob boxes — one per param.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UIFactory.wrap_padded(body, 4, 4, 3, 4))

	for pk in mod.params:
		var box_dict: Dictionary = UIFactory.make_knob_box(pk)
		body.add_child(box_dict.box)
		var knob: Knob = box_dict.knob
		knob.value_changed.connect(_host._on_param_value_changed.bind(pk))
		knob.reset_requested.connect(_host._on_param_reset.bind(pk))
		knob.lock_toggled.connect(_host._on_param_lock_toggled.bind(pk))
		# Clicking the label resets to default — preserves the prior UX
		# even though the inline lock button is gone.
		box_dict.label_btn.pressed.connect(_host._on_param_reset.bind(pk))
		param_knobs[pk] = knob
		param_value_labels[pk] = box_dict.value_label

	return panel


# ── Right column ───────────────────────────────────────────────────
# No outer ScrollContainer — the column is sized to fit at 1280×900 with
# the bin getting whatever vertical space remains.
func _build_right_column() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 2.0
	v.custom_minimum_size = Palette.COLUMN_LEFT_MIN

	v.add_child(_build_master_panel())
	v.add_child(_build_presets_panel())
	v.add_child(_build_actions_panel())
	v.add_child(_build_sound_string_panel())

	# Bin gets the remaining vertical real estate — its internal ScrollContainer
	# is the only scrollbar in the entire app, and it only kicks in when the
	# bin actually overflows.
	var bin_panel := _build_bin_panel()
	bin_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(bin_panel)

	return v


func _build_master_panel() -> Control:
	var panel := UIFactory.make_section_panel("MASTER")
	var body: VBoxContainer = panel.get_meta("body")

	body.add_child(UIFactory.make_label("MIX", 9, Palette.TEXT_DIM, 0.3))

	mix_container = VBoxContainer.new()
	mix_container.add_theme_constant_override("separation", 4)
	body.add_child(mix_container)

	body.add_child(UIFactory.wrap_padded(UIFactory.make_hairline(), 0, 0, 6, 0))
	body.add_child(UIFactory.make_label("OUTPUT", 9, Palette.TEXT_DIM, 0.3))

	# Output knobs in one horizontal row.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(row)

	var mv := UIFactory.make_master_knob_box("VOLUME", 0.0, 1.0, 0.01)
	master_v_knob = mv["knob"]
	master_v_label = mv["value_label"]
	master_v_knob.value_changed.connect(_host._on_master_changed.bind("masterVolume"))
	mv["label_btn"].pressed.connect(_host._on_master_reset.bind("masterVolume"))
	master_v_knob.reset_requested.connect(_host._on_master_reset.bind("masterVolume"))
	row.add_child(mv["box"])

	var rm := UIFactory.make_master_knob_box("VERB MIX", 0.0, 1.0, 0.01)
	verb_mix_knob = rm["knob"]
	verb_mix_label = rm["value_label"]
	verb_mix_knob.value_changed.connect(_host._on_master_changed.bind("reverbMix"))
	rm["label_btn"].pressed.connect(_host._on_master_reset.bind("reverbMix"))
	verb_mix_knob.reset_requested.connect(_host._on_master_reset.bind("reverbMix"))
	row.add_child(rm["box"])

	var rs := UIFactory.make_master_knob_box("VERB SIZE", 0.0, 1.0, 0.01)
	verb_size_knob = rs["knob"]
	verb_size_label = rs["value_label"]
	verb_size_knob.value_changed.connect(_host._on_master_changed.bind("reverbSize"))
	rs["label_btn"].pressed.connect(_host._on_master_reset.bind("reverbSize"))
	verb_size_knob.reset_requested.connect(_host._on_master_reset.bind("reverbSize"))
	row.add_child(rs["box"])

	return panel


func _build_presets_panel() -> Control:
	var panel := UIFactory.make_section_panel("PRESETS")
	var body: VBoxContainer = panel.get_meta("body")
	preset_buttons_root = VBoxContainer.new()
	preset_buttons_root.add_theme_constant_override("separation", 4)
	body.add_child(preset_buttons_root)
	refresh_preset_panel()
	return panel


# Rebuild the tab strip and every group's grid. Called once on init and
# again after a user preset is saved (so the USER tab appears or grows
# in place). Active-tab state is preserved across rebuilds.
func refresh_preset_panel() -> void:
	if preset_buttons_root == null:
		return
	for c in preset_buttons_root.get_children():
		c.queue_free()
	preset_tab_buttons.clear()
	preset_grids.clear()

	# Discover groups dynamically in REGISTRY-declaration order so new
	# categories appear automatically.
	var groups: Array = []
	for entry in Presets.REGISTRY:
		if not (entry.group in groups):
			groups.append(entry.group)

	var user_entries: Array = _build_user_preset_entries()
	if not user_entries.is_empty():
		groups.append("USER")

	if groups.is_empty():
		return

	# Default to first group on first run; preserve user's selection across
	# rebuilds when possible.
	if preset_active_group == "" or not (preset_active_group in groups):
		preset_active_group = groups[0]

	# Tab-button row.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_buttons_root.add_child(tabs)

	for g in groups:
		var tab_btn := UIFactory.make_action_button(g)
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.pressed.connect(_on_preset_tab_pressed.bind(g))
		tabs.add_child(tab_btn)
		preset_tab_buttons[g] = tab_btn

	# One grid per group; only the active group's grid is visible.
	for g in groups:
		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preset_buttons_root.add_child(grid)
		preset_grids[g] = grid

		var entries: Array
		if g == "USER":
			entries = user_entries
		else:
			entries = []
			for entry in Presets.REGISTRY:
				if entry.group == g:
					entries.append(entry)

		for entry in entries:
			var btn := UIFactory.make_action_button(entry.name)
			btn.pressed.connect(_host._on_preset_pressed.bind(entry))
			# Hover preview: audit on enter, cancel on exit.
			btn.mouse_entered.connect(_host._on_preset_button_hovered.bind(entry))
			btn.mouse_exited.connect(_host._on_preset_button_unhovered)
			grid.add_child(btn)

		grid.visible = (g == preset_active_group)

	_restyle_preset_tabs()


func _on_preset_tab_pressed(group_name: String) -> void:
	preset_active_group = group_name
	for g in preset_grids.keys():
		preset_grids[g].visible = (g == group_name)
	_restyle_preset_tabs()


func _restyle_preset_tabs() -> void:
	for g in preset_tab_buttons.keys():
		UIFactory.apply_preset_tab_style(preset_tab_buttons[g], g == preset_active_group)


# Build registry-style entries for user-saved presets. They carry an
# extra "string" field (the v7 sound string) so the controller can tell
# them apart from built-ins, plus user_index for delete operations.
func _build_user_preset_entries() -> Array:
	var entries: Array = []
	var loaded: Array = Persistence.load_user_presets()
	for i in loaded.size():
		var item: Dictionary = loaded[i]
		entries.append({
			"name": "★%s" % String(item.get("name", "untitled")),
			"kind": "user",
			"group": "USER",
			"string": String(item.get("string", "")),
			"user_index": i,
		})
	return entries


func _build_actions_panel() -> Control:
	var panel := UIFactory.make_section_panel("ACTIONS")
	var body: VBoxContainer = panel.get_meta("body")

	# Variation-seed row sits above the action buttons. Each preset/GEN
	# click consumes the current value and increments — typing any prior
	# seed back into the SpinBox revives that variant.
	body.add_child(_build_variation_row())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)

	var gen := UIFactory.make_action_button("⚄ GEN", true)
	gen.pressed.connect(_host._on_generate_pressed)
	grid.add_child(gen)

	var play := UIFactory.make_action_button("▶ PLAY")
	play.pressed.connect(_host._on_play_pressed)
	grid.add_child(play)

	var wav := UIFactory.make_action_button("↓ WAV")
	wav.pressed.connect(_host._on_export_pressed)
	grid.add_child(wav)

	# SAVE PRESET writes the current sound string to user_presets.json
	# and re-renders the preset panel so the new ★ entry shows up
	# immediately under the USER section.
	var save_preset := UIFactory.make_action_button("★ SAVE PRESET")
	save_preset.pressed.connect(_host._on_save_preset_pressed)
	grid.add_child(save_preset)

	return panel


# Variation-seed row: small "VAR" label + SpinBox showing the next seed
# to consume + ↻ button to randomise the seed for a fresh batch.
func _build_variation_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var label := UIFactory.make_label("VAR", Palette.FONT_SMALL, Palette.TEXT_DIM, 0.3)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	variation_seed_input = SpinBox.new()
	variation_seed_input.min_value = 0
	variation_seed_input.max_value = 9999
	variation_seed_input.step = 1
	variation_seed_input.value = _state.variation_seed
	variation_seed_input.custom_minimum_size = Palette.VARIATION_SEED_SIZE
	variation_seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variation_seed_input.tooltip_text = "Next random seed. Auto-increments after each preset/GEN. Type any value to revisit that variant."
	variation_seed_input.value_changed.connect(_host._on_variation_seed_changed)
	row.add_child(variation_seed_input)

	var reroll := UIFactory.make_action_button("↻")
	reroll.tooltip_text = "Pick a fresh random seed"
	reroll.custom_minimum_size = Palette.REROLL_BTN_SIZE
	reroll.pressed.connect(_host._on_variation_reroll_pressed)
	row.add_child(reroll)

	return row


func _build_sound_string_panel() -> Control:
	var panel := UIFactory.make_section_panel("SOUND STRING")
	var body: VBoxContainer = panel.get_meta("body")

	sound_string_input = LineEdit.new()
	sound_string_input.placeholder_text = "sfx7:..."
	sound_string_input.add_theme_color_override("font_color", Palette.TEXT)
	sound_string_input.add_theme_color_override("font_placeholder_color", Palette.TEXT_DIM)
	sound_string_input.add_theme_font_size_override("font_size", Palette.FONT_VALUE)
	UIFactory.apply_lineedit_style(sound_string_input)
	body.add_child(sound_string_input)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)

	var copy_btn := UIFactory.make_action_button("⧉ COPY")
	copy_btn.pressed.connect(_host._on_copy_pressed)
	grid.add_child(copy_btn)

	var paste_btn := UIFactory.make_action_button("⏎ PASTE")
	paste_btn.pressed.connect(_host._on_paste_pressed)
	grid.add_child(paste_btn)

	var load_btn := UIFactory.make_action_button("LOAD")
	load_btn.pressed.connect(_host._on_load_string_pressed)
	grid.add_child(load_btn)

	return panel


func _build_bin_panel() -> Control:
	var panel := UIFactory.make_section_panel("BIN [0]", true)
	var body: VBoxContainer = panel.get_meta("body")
	bin_count_label = panel.get_meta("title")

	var save_btn := UIFactory.make_action_button("+ SAVE")
	save_btn.pressed.connect(_host._on_save_to_bin_pressed)
	panel.get_meta("title_row").add_child(save_btn)

	# Search box: substring filter on entry names. Updates the rendered
	# list live as the user types — no Enter required.
	bin_search_input = LineEdit.new()
	bin_search_input.placeholder_text = "search…"
	bin_search_input.add_theme_color_override("font_color", Palette.TEXT)
	bin_search_input.add_theme_color_override("font_placeholder_color", Palette.TEXT_DIM)
	bin_search_input.add_theme_font_size_override("font_size", Palette.FONT_VALUE)
	bin_search_input.clear_button_enabled = true
	UIFactory.apply_lineedit_style(bin_search_input)
	bin_search_input.text_changed.connect(_on_bin_search_changed)
	body.add_child(bin_search_input)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	bin_container = VBoxContainer.new()
	bin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bin_container)

	return panel


func _on_bin_search_changed(text: String) -> void:
	bin_search_query = text.strip_edges().to_lower()
	refresh_bin_list()


func _build_footer() -> Control:
	var foot := UIFactory.make_label(
		"UP TO 4 CHANNELS · MIX & REVERB IN MASTER · LOCK PARAMS OR MODULES TO HOLD THEM THROUGH GEN · BIN PERSISTS",
		10, Palette.TEXT_DIM, 0.3
	)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(UIFactory.make_hairline())
	v.add_child(foot)
	return v


# ── Refresh helpers ────────────────────────────────────────────────

func refresh_waveform_info() -> void:
	if waveform_info_left == null:
		return
	var ms: int = int(round(float(_state.samples.size()) / float(SoundData.SAMPLE_RATE) * 1000.0))
	waveform_info_left.text = "WAVEFORM · %d SMP · %dms · %dCH" % [_state.samples.size(), ms, _state.sound.channels.size()]
	var ch: Dictionary = _state.sound.channels[_state.active_channel]
	var mode_idx: int = clampi(int(ch.mode), 0, SoundData.MODES.size() - 1)
	waveform_info_right.text = "CH%d · %s @ %dHz" % [_state.active_channel + 1, SoundData.MODES[mode_idx], int(round(float(ch.pitch)))]


func refresh_channel_tabs() -> void:
	for c in channel_tabs_container.get_children():
		c.queue_free()

	for i in _state.sound.channels.size():
		var ch_dict: Dictionary = _state.sound.channels[i]
		var btn := UIFactory.make_channel_tab(
			"CH %d" % (i + 1),
			i == _state.active_channel,
			bool(ch_dict.get("soloed", false)),
			bool(ch_dict.get("muted", false)),
		)
		btn.pressed.connect(_host._on_channel_tab_pressed.bind(i))
		channel_tabs_container.add_child(btn)

	if _state.sound.channels.size() < SoundData.MAX_CHANNELS:
		var add_btn := UIFactory.make_channel_add_btn()
		add_btn.pressed.connect(_host._on_add_channel_pressed)
		channel_tabs_container.add_child(add_btn)


func refresh_mix_rows() -> void:
	for c in mix_container.get_children():
		c.queue_free()

	for i in _state.sound.channels.size():
		mix_container.add_child(_make_mix_row(i))


func _make_mix_row(i: int) -> Control:
	var ch_dict: Dictionary = _state.sound.channels[i]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var label_btn := UIFactory.make_mix_label_btn(i, i == _state.active_channel)
	label_btn.pressed.connect(_host._on_channel_tab_pressed.bind(i))
	row.add_child(label_btn)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = float(ch_dict.get("level", 1.0))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_host._on_channel_level_changed.bind(i))
	row.add_child(slider)

	var muted: bool = bool(ch_dict.get("muted", false))
	var mute_btn := UIFactory.make_mini_btn("M", muted)
	mute_btn.tooltip_text = "Unmute" if muted else "Mute"
	mute_btn.pressed.connect(_host._on_channel_mute_pressed.bind(i))
	row.add_child(mute_btn)

	var soloed: bool = bool(ch_dict.get("soloed", false))
	var solo_btn := UIFactory.make_mini_btn("S", soloed)
	solo_btn.tooltip_text = "Unsolo" if soloed else "Solo"
	solo_btn.pressed.connect(_host._on_channel_solo_pressed.bind(i))
	row.add_child(solo_btn)

	if _state.sound.channels.size() > 1:
		var del_btn := UIFactory.make_mini_btn("×", false)
		del_btn.tooltip_text = "Remove channel"
		del_btn.pressed.connect(_host._on_channel_delete_pressed.bind(i))
		row.add_child(del_btn)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Palette.MINI_BTN_SIZE
		row.add_child(spacer)

	return row


# Update knob values + lock states for the active channel WITHOUT
# triggering signal emission cascades (which would cause feedback loops).
func refresh_module_values() -> void:
	var ch_dict: Dictionary = _state.sound.channels[_state.active_channel]
	var ch_locks: Dictionary = _state.active_channel_locks()

	for key in param_knobs.keys():
		var knob: Knob = param_knobs[key]
		var v: float = float(ch_dict.get(key, 0.0))
		# set_value_no_signal avoids the round-trip back into _on_param_value_changed.
		knob.set_value_no_signal(v)
		var label: Label = param_value_labels[key]
		label.text = SoundData.format_value(key, v)
		knob.set_locked(bool(ch_locks.get(key, false)))

	for mod in SoundData.MODULES:
		var ek: String = mod.enable_key
		if ek == "":
			continue
		var enabled: bool = bool(ch_dict.get(ek, false))
		var check_btn: Button = module_check_buttons[ek]
		check_btn.set_pressed_no_signal(enabled)
		UIFactory.apply_check_style(check_btn, enabled)
		var lock_btn: Button = module_lock_buttons[ek]
		UIFactory.apply_button_style(lock_btn, bool(ch_locks.get(ek, false)))

		# Dim the panel when the module is disabled.
		var panel: Control = module_panels[mod.key]
		panel.modulate = Palette.MODULATE_DIM if (mod.enable_key != "" and not enabled) else Color.WHITE


func refresh_master_values() -> void:
	if master_v_knob == null:
		return
	master_v_knob.set_value_no_signal(float(_state.sound.master.masterVolume))
	master_v_label.text = "%.2f" % float(_state.sound.master.masterVolume)
	verb_mix_knob.set_value_no_signal(float(_state.sound.master.reverbMix))
	verb_mix_label.text = "%.2f" % float(_state.sound.master.reverbMix)
	verb_size_knob.set_value_no_signal(float(_state.sound.master.reverbSize))
	verb_size_label.text = "%.2f" % float(_state.sound.master.reverbSize)


func refresh_bin_list() -> void:
	for c in bin_container.get_children():
		c.queue_free()

	# Header reflects total stored, not filtered, so the user always
	# knows how many entries the bin actually holds.
	bin_count_label.text = "BIN [%d]" % _state.bin.size()

	if _state.bin.is_empty():
		var empty := UIFactory.make_label("EMPTY · SAVE A SOUND", 11, Palette.TEXT_DIM, 0.3)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bin_container.add_child(UIFactory.wrap_padded(empty, 0, 0, 24, 24))
		return

	# Apply the search filter. Substring match on lowercased name; empty
	# query passes everything through.
	var visible: Array = _state.bin
	if not bin_search_query.is_empty():
		visible = _state.bin.filter(func(e): return String(e.get("name", "")).to_lower().contains(bin_search_query))

	if visible.is_empty():
		var miss := UIFactory.make_label("NO MATCH · CLEAR SEARCH", 11, Palette.TEXT_DIM, 0.3)
		miss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		miss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bin_container.add_child(UIFactory.wrap_padded(miss, 0, 0, 24, 24))
		return

	for entry in visible:
		var entry_id: int = int(entry.get("id", 0))
		var built: Dictionary = UIFactory.make_bin_row(entry.get("name", "—"))
		built.play_btn.pressed.connect(_host._on_bin_load_pressed.bind(entry_id))
		built.del_btn.pressed.connect(_host._on_bin_delete_pressed.bind(entry_id))
		bin_container.add_child(built.container)


# ── Status flash ───────────────────────────────────────────────────

func flash_status(msg: String) -> void:
	status_label.text = msg
	# Filled-pill state when transient, hollow when "READY".
	UIFactory.apply_panel_style(status_label, Palette.ACCENT, Palette.ACCENT)
	status_label.add_theme_color_override("font_color", Palette.BG)
	_status_token += 1
	var token := _status_token
	_host.get_tree().create_timer(Palette.STATUS_HOLD_SEC).timeout.connect(func():
		if token != _status_token:
			return
		status_label.text = "READY"
		UIFactory.apply_panel_style(status_label, Palette.BG, Palette.ACCENT)
		status_label.add_theme_color_override("font_color", Palette.ACCENT)
	)


# ── Save-preset dialog (lazy) ──────────────────────────────────────

func ensure_save_preset_dialog() -> void:
	if _save_preset_dialog != null:
		return
	_save_preset_dialog = ConfirmationDialog.new()
	_save_preset_dialog.title = "Save as user preset"
	_save_preset_dialog.size = Palette.PRESET_NAME_DIALOG_SIZE
	_save_preset_dialog.confirmed.connect(_host._on_save_preset_confirmed)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Palette.PRESET_NAME_BODY_MIN
	_save_preset_dialog.add_child(v)

	v.add_child(UIFactory.make_label("Name:", Palette.FONT_VALUE, Palette.TEXT))
	_save_preset_name_input = LineEdit.new()
	_save_preset_name_input.placeholder_text = "MY_LASER"
	_save_preset_name_input.add_theme_color_override("font_color", Palette.TEXT)
	_save_preset_name_input.add_theme_font_size_override("font_size", Palette.FONT_VALUE)
	UIFactory.apply_lineedit_style(_save_preset_name_input)
	v.add_child(_save_preset_name_input)

	_host.add_child(_save_preset_dialog)


func open_save_preset_dialog(default_name: String) -> void:
	ensure_save_preset_dialog()
	_save_preset_name_input.text = default_name
	_save_preset_dialog.popup_centered()
	_save_preset_name_input.grab_focus()
	_save_preset_name_input.select_all()


func read_save_preset_name() -> String:
	if _save_preset_name_input == null:
		return ""
	return _save_preset_name_input.text.strip_edges()
