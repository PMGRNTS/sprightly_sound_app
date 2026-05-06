extends Control

# Top-level controller. Owns audio playback infrastructure (players +
# timers + WAV save dialog), creates the SoundState data container and
# the UIBuilder that constructs the control tree, and wires UI signals to
# state mutations + UI refreshes.
#
# Architecture:
#   • State (sound, locks, samples, bin, undo/redo) lives in SoundState.
#   • UI construction + refresh + cached node refs live in UIBuilder.
#   • Persistence (BinStore, UserPresets) is wrapped by the Persistence
#     facade — we don't talk to those modules directly from here.
#   • This file: lifecycle, signal handlers, render orchestration, input.


# ── Collaborators ──────────────────────────────────────────────────
var state: SoundState
var ui: UIBuilder

# ── Audio playback infra ───────────────────────────────────────────
var audio_player: AudioStreamPlayer
var save_dialog: FileDialog
# Coalesces rapid slider drags into a single render. Started/restarted
# by _request_re_render(); cancelled by any direct _re_render() call.
var render_timer: Timer


# ── Lifecycle ──────────────────────────────────────────────────────

func _ready() -> void:
	# Window can scale down to roughly half the design size and still
	# stay legible. Below the design size (1280×900) the project's
	# canvas_items stretch mode scales the entire UI proportionally
	# rather than clipping content; above it, columns flex via stretch
	# ratios. The min keeps fonts/knobs from shrinking below readable.
	get_window().min_size = Vector2i(720, 540)

	# Apply saved theme BEFORE build_ui so initial styling matches the
	# user's last choice. Empty string = no saved choice → keep default.
	var saved_theme: String = Persistence.load_theme()
	if not saved_theme.is_empty():
		Palette.apply_theme(saved_theme)

	state = SoundState.new()
	ui = UIBuilder.new(self, state)

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	render_timer = Timer.new()
	render_timer.wait_time = Palette.RENDER_DEBOUNCE_S
	render_timer.one_shot = true
	render_timer.timeout.connect(_re_render)
	add_child(render_timer)

	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.wav", "WAV audio")
	save_dialog.size = Palette.SAVE_DIALOG_SIZE
	save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(save_dialog)

	ui.build_ui()
	state.bin.assign(Persistence.load_bin())
	_re_render()
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_master_values()
	ui.refresh_bin_list()


# ── Render orchestration ───────────────────────────────────────────

func _re_render() -> void:
	# Any direct render call cancels a pending debounced one — otherwise we'd
	# render twice in a row when a slider edit is followed by an action button.
	if render_timer:
		render_timer.stop()
	state.samples = Synth.render_sound(state.sound)
	if ui.waveform:
		ui.waveform.set_samples(state.samples)
	state.sound_string = SoundData.sound_to_string(state.sound)
	if ui.sound_string_input and not ui.sound_string_input.has_focus():
		ui.sound_string_input.text = state.sound_string
	ui.refresh_waveform_info()


# Slider drag → coalesced render. Restart the one-shot timer; whichever
# edit lands last wins, and we render once after motion settles.
func _request_re_render() -> void:
	if render_timer:
		render_timer.start()
	else:
		_re_render()


# Apply a state change and play it: re-render samples, flash status, play.
func _apply_and_play(label: String) -> void:
	_re_render()
	ui.flash_status(label)
	_play_samples(state.samples)


# ── Param + module handlers ────────────────────────────────────────

func _on_param_value_changed(value: float, key: String) -> void:
	# Step is enforced by Knob.step; the def may also store ints.
	var def: Dictionary = SoundData.PARAM_DEFS[key]
	var stored_value: Variant = value
	if def.has("step") and def.step >= 1.0:
		stored_value = int(round(value))

	state.sound.channels[state.active_channel][key] = stored_value
	ui.param_value_labels[key].text = SoundData.format_value(key, value)
	_request_re_render()
	ui.refresh_waveform_info()


# Knob alt-click emits the new locked state. Mirror it onto the channel's
# locks dict; the knob already updated its own visual.
func _on_param_lock_toggled(is_locked: bool, key: String) -> void:
	state.locks[state.active_channel][key] = is_locked


func _on_param_reset(key: String) -> void:
	var def_value: Variant = SoundData.DEFAULT_PARAMS[key]
	state.sound.channels[state.active_channel][key] = def_value
	var knob: Knob = ui.param_knobs[key]
	knob.set_value_no_signal(float(def_value))
	ui.param_value_labels[key].text = SoundData.format_value(key, float(def_value))
	_re_render()


func _on_module_toggled(pressed: bool, enable_key: String) -> void:
	state.sound.channels[state.active_channel][enable_key] = pressed
	UIFactory.apply_check_style(ui.module_check_buttons[enable_key], pressed)
	for mod in SoundData.MODULES:
		if mod.enable_key == enable_key:
			ui.module_panels[mod.key].modulate = Palette.MODULATE_DIM if not pressed else Color.WHITE
			break
	_re_render()


# Module-level lock: locks the enable flag plus every param in the module.
func _on_module_lock_pressed(mod: Dictionary) -> void:
	if mod.enable_key == "":
		return
	var cur: Dictionary = state.locks[state.active_channel]
	var will_lock: bool = not bool(cur.get(mod.enable_key, false))
	cur[mod.enable_key] = will_lock
	for p in mod.params:
		cur[p] = will_lock
	UIFactory.apply_button_style(ui.module_lock_buttons[mod.enable_key], will_lock)
	for p in mod.params:
		var knob: Knob = ui.param_knobs.get(p)
		if knob:
			knob.set_locked(will_lock)


# ── Channel handlers ───────────────────────────────────────────────

func _on_channel_tab_pressed(idx: int) -> void:
	state.active_channel = idx
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_waveform_info()


func _on_add_channel_pressed() -> void:
	if not state.add_channel():
		return
	ui.flash_status("+ CH %d" % (state.active_channel + 1))
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	_re_render()


func _on_channel_delete_pressed(idx: int) -> void:
	if not state.remove_channel(idx):
		return
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	_re_render()


func _on_channel_level_changed(value: float, idx: int) -> void:
	state.sound.channels[idx]["level"] = value
	_request_re_render()


func _on_channel_mute_pressed(idx: int) -> void:
	state.sound.channels[idx]["muted"] = not bool(state.sound.channels[idx].get("muted", false))
	ui.refresh_mix_rows()
	ui.refresh_channel_tabs()
	_re_render()


func _on_channel_solo_pressed(idx: int) -> void:
	state.sound.channels[idx]["soloed"] = not bool(state.sound.channels[idx].get("soloed", false))
	ui.refresh_mix_rows()
	ui.refresh_channel_tabs()
	_re_render()


# ── Master handlers ────────────────────────────────────────────────

func _on_master_changed(value: float, key: String) -> void:
	state.sound.master[key] = value
	match key:
		"masterVolume":
			ui.master_v_label.text = "%.2f" % value
		"reverbMix":
			ui.verb_mix_label.text = "%.2f" % value
		"reverbSize":
			ui.verb_size_label.text = "%.2f" % value
	_request_re_render()


func _on_master_reset(key: String) -> void:
	var def_value: float = float(SoundData.DEFAULT_MASTER[key])
	state.sound.master[key] = def_value
	match key:
		"masterVolume":
			ui.master_v_knob.set_value_no_signal(def_value)
			ui.master_v_label.text = "%.2f" % def_value
		"reverbMix":
			ui.verb_mix_knob.set_value_no_signal(def_value)
			ui.verb_mix_label.text = "%.2f" % def_value
		"reverbSize":
			ui.verb_size_knob.set_value_no_signal(def_value)
			ui.verb_size_label.text = "%.2f" % def_value
	_re_render()


# ── Action handlers ────────────────────────────────────────────────

func _on_generate_pressed() -> void:
	state.push_undo()
	# Seed BEFORE randomize_all reads any randf — same seed on the
	# SpinBox = same generated sound, every time.
	state.consume_variation_seed()
	if ui.variation_seed_input:
		ui.variation_seed_input.set_value_no_signal(state.variation_seed)
	var ch: Dictionary = state.active_channel_params()
	var ch_locks: Dictionary = Presets.effective_locks(state.active_channel_locks())
	var new_patch: Dictionary = Presets.randomize_all(ch, ch_locks)
	state.sound.channels[state.active_channel] = new_patch
	_apply_and_play("GEN")
	ui.refresh_module_values()


func _on_play_pressed() -> void:
	_play_samples(state.samples)


func _on_export_pressed() -> void:
	if state.samples.is_empty():
		ui.flash_status("EMPTY")
		return
	save_dialog.current_file = "sfx_%s.wav" % Time.get_ticks_msec()
	save_dialog.popup_centered()


func _on_save_file_selected(path: String) -> void:
	# FileDialog's .wav filter doesn't enforce the extension on the typed
	# filename — append it ourselves so dragging the export into a DAW or
	# Godot project works without a manual rename.
	if not path.to_lower().ends_with(".wav"):
		path += ".wav"
	var bytes: PackedByteArray = SoundData.encode_wav(state.samples)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		# get_open_error() captures permission/path issues that swallow open().
		var err: int = FileAccess.get_open_error()
		ui.flash_status("WRITE FAIL")
		push_warning("WAV export failed to open %s: %s" % [path, error_string(err)])
		return
	f.store_buffer(bytes)
	# store_buffer() can fail mid-write (disk full, etc.) — surface that too.
	var write_err: int = f.get_error()
	f.close()
	if write_err != OK:
		ui.flash_status("WRITE FAIL")
		push_warning("WAV export failed mid-write at %s: %s" % [path, error_string(write_err)])
		return
	ui.flash_status("EXPORTED")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(state.sound_string)
	ui.flash_status("COPIED")


func _on_paste_pressed() -> void:
	var text := DisplayServer.clipboard_get()
	var s: Variant = SoundData.sound_from_string(text)
	if s == null:
		ui.flash_status("INVALID")
		return
	state.push_undo()
	_replace_sound_and_refresh(s, "PASTED")


func _on_load_string_pressed() -> void:
	var s: Variant = SoundData.sound_from_string(ui.sound_string_input.text)
	if s == null:
		ui.flash_status("INVALID")
		return
	state.push_undo()
	_replace_sound_and_refresh(s, "LOADED")


func _on_preset_pressed(entry: Dictionary) -> void:
	# User preset: load the saved sound string directly (kind="user",
	# carries a "string" field instead of a function reference).
	if entry.get("kind", "") == "user":
		var us: Variant = SoundData.sound_from_string(String(entry.get("string", "")))
		if us == null:
			ui.flash_status("CORRUPT")
			return
		state.push_undo()
		_replace_sound_and_refresh(us, entry.name)
		return

	if entry.kind == "sound":
		state.consume_variation_seed()
		if ui.variation_seed_input:
			ui.variation_seed_input.set_value_no_signal(state.variation_seed)
		var s: Variant = Presets.run_preset(entry, {}, {})
		state.push_undo()
		_replace_sound_and_refresh(s, entry.name)
		return

	state.consume_variation_seed()
	if ui.variation_seed_input:
		ui.variation_seed_input.set_value_no_signal(state.variation_seed)
	state.push_undo()
	var ch: Dictionary = state.active_channel_params()
	var ch_locks: Dictionary = Presets.effective_locks(state.active_channel_locks())
	var new_patch: Variant = Presets.run_preset(entry, ch, ch_locks)
	# Patch presets collapse to a single-channel sound (matches JS behavior).
	state.apply_patch_preset(new_patch)
	_apply_and_play(entry.name)
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_master_values()


# Replace the entire sound, refresh every UI surface that depends on it,
# and play. Used by paste, load string, bin-load, user preset, undo/redo.
func _replace_sound_and_refresh(new_sound: Dictionary, label: String) -> void:
	state.replace_sound(new_sound)
	_apply_and_play(label)
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_master_values()


# ── Variation seed handlers ────────────────────────────────────────

func _on_variation_seed_changed(value: float) -> void:
	state.variation_seed = int(value)


func _on_variation_reroll_pressed() -> void:
	state.randomize_variation_seed()
	if ui.variation_seed_input:
		ui.variation_seed_input.set_value_no_signal(state.variation_seed)
	ui.flash_status("VAR %d" % state.variation_seed)


# ── Save-as-preset handlers ────────────────────────────────────────

func _on_save_preset_pressed() -> void:
	var default_name: String = "preset_%d" % (Persistence.load_user_presets().size() + 1)
	ui.open_save_preset_dialog(default_name)


func _on_save_preset_confirmed() -> void:
	var name: String = ui.read_save_preset_name()
	if name.is_empty():
		ui.flash_status("EMPTY NAME")
		return
	Persistence.add_user_preset(name, state.sound_string)
	ui.refresh_preset_panel()
	ui.flash_status("SAVED ★")


# ── Bin handlers ───────────────────────────────────────────────────

func _on_save_to_bin_pressed() -> void:
	var id: int = Time.get_ticks_msec()
	var entry: Dictionary = {
		"id": id,
		"name": "sfx_%dch_%s" % [state.sound.channels.size(), str(id).right(5)],
		"string": state.sound_string,
	}
	state.add_to_bin(entry)
	var ok: bool = Persistence.save_bin(state.bin)
	ui.refresh_bin_list()
	ui.flash_status("SAVED" if ok else "SAVE FAILED")


func _on_bin_load_pressed(id: int) -> void:
	var entry: Variant = state.find_bin_entry(id)
	if entry == null:
		return
	var s: Variant = SoundData.sound_from_string(entry.string)
	if s == null:
		ui.flash_status("CORRUPT")
		return
	state.push_undo()
	_replace_sound_and_refresh(s, "LOADED")


func _on_bin_delete_pressed(id: int) -> void:
	state.remove_from_bin(id)
	var ok: bool = Persistence.save_bin(state.bin)
	ui.refresh_bin_list()
	if not ok:
		ui.flash_status("DELETE FAILED")


# ── Theme handler ──────────────────────────────────────────────────
# Theme changes can't be applied incrementally because StyleBox colours
# bake at construction. We tear down the current UI subtree, apply the
# new palette, and rebuild. State (sound, bin, channels) is preserved.
func _on_theme_changed(theme_name: String) -> void:
	if theme_name == Palette.current_theme:
		return
	Palette.apply_theme(theme_name)
	Persistence.save_theme(theme_name)
	if ui != null:
		ui.teardown()
	ui = UIBuilder.new(self, state)
	ui.build_ui()
	_re_render()
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_master_values()
	ui.refresh_bin_list()
	ui.flash_status(theme_name.to_upper())


# ── Audio playback ─────────────────────────────────────────────────

func _play_samples(buf: PackedFloat32Array) -> void:
	if buf.is_empty():
		return
	audio_player.stop()
	audio_player.stream = Playback.build_stream(buf)
	audio_player.play()


# ── Undo / redo (delegate to state, then full UI refresh) ──────────

func _undo() -> void:
	if not state.undo():
		ui.flash_status("NO UNDO")
		return
	_apply_and_play("UNDO")
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_master_values()


func _redo() -> void:
	if not state.redo():
		ui.flash_status("NO REDO")
		return
	_apply_and_play("REDO")
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_master_values()


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
	if idx < 0 or idx >= state.sound.channels.size():
		return
	if idx == state.active_channel:
		return
	_on_channel_tab_pressed(idx)


func _line_edit_focused() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and f is LineEdit
