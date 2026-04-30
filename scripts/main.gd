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

# Theme tokens (colour palette, font sizes, status-pill timing) live in
# scripts/palette.gd — referenced as Palette.BG, Palette.ACCENT, etc.
# Bin disk persistence lives in scripts/bin_store.gd (BinStore class).

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
# Coalesces rapid slider drags into a single render. Started/restarted
# by _request_re_render(); cancelled by any direct _re_render() call.
var render_timer: Timer

# Hover-preview infra (2B-2). A second AudioStreamPlayer auditions a
# preset against a CLEAN default sound on hover so the user hears just
# the preset's character. Debounced so brushing past doesn't fire.
var hover_player: AudioStreamPlayer
var hover_timer: Timer
var hover_pending_entry: Dictionary = {}

# Save-preset dialog (2B-4). Lazily built on first use.
var save_preset_dialog: ConfirmationDialog
var save_preset_name_input: LineEdit

# ── Undo / redo ────────────────────────────────────────────────────
# Snapshots are taken before discrete state replacements (GEN, preset,
# paste, bin-load) — NOT before slider drags, which would flood the stack.
const UNDO_MAX := 50
var undo_stack: Array = []
var redo_stack: Array = []

# ── Variation seed (2B-1) ──────────────────────────────────────────
# Auto-incrementing seed applied before every preset / GEN. Each click
# yields a fresh take (current behavior preserved) AND every result is
# reproducible: type any prior value into the SpinBox to get that
# variant back. Shown next to the GEN button.
var variation_seed: int = 0
var variation_seed_input: SpinBox

# ── Preset panel state ─────────────────────────────────────────────
# Tab-strip state: one group visible at a time. Persists across
# _refresh_preset_panel calls so saving a user preset doesn't yank the
# user away from whatever group they were browsing.
var preset_active_group: String = ""
var preset_tab_buttons: Dictionary = {}  # group name -> Button (re-styled on switch)
var preset_grids: Dictionary = {}        # group name -> GridContainer (visibility toggled)

# ── Bin search (2B-5) ──────────────────────────────────────────────
# Substring filter applied to bin-entry names. Lowercased on input.
var bin_search_input: LineEdit
var bin_search_query: String = ""

var status_label: Label
var waveform: WaveformDisplay
var waveform_info_left: Label
var waveform_info_right: Label

# ── Onomatopoeia (Phase 2) ─────────────────────────────────────────
# Header LineEdit + apply button. Type a word, get a sound — single
# channel, params merged onto the active channel respecting locks.
var onomatopoeia_input: LineEdit

var channel_tabs_container: HBoxContainer
var modules_container: GridContainer
var mix_container: VBoxContainer
var master_v_knob: Knob
var master_v_label: Label
var verb_mix_knob: Knob
var verb_mix_label: Label
var verb_size_knob: Knob
var verb_size_label: Label
var sound_string_input: LineEdit
var bin_container: VBoxContainer
var bin_count_label: Label

# Cached references per param key — keyed by param name string.
# Knob extends Range, so it shares the set_value_no_signal API with the
# previous HSlider implementation. Lock state lives on the knob itself
# (knob.locked, toggled via alt-click) — there's no separate lock button.
var param_knobs: Dictionary = {}        # key -> Knob
var param_value_labels: Dictionary = {} # key -> Label
var module_panels: Dictionary = {}      # mod_key -> PanelContainer (for dim)
var module_check_buttons: Dictionary = {} # enable_key -> Button (acts as checkbox)
var module_lock_buttons: Dictionary = {}  # enable_key -> Button
var preset_buttons_root: VBoxContainer


# ── Lifecycle ──────────────────────────────────────────────────────
func _ready() -> void:
	sound = SoundData.default_sound()

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	# ~30 ms debounce: catches the tail of a slider drag without lag.
	render_timer = Timer.new()
	render_timer.wait_time = 0.03
	render_timer.one_shot = true
	render_timer.timeout.connect(_re_render)
	add_child(render_timer)

	# Dedicated hover-preview player so audits don't interrupt the main
	# AudioStreamPlayer (e.g. if user is mid-preview of their own sound).
	# Slightly attenuated so previews feel obviously "secondary".
	hover_player = AudioStreamPlayer.new()
	hover_player.volume_db = -3.0
	add_child(hover_player)

	# 180 ms debounce: long enough that brushing past a button doesn't
	# fire, short enough that intentional hovers feel responsive.
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.18
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)

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
	bg.color = Palette.BG
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
	onomatopoeia_input.custom_minimum_size = Vector2(240, 28)
	onomatopoeia_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.apply_lineedit_style(onomatopoeia_input)
	onomatopoeia_input.text_submitted.connect(_on_onomatopoeia_submitted)
	ono_box.add_child(onomatopoeia_input)

	var apply_btn := UIFactory.make_action_button("→", true)
	apply_btn.tooltip_text = "Convert text to sound parameters"
	apply_btn.custom_minimum_size = Vector2(36, 28)
	apply_btn.pressed.connect(_on_onomatopoeia_apply_pressed)
	ono_box.add_child(apply_btn)

	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_vertical = Control.SIZE_SHRINK_END
	hdr.add_child(right)

	right.add_child(UIFactory.make_label("STATUS", 10, Palette.TEXT_MUTE, 0.3))

	status_label = Label.new()
	status_label.text = "READY"
	status_label.custom_minimum_size = Vector2(120, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Palette.ACCENT)
	status_label.add_theme_font_size_override("font_size", Palette.FONT_LABEL)
	# Letter-spacing is currently a no-op (custom font not wired up); kept as
	# a 0-arg call site so re-enabling it is a one-line change.
	UIFactory.apply_panel_style(status_label, Palette.BG, Palette.ACCENT)
	right.add_child(status_label)

	# Bottom border
	var border_below := ColorRect.new()
	border_below.color = Palette.BORDER
	border_below.custom_minimum_size = Vector2(0, 1)
	border_below.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.add_child(hdr)
	v.add_child(border_below)
	return v


func _build_waveform() -> Control:
	var panel := PanelContainer.new()
	UIFactory.apply_panel_style(panel, Palette.INSET, Palette.BORDER)
	panel.custom_minimum_size = Vector2(0, 120)

	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(holder)

	waveform = WaveformDisplay.new()
	waveform.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(waveform)

	waveform_info_left = UIFactory.make_label("WAVEFORM", 10, Palette.TEXT_MUTE, 0.25)
	waveform_info_left.position = Vector2(10, 6)
	waveform_info_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(waveform_info_left)

	waveform_info_right = UIFactory.make_label("", 10, Palette.TEXT_MUTE, 0.25)
	waveform_info_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	waveform_info_right.position = Vector2(-260, 6)
	waveform_info_right.size = Vector2(250, 16)
	waveform_info_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	waveform_info_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(waveform_info_right)

	return panel


# ── Left column: channel tabs + module list ────────────────────────

# Module pairing for the 2-column grid. Five rows × two cols puts every
# module on one screen at 1280×900 with no scrolling. Order chosen so
# closely-related modules sit side-by-side (filter/pitch env, vib/trem).
const MODULE_ROW_PAIRS := [
	["source",   "amp"],
	["filter",   "pitchEnv"],
	["vibrato",  "tremolo"],
	["arpeggio", "delay"],
	["drive",    "crush"],
]

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

	# Border under header
	var hdr_border := ColorRect.new()
	hdr_border.color = Palette.BORDER
	hdr_border.custom_minimum_size = Vector2(0, 1)
	hdr_border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(hdr_border)

	var enable_key: String = mod.enable_key
	var is_toggleable: bool = enable_key != ""

	if is_toggleable:
		var check := UIFactory.make_check_button("", false)
		check.custom_minimum_size = Vector2(18, 18)
		check.toggled.connect(_on_module_toggled.bind(enable_key))
		header.add_child(check)
		module_check_buttons[enable_key] = check
	else:
		# Always-on indicator
		var indicator := ColorRect.new()
		indicator.color = Color("#332a1f")
		indicator.custom_minimum_size = Vector2(18, 18)
		var inner := ColorRect.new()
		inner.color = Palette.ACCENT
		inner.set_anchors_preset(Control.PRESET_CENTER)
		inner.position = Vector2(6, 6)
		inner.size = Vector2(6, 6)
		indicator.add_child(inner)
		header.add_child(indicator)

	var title := UIFactory.make_label(mod.title, Palette.FONT_LABEL, Palette.TEXT, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	if is_toggleable:
		var lock_btn := UIFactory.make_lock_button()
		lock_btn.pressed.connect(_on_module_lock_pressed.bind(mod))
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
		knob.value_changed.connect(_on_param_value_changed.bind(pk))
		knob.reset_requested.connect(_on_param_reset.bind(pk))
		knob.lock_toggled.connect(_on_param_lock_toggled.bind(pk))
		# Clicking the label resets to default — preserves the prior UX
		# even though the inline lock button is gone.
		box_dict.label_btn.pressed.connect(_on_param_reset.bind(pk))
		param_knobs[pk] = knob
		param_value_labels[pk] = box_dict.value_label

	return panel


# ── Right column: master, presets, actions, sound string, bin ──────
# No outer ScrollContainer — the column is sized to fit at 1280×900 with
# the bin getting whatever vertical space remains.
func _build_right_column() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 2.0
	v.custom_minimum_size = Vector2(420, 0)

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

	var output_border := ColorRect.new()
	output_border.color = Palette.BORDER
	output_border.custom_minimum_size = Vector2(0, 1)
	output_border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(UIFactory.wrap_padded(output_border, 0, 0, 6, 0))
	body.add_child(UIFactory.make_label("OUTPUT", 9, Palette.TEXT_DIM, 0.3))

	# Output knobs in one horizontal row.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(row)

	var mv := UIFactory.make_master_knob_box("VOLUME", 0.0, 1.0, 0.01)
	master_v_knob = mv["knob"]
	master_v_label = mv["value_label"]
	master_v_knob.value_changed.connect(_on_master_changed.bind("masterVolume"))
	mv["label_btn"].pressed.connect(_on_master_reset.bind("masterVolume"))
	master_v_knob.reset_requested.connect(_on_master_reset.bind("masterVolume"))
	row.add_child(mv["box"])

	var rm := UIFactory.make_master_knob_box("VERB MIX", 0.0, 1.0, 0.01)
	verb_mix_knob = rm["knob"]
	verb_mix_label = rm["value_label"]
	verb_mix_knob.value_changed.connect(_on_master_changed.bind("reverbMix"))
	rm["label_btn"].pressed.connect(_on_master_reset.bind("reverbMix"))
	verb_mix_knob.reset_requested.connect(_on_master_reset.bind("reverbMix"))
	row.add_child(rm["box"])

	var rs := UIFactory.make_master_knob_box("VERB SIZE", 0.0, 1.0, 0.01)
	verb_size_knob = rs["knob"]
	verb_size_label = rs["value_label"]
	verb_size_knob.value_changed.connect(_on_master_changed.bind("reverbSize"))
	rs["label_btn"].pressed.connect(_on_master_reset.bind("reverbSize"))
	verb_size_knob.reset_requested.connect(_on_master_reset.bind("reverbSize"))
	row.add_child(rs["box"])

	return panel


func _build_presets_panel() -> Control:
	var panel := UIFactory.make_section_panel("PRESETS")
	var body: VBoxContainer = panel.get_meta("body")
	preset_buttons_root = VBoxContainer.new()
	preset_buttons_root.add_theme_constant_override("separation", 4)
	body.add_child(preset_buttons_root)
	_refresh_preset_panel()
	return panel


# Rebuild the tab strip and every group's grid. Called once on init and
# again after a user preset is saved (so the USER tab appears or grows
# in place). Active-tab state is preserved across rebuilds.
func _refresh_preset_panel() -> void:
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

	# One grid per group; only the active group's grid is visible. Container
	# layout skips invisible children, so the panel sizes to whichever group
	# is showing.
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
			btn.pressed.connect(_on_preset_pressed.bind(entry))
			# Hover preview (2B-2): audit on enter, cancel on exit.
			btn.mouse_entered.connect(_on_preset_button_hovered.bind(entry))
			btn.mouse_exited.connect(_on_preset_button_unhovered)
			grid.add_child(btn)

		grid.visible = (g == preset_active_group)

	_restyle_preset_tabs()


func _on_preset_tab_pressed(group_name: String) -> void:
	preset_active_group = group_name
	for g in preset_grids.keys():
		preset_grids[g].visible = (g == group_name)
	_restyle_preset_tabs()


# Active tab gets the filled accent stylebox; inactives stay hollow. Reuses
# make_stylebox so it matches the rest of the app's button language.
func _restyle_preset_tabs() -> void:
	for g in preset_tab_buttons.keys():
		var btn: Button = preset_tab_buttons[g]
		var active: bool = (g == preset_active_group)
		var bg: Color = Palette.ACCENT if active else Color(0, 0, 0, 0)
		var fg: Color = Palette.BG if active else Palette.TEXT_MUTE
		var border: Color = Palette.ACCENT if active else Palette.BORDER_HI
		var normal := UIFactory.make_stylebox(bg, border)
		var hover := UIFactory.make_stylebox(Palette.ACCENT, Palette.ACCENT)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", normal)
		btn.add_theme_stylebox_override("focus", normal)
		btn.add_theme_color_override("font_color", fg)
		btn.add_theme_color_override("font_hover_color", Palette.BG)


# Build registry-style entries for user-saved presets. They carry an
# extra "string" field (the v7 sound string) so _on_preset_pressed can
# tell them apart from built-ins, plus user_index for delete operations.
func _build_user_preset_entries() -> Array:
	var entries: Array = []
	var loaded: Array = UserPresets.load_all()
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


# ── Hover preview (2B-2) ───────────────────────────────────────────

func _on_preset_button_hovered(entry: Dictionary) -> void:
	hover_pending_entry = entry
	hover_timer.start()


func _on_preset_button_unhovered() -> void:
	hover_pending_entry = {}
	hover_timer.stop()


func _on_hover_timer_timeout() -> void:
	if hover_pending_entry.is_empty():
		return
	var s = _render_preset_preview(hover_pending_entry)
	if s == null:
		return
	var buf: PackedFloat32Array = Synth.render_sound(s)
	if buf.is_empty():
		return
	hover_player.stop()
	hover_player.stream = Playback.build_stream(buf)
	hover_player.play()


# Render a preset against a clean default channel so the user auditions
# JUST the preset's character — not their current sound mutated by it.
# Sound presets and user presets replace the entire sound; patches merge
# onto a fresh default channel.
func _render_preset_preview(entry: Dictionary):
	if entry.get("kind", "") == "user":
		return SoundData.sound_from_string(String(entry.get("string", "")))
	if entry.kind == "sound":
		return Presets.run_preset(entry, {}, {})
	var base: Dictionary = {
		"channels": [SoundData.clone_params()],
		"master": SoundData.clone_master(),
	}
	var patch = Presets.run_preset(entry, base.channels[0], {})
	if patch == null:
		return null
	base.channels[0].merge(patch, true)
	return base


# ── Variation seed (2B-1) ──────────────────────────────────────────

# Apply seed before any preset/GEN so the result is reproducible, then
# auto-increment so the next click yields a fresh take by default. To
# revisit a previous variant, the user types its seed back into the
# SpinBox before clicking.
func _consume_variation_seed() -> void:
	seed(variation_seed)
	variation_seed = (variation_seed + 1) % 10000
	if variation_seed_input:
		variation_seed_input.set_value_no_signal(variation_seed)


func _on_variation_seed_changed(value: float) -> void:
	variation_seed = int(value)


func _on_variation_reroll_pressed() -> void:
	variation_seed = randi() % 10000
	if variation_seed_input:
		variation_seed_input.set_value_no_signal(variation_seed)
	_flash_status("VAR %d" % variation_seed)


# ── Save-as-preset dialog (2B-4) ───────────────────────────────────

func _ensure_save_preset_dialog() -> void:
	if save_preset_dialog != null:
		return
	save_preset_dialog = ConfirmationDialog.new()
	save_preset_dialog.title = "Save as user preset"
	save_preset_dialog.size = Vector2i(420, 140)
	save_preset_dialog.confirmed.connect(_on_save_preset_confirmed)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(380, 0)
	save_preset_dialog.add_child(v)

	v.add_child(UIFactory.make_label("Name:", Palette.FONT_VALUE, Palette.TEXT))
	save_preset_name_input = LineEdit.new()
	save_preset_name_input.placeholder_text = "MY_LASER"
	save_preset_name_input.add_theme_color_override("font_color", Palette.TEXT)
	save_preset_name_input.add_theme_font_size_override("font_size", Palette.FONT_VALUE)
	UIFactory.apply_lineedit_style(save_preset_name_input)
	v.add_child(save_preset_name_input)

	add_child(save_preset_dialog)


func _on_save_preset_pressed() -> void:
	_ensure_save_preset_dialog()
	save_preset_name_input.text = "preset_%d" % (UserPresets.load_all().size() + 1)
	save_preset_dialog.popup_centered()
	save_preset_name_input.grab_focus()
	save_preset_name_input.select_all()


func _on_save_preset_confirmed() -> void:
	var name: String = save_preset_name_input.text.strip_edges()
	if name.is_empty():
		_flash_status("EMPTY NAME")
		return
	UserPresets.add(name, sound_string)
	_refresh_preset_panel()
	_flash_status("SAVED ★")


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
	gen.pressed.connect(_on_generate_pressed)
	grid.add_child(gen)

	var play := UIFactory.make_action_button("▶ PLAY")
	play.pressed.connect(_on_play_pressed)
	grid.add_child(play)

	var wav := UIFactory.make_action_button("↓ WAV")
	wav.pressed.connect(_on_export_pressed)
	grid.add_child(wav)

	# SAVE PRESET writes the current sound string to user_presets.json
	# and re-renders the preset panel so the new ★ entry shows up
	# immediately under the USER section.
	var save_preset := UIFactory.make_action_button("★ SAVE PRESET")
	save_preset.pressed.connect(_on_save_preset_pressed)
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
	variation_seed_input.value = variation_seed
	variation_seed_input.custom_minimum_size = Vector2(82, 22)
	variation_seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variation_seed_input.tooltip_text = "Next random seed. Auto-increments after each preset/GEN. Type any value to revisit that variant."
	variation_seed_input.value_changed.connect(_on_variation_seed_changed)
	row.add_child(variation_seed_input)

	var reroll := UIFactory.make_action_button("↻")
	reroll.tooltip_text = "Pick a fresh random seed"
	reroll.custom_minimum_size = Vector2(28, 22)
	reroll.pressed.connect(_on_variation_reroll_pressed)
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
	copy_btn.pressed.connect(_on_copy_pressed)
	grid.add_child(copy_btn)

	var paste_btn := UIFactory.make_action_button("⏎ PASTE")
	paste_btn.pressed.connect(_on_paste_pressed)
	grid.add_child(paste_btn)

	var load_btn := UIFactory.make_action_button("LOAD")
	load_btn.pressed.connect(_on_load_string_pressed)
	grid.add_child(load_btn)

	return panel


func _build_bin_panel() -> Control:
	var panel := UIFactory.make_section_panel("BIN [0]", true)
	var body: VBoxContainer = panel.get_meta("body")
	bin_count_label = panel.get_meta("title")

	var save_btn := UIFactory.make_action_button("+ SAVE")
	save_btn.pressed.connect(_on_save_to_bin_pressed)
	panel.get_meta("title_row").add_child(save_btn)

	# Search box (2B-5): substring filter on entry names. Updates the
	# rendered list live as the user types — no Enter required.
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
	_refresh_bin_list()


func _build_footer() -> Control:
	var border := ColorRect.new()
	border.color = Palette.BORDER
	border.custom_minimum_size = Vector2(0, 1)
	border.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var foot := UIFactory.make_label(
		"UP TO 4 CHANNELS · MIX & REVERB IN MASTER · LOCK PARAMS OR MODULES TO HOLD THEM THROUGH GEN · BIN PERSISTS",
		10, Palette.TEXT_DIM, 0.3
	)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(border)
	v.add_child(foot)
	return v


# ── Refresh helpers ────────────────────────────────────────────────

func _re_render() -> void:
	# Any direct render call cancels a pending debounced one — otherwise we'd
	# render twice in a row when a slider edit is followed by an action button.
	if render_timer:
		render_timer.stop()
	samples = Synth.render_sound(sound)
	if waveform:
		waveform.set_samples(samples)
	sound_string = SoundData.sound_to_string(sound)
	if sound_string_input and not sound_string_input.has_focus():
		sound_string_input.text = sound_string
	_refresh_waveform_info()


# Slider drag → coalesced render. Restart the one-shot timer; whichever
# edit lands last wins, and we render once after motion settles.
func _request_re_render() -> void:
	if render_timer:
		render_timer.start()
	else:
		_re_render()


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
		btn.add_theme_font_size_override("font_size", Palette.FONT_VALUE)

		var active: bool = i == active_channel
		var bg: Color = Palette.ACCENT if active else Color(0, 0, 0, 0)
		var fg: Color = Palette.BG if active else Palette.TEXT
		var border: Color = Palette.ACCENT if (active or bool(ch_dict.get("soloed", false))) else Palette.BORDER
		var normal := UIFactory.make_stylebox(bg, border)
		var hover := UIFactory.make_stylebox(Palette.ACCENT.lightened(0.05) if active else Color(1, 0.55, 0.1, 0.08), border)
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
		var n := UIFactory.make_stylebox(Color(0, 0, 0, 0), Palette.BORDER)
		var h := UIFactory.make_stylebox(Color(0, 0, 0, 0), Palette.ACCENT)
		add_btn.add_theme_stylebox_override("normal", n)
		add_btn.add_theme_stylebox_override("hover", h)
		add_btn.add_theme_stylebox_override("pressed", n)
		add_btn.add_theme_stylebox_override("focus", n)
		add_btn.add_theme_color_override("font_color", Palette.TEXT_MUTE)
		add_btn.add_theme_color_override("font_hover_color", Palette.ACCENT)
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
	label_btn.add_theme_color_override("font_color", Palette.ACCENT if i == active_channel else Palette.TEXT_MUTE)
	label_btn.add_theme_color_override("font_hover_color", Palette.ACCENT)
	label_btn.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
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
	b.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	var bg: Color = Palette.ACCENT if on else Color(0, 0, 0, 0)
	var fg: Color = Palette.BG if on else Palette.TEXT_MUTE
	var border: Color = Palette.ACCENT if on else Palette.BORDER_HI
	var normal := UIFactory.make_stylebox(bg, border)
	var hover := UIFactory.make_stylebox(Palette.ACCENT, Palette.ACCENT)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", Palette.BG)
	return b


# Update knob values + lock states for the active channel WITHOUT
# triggering signal emission cascades (which would cause feedback loops).
func _refresh_module_values() -> void:
	var ch_dict: Dictionary = sound.channels[active_channel]
	var ch_locks: Dictionary = locks[active_channel] if active_channel < locks.size() else {}

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
		panel.modulate = Color(1, 1, 1, 0.55) if (mod.enable_key != "" and not enabled) else Color.WHITE


func _refresh_master_values() -> void:
	if master_v_knob == null:
		return
	master_v_knob.set_value_no_signal(float(sound.master.masterVolume))
	master_v_label.text = "%.2f" % float(sound.master.masterVolume)
	verb_mix_knob.set_value_no_signal(float(sound.master.reverbMix))
	verb_mix_label.text = "%.2f" % float(sound.master.reverbMix)
	verb_size_knob.set_value_no_signal(float(sound.master.reverbSize))
	verb_size_label.text = "%.2f" % float(sound.master.reverbSize)


func _refresh_bin_list() -> void:
	for c in bin_container.get_children():
		c.queue_free()

	# Header reflects total stored, not filtered, so the user always
	# knows how many entries the bin actually holds.
	bin_count_label.text = "BIN [%d]" % bin.size()

	if bin.is_empty():
		var empty := UIFactory.make_label("EMPTY · SAVE A SOUND", 11, Palette.TEXT_DIM, 0.3)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bin_container.add_child(UIFactory.wrap_padded(empty, 0, 0, 24, 24))
		return

	# Apply the search filter (2B-5). Substring match on lowercased name;
	# empty query passes everything through.
	var visible: Array = bin
	if not bin_search_query.is_empty():
		visible = bin.filter(func(e): return String(e.get("name", "")).to_lower().contains(bin_search_query))

	if visible.is_empty():
		var miss := UIFactory.make_label("NO MATCH · CLEAR SEARCH", 11, Palette.TEXT_DIM, 0.3)
		miss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		miss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bin_container.add_child(UIFactory.wrap_padded(miss, 0, 0, 24, 24))
		return

	for entry in visible:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := UIFactory.make_label(entry.get("name", "—"), 11, Palette.TEXT, 0.1)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var play_btn := Button.new()
		play_btn.text = "▶"
		play_btn.flat = true
		play_btn.tooltip_text = "Load and play"
		play_btn.add_theme_color_override("font_color", Palette.ACCENT)
		play_btn.custom_minimum_size = Vector2(22, 22)
		play_btn.pressed.connect(_on_bin_load_pressed.bind(entry.get("id", 0)))
		row.add_child(play_btn)

		var del_btn := Button.new()
		del_btn.text = "×"
		del_btn.flat = true
		del_btn.tooltip_text = "Delete"
		del_btn.add_theme_color_override("font_color", Palette.TEXT_MUTE)
		del_btn.add_theme_color_override("font_hover_color", Palette.ACCENT)
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
		v.add_child(UIFactory.wrap_padded(row, 12, 12, 6, 6))
		v.add_child(separator)
		bin_container.add_child(v)


# ── Param + module handlers ────────────────────────────────────────

func _on_param_value_changed(value: float, key: String) -> void:
	# Step is enforced by Knob.step; the def may also store ints.
	var def: Dictionary = SoundData.PARAM_DEFS[key]
	var stored_value: Variant = value
	if def.has("step") and def.step >= 1.0:
		stored_value = int(round(value))

	# Booleans are not addressed here — only modules toggle bools, and the
	# default channel dict already has int/float for everything else.
	sound.channels[active_channel][key] = stored_value
	param_value_labels[key].text = SoundData.format_value(key, value)
	_request_re_render()
	# Keep the channel-tab right-side header info in sync.
	_refresh_waveform_info()


# Knob alt-click emits the new locked state. Mirror it onto the channel's
# locks dict; the knob already updated its own visual.
func _on_param_lock_toggled(is_locked: bool, key: String) -> void:
	var cur: Dictionary = locks[active_channel]
	cur[key] = is_locked


func _on_param_reset(key: String) -> void:
	var def_value: Variant = SoundData.DEFAULT_PARAMS[key]
	sound.channels[active_channel][key] = def_value
	var knob: Knob = param_knobs[key]
	knob.set_value_no_signal(float(def_value))
	param_value_labels[key].text = SoundData.format_value(key, float(def_value))
	_re_render()


func _on_module_toggled(pressed: bool, enable_key: String) -> void:
	sound.channels[active_channel][enable_key] = pressed
	# Re-style and re-dim
	UIFactory.apply_check_style(module_check_buttons[enable_key], pressed)
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
	UIFactory.apply_button_style(module_lock_buttons[mod.enable_key], will_lock)
	for p in mod.params:
		var knob: Knob = param_knobs.get(p)
		if knob:
			knob.set_locked(will_lock)


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
	_request_re_render()


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
	_request_re_render()


func _on_master_reset(key: String) -> void:
	var def_value: float = float(SoundData.DEFAULT_MASTER[key])
	sound.master[key] = def_value
	match key:
		"masterVolume":
			master_v_knob.set_value_no_signal(def_value)
			master_v_label.text = "%.2f" % def_value
		"reverbMix":
			verb_mix_knob.set_value_no_signal(def_value)
			verb_mix_label.text = "%.2f" % def_value
		"reverbSize":
			verb_size_knob.set_value_no_signal(def_value)
			verb_size_label.text = "%.2f" % def_value
	_re_render()


# ── Onomatopoeia handlers ──────────────────────────────────────────

func _on_onomatopoeia_submitted(text: String) -> void:
	_apply_onomatopoeia(text)


func _on_onomatopoeia_apply_pressed() -> void:
	_apply_onomatopoeia(onomatopoeia_input.text)


func _apply_onomatopoeia(text: String) -> void:
	var phonemes: Array = Onomatopoeia.tokenize(text)
	if phonemes.is_empty():
		_flash_status("?")
		return
	_push_undo()
	var ch: Dictionary = sound.channels[active_channel]
	var ch_locks: Dictionary = locks[active_channel] if active_channel < locks.size() else {}
	var new_params: Dictionary = Onomatopoeia.text_to_patch(text, ch, ch_locks)
	sound.channels[active_channel] = new_params
	# Cap the status flash so a long word doesn't blow out the pill.
	var label: String = text.to_upper()
	if label.length() > 12:
		label = label.substr(0, 11) + "…"
	_apply_and_play(label)
	_refresh_module_values()


# ── Action handlers ────────────────────────────────────────────────

func _on_generate_pressed() -> void:
	_push_undo()
	# Seed BEFORE randomize_all reads any randf — same seed on the
	# SpinBox = same generated sound, every time.
	_consume_variation_seed()
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
	# FileDialog's .wav filter doesn't enforce the extension on the typed
	# filename — append it ourselves so dragging the export into a DAW or
	# Godot project works without a manual rename.
	if not path.to_lower().ends_with(".wav"):
		path += ".wav"
	var bytes: PackedByteArray = SoundData.encode_wav(samples)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		# get_open_error() captures permission/path issues that swallow open().
		var err: int = FileAccess.get_open_error()
		_flash_status("WRITE FAIL")
		push_warning("WAV export failed to open %s: %s" % [path, error_string(err)])
		return
	f.store_buffer(bytes)
	# store_buffer() can fail mid-write (disk full, etc.) — surface that too.
	var write_err: int = f.get_error()
	f.close()
	if write_err != OK:
		_flash_status("WRITE FAIL")
		push_warning("WAV export failed mid-write at %s: %s" % [path, error_string(write_err)])
		return
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
	_push_undo()
	_replace_sound(s, "PASTED")


func _on_load_string_pressed() -> void:
	var s = SoundData.sound_from_string(sound_string_input.text)
	if s == null:
		_flash_status("INVALID")
		return
	_push_undo()
	_replace_sound(s, "LOADED")


func _on_preset_pressed(entry: Dictionary) -> void:
	# User preset: load the saved sound string directly (kind="user",
	# carries a "string" field instead of a function reference).
	if entry.get("kind", "") == "user":
		var us = SoundData.sound_from_string(String(entry.get("string", "")))
		if us == null:
			_flash_status("CORRUPT")
			return
		_push_undo()
		_replace_sound(us, entry.name)
		return

	if entry.kind == "sound":
		_consume_variation_seed()
		var s = Presets.run_preset(entry, {}, {})
		_push_undo()
		_replace_sound(s, entry.name)
		return

	_consume_variation_seed()
	_push_undo()
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
		_push_undo()
		_replace_sound(s, "LOADED")
		return


func _on_bin_delete_pressed(id: int) -> void:
	bin = bin.filter(func(e): return int(e.get("id", -1)) != id)
	_persist_bin()
	_refresh_bin_list()


func _persist_bin() -> void:
	BinStore.persist(bin)


func _load_bin() -> void:
	bin = BinStore.load_bin()


# ── Undo / redo ────────────────────────────────────────────────────

# Capture (sound, locks, active_channel) as one immutable snapshot.
# Dictionary.duplicate(true) recurses into nested arrays/dicts, so the
# returned dict is fully decoupled from live state.
func _snapshot() -> Dictionary:
	return {
		"sound": sound.duplicate(true),
		"locks": locks.duplicate(true),
		"active_channel": active_channel,
	}


# Push current state onto the undo stack and clear redo (new branch taken).
# Called BEFORE any state replacement (GEN, preset, paste, bin-load).
func _push_undo() -> void:
	undo_stack.append(_snapshot())
	if undo_stack.size() > UNDO_MAX:
		undo_stack.pop_front()
	redo_stack.clear()


func _undo() -> void:
	if undo_stack.is_empty():
		_flash_status("NO UNDO")
		return
	redo_stack.append(_snapshot())
	if redo_stack.size() > UNDO_MAX:
		redo_stack.pop_front()
	_restore_snapshot(undo_stack.pop_back(), "UNDO")


func _redo() -> void:
	if redo_stack.is_empty():
		_flash_status("NO REDO")
		return
	undo_stack.append(_snapshot())
	if undo_stack.size() > UNDO_MAX:
		undo_stack.pop_front()
	_restore_snapshot(redo_stack.pop_back(), "REDO")


# Restore a snapshot taken by _snapshot(). Mirrors _replace_sound's refresh
# sequence but keeps locks + active_channel from the snapshot rather than
# resetting them.
func _restore_snapshot(snap: Dictionary, label: String) -> void:
	sound = snap.sound
	locks = snap.locks
	active_channel = clampi(int(snap.active_channel), 0, sound.channels.size() - 1)
	_apply_and_play(label)
	_refresh_channel_tabs()
	_refresh_mix_rows()
	_refresh_module_values()
	_refresh_master_values()


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
	audio_player.stop()
	audio_player.stream = Playback.build_stream(buf)
	audio_player.play()


# ── Status flash ───────────────────────────────────────────────────

func _flash_status(msg: String) -> void:
	status_label.text = msg
	# Filled-pill state when transient, hollow when "READY".
	UIFactory.apply_panel_style(status_label, Palette.ACCENT, Palette.ACCENT)
	status_label.add_theme_color_override("font_color", Palette.BG)
	status_token += 1
	var token := status_token
	get_tree().create_timer(Palette.STATUS_HOLD_SEC).timeout.connect(func():
		if token != status_token:
			return
		status_label.text = "READY"
		UIFactory.apply_panel_style(status_label, Palette.BG, Palette.ACCENT)
		status_label.add_theme_color_override("font_color", Palette.ACCENT)
	)


# ── Input ──────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# All hotkeys skip when a text field is focused so users can type freely
	# (sound-string LineEdit, FileDialog filename field, etc.). Undo/redo are
	# included in the gate because LineEdit handles its own Ctrl+Z internally.
	if _line_edit_focused():
		return
	if event.is_action_pressed("play_sound"):
		_on_play_pressed()
	elif event.is_action_pressed("re_render"):
		# Forces a fresh render + play. Useful after a paste or to A/B-confirm
		# the cached samples match the current parameters.
		_apply_and_play("PLAY")
	elif event.is_action_pressed("gen_sound"):
		_on_generate_pressed()
	elif event.is_action_pressed("export_sound"):
		_on_export_pressed()
	elif event.is_action_pressed("undo_action"):
		_undo()
	elif event.is_action_pressed("redo_action"):
		_redo()
	elif event.is_action_pressed("channel_1"):
		_switch_channel_hotkey(0)
	elif event.is_action_pressed("channel_2"):
		_switch_channel_hotkey(1)
	elif event.is_action_pressed("channel_3"):
		_switch_channel_hotkey(2)
	elif event.is_action_pressed("channel_4"):
		_switch_channel_hotkey(3)


# Hotkey-driven channel switch: silently no-ops when the channel doesn't
# exist (e.g. pressing "4" with only 2 channels), so missing channels never
# crash or flash an error.
func _switch_channel_hotkey(idx: int) -> void:
	if idx < 0 or idx >= sound.channels.size():
		return
	if idx == active_channel:
		return
	_on_channel_tab_pressed(idx)


func _line_edit_focused() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and f is LineEdit
