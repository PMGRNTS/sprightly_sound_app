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
var export_sample_rate: int = 44100
var export_bit_depth: int = 16
var export_normalize: bool = false

# Batch export. The options dialog is UI and lives in UIBuilder; the
# directory picker and worker thread are infrastructure and live here.
var batch_dir_dialog: FileDialog
var batch_thread: Thread
# Coalesces rapid slider drags into a single render. Started/restarted
# by _request_re_render(); cancelled by any direct _re_render() call.
var render_timer: Timer

# ── Window scaling ─────────────────────────────────────────────────
# Physical pixels per layout point on the current screen (2.0 on a Retina
# display, 1.0 on a conventional one). Sizes in Palette are points; the
# Window API is always pixels, so anything crossing that boundary gets
# multiplied by this.
var ui_scale: float = 1.0


# ── Lifecycle ──────────────────────────────────────────────────────

func _ready() -> void:
	_configure_window_scaling()

	# Apply saved theme BEFORE build_ui so initial styling matches the
	# user's last choice. Empty string = no saved choice → keep default.
	var saved_theme: String = Persistence.load_theme()
	if not saved_theme.is_empty():
		Palette.apply_theme(saved_theme)

	var saved_res: Vector2i = Persistence.load_resolution()
	if saved_res != Vector2i.ZERO:
		get_window().size = saved_res
		var saved_pos: Vector2i = Persistence.load_window_position()
		if saved_pos != Vector2i(-1, -1):
			get_window().position = saved_pos
		else:
			get_window().position = (DisplayServer.screen_get_size() - saved_res) / 2
	else:
		# First run: open at the design size.
		var first: Vector2i = to_pixels(Palette.DESIGN_SIZE)
		get_window().size = first
		get_window().position = (DisplayServer.screen_get_size() - first) / 2

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

	batch_dir_dialog = FileDialog.new()
	batch_dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	batch_dir_dialog.access = FileDialog.ACCESS_FILESYSTEM
	batch_dir_dialog.size = Palette.SAVE_DIALOG_SIZE
	batch_dir_dialog.dir_selected.connect(_on_batch_dir_selected)
	add_child(batch_dir_dialog)

	ui.build_ui()

	state.bin.assign(Persistence.load_bin())
	_re_render()
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	ui.refresh_master_values()
	ui.refresh_bin_list()


# ── Window scaling ─────────────────────────────────────────────────
# The UI is laid out in points. On a HiDPI screen the OS measures the
# window in physical pixels — a 2560×1440-point window reports as
# 5120×2880 — so we drive the canvas_items stretch base from
# window_size / ui_scale. One layout point then equals one OS point at
# any DPI: text stays crisp and correctly sized, and a bigger window
# buys more ROOM rather than bigger widgets.
#
# The previous setup pinned the stretch base at a fixed 1920×1080, so the
# logical viewport was always exactly 1080 points tall no matter how large
# the window got. Enlarging the window only magnified the UI, and content
# growth spilled past the bottom edge with no way to reach it.
func _configure_window_scaling() -> void:
	var win := get_window()
	ui_scale = _detect_ui_scale()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.min_size = to_pixels(Palette.MIN_WINDOW_SIZE)
	win.size_changed.connect(_sync_content_scale)
	_sync_content_scale()


func _sync_content_scale() -> void:
	var win := get_window()
	# Base == window size in points ⇒ the stretch factor is exactly
	# ui_scale on both axes, with no aspect-driven letterboxing.
	win.content_scale_size = Vector2i(Vector2(win.size) / ui_scale)
	# Dragging the window edge changes the size too, not just the picker.
	if ui != null:
		ui.update_resolution_label()


# Physical pixels per point for the window's current screen.
# screen_get_scale() is exact on macOS; on platforms where it always
# reports 1.0 we derive the factor from the reported DPI instead.
func _detect_ui_scale() -> float:
	var screen: int = DisplayServer.window_get_current_screen()
	var s: float = DisplayServer.screen_get_scale(screen)
	if s <= 1.0:
		var dpi: int = DisplayServer.screen_get_dpi(screen)
		if dpi > 0:
			s = float(dpi) / 96.0
	return clampf(snappedf(s, 0.25), 1.0, 3.0)


func to_pixels(points: Vector2i) -> Vector2i:
	return Vector2i(Vector2(points) * ui_scale)


func to_points(pixels: Vector2i) -> Vector2i:
	return Vector2i(Vector2(pixels) / ui_scale)


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


func _on_param_lock_toggled(is_locked: bool, key: String) -> void:
	state.locks[state.active_channel][key] = is_locked
	_restyle_param_label(key, is_locked)


func _on_param_label_lock_pressed(key: String) -> void:
	var new_locked := not bool(state.locks[state.active_channel].get(key, false))
	state.locks[state.active_channel][key] = new_locked
	ui.param_knobs[key].set_locked(new_locked)
	_restyle_param_label(key, new_locked)


func _restyle_param_label(key: String, is_locked: bool) -> void:
	var btn: Button = ui.param_label_btns.get(key)
	if btn:
		UIFactory.apply_knob_label_style(btn, is_locked)


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
		_restyle_param_label(p, will_lock)


# ── Channel handlers ───────────────────────────────────────────────

func _on_channel_tab_pressed(idx: int) -> void:
	if idx >= state.sound.channels.size():
		return
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
	if idx >= state.sound.channels.size():
		return
	if not state.remove_channel(idx):
		return
	ui.refresh_channel_tabs()
	ui.refresh_mix_rows()
	ui.refresh_module_values()
	_re_render()


func _on_channel_level_changed(value: float, idx: int) -> void:
	if idx >= state.sound.channels.size():
		return
	state.sound.channels[idx]["level"] = value
	_request_re_render()


func _on_channel_mute_pressed(idx: int) -> void:
	if idx >= state.sound.channels.size():
		return
	state.sound.channels[idx]["muted"] = not bool(state.sound.channels[idx].get("muted", false))
	ui.refresh_mix_rows()
	ui.refresh_channel_tabs()
	_re_render()


func _on_channel_solo_pressed(idx: int) -> void:
	if idx >= state.sound.channels.size():
		return
	state.sound.channels[idx]["soloed"] = not bool(state.sound.channels[idx].get("soloed", false))
	state.active_channel = idx
	ui.refresh_mix_rows()
	ui.refresh_channel_tabs()
	ui.refresh_module_values()
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


func _on_mutate_pressed() -> void:
	state.push_undo()
	Presets.mutate_channel(state.sound.channels[state.active_channel], state.active_channel_locks())
	_apply_and_play("MUTATE")
	ui.refresh_module_values()


func _on_play_pressed() -> void:
	_play_samples(state.samples)


func _on_export_pressed() -> void:
	if state.samples.is_empty():
		ui.flash_status("EMPTY")
		return
	var ts := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")
	save_dialog.current_file = "sfx_%s.wav" % ts
	save_dialog.popup_centered()


func _on_sample_rate_toggled() -> void:
	export_sample_rate = 22050 if export_sample_rate == 44100 else 44100
	ui.refresh_export_labels(export_sample_rate, export_bit_depth, export_normalize)


func _on_bit_depth_toggled() -> void:
	export_bit_depth = 8 if export_bit_depth == 16 else 16
	ui.refresh_export_labels(export_sample_rate, export_bit_depth, export_normalize)


func _on_normalize_toggled() -> void:
	export_normalize = not export_normalize
	ui.refresh_export_labels(export_sample_rate, export_bit_depth, export_normalize)


func _export_samples(samples: PackedFloat32Array) -> PackedByteArray:
	var buf: PackedFloat32Array = SoundData.normalize(samples) if export_normalize else samples
	return SoundData.encode_wav(buf, export_sample_rate, export_bit_depth)


func _on_batch_pressed() -> void:
	ui.open_batch_dialog()


func _on_batch_confirmed() -> void:
	batch_dir_dialog.popup_centered()


func _on_batch_dir_selected(dir_path: String) -> void:
	if batch_thread != null and batch_thread.is_started():
		ui.flash_status("BUSY")
		return

	var count: int = ui.read_batch_count()
	var batch_mutate: bool = ui.read_batch_mutate()
	var saved_sound: Dictionary = state.sound.duplicate(true)
	var saved_seed: int = state.variation_seed
	var base_seed: int = state.variation_seed

	var sounds: Array[Dictionary] = []
	for i in count:
		if batch_mutate:
			var s: Dictionary = saved_sound.duplicate(true)
			Presets.mutate_channel(s.channels[state.active_channel], state.active_channel_locks())
			sounds.append(s)
		else:
			state.variation_seed = base_seed + i
			state.consume_variation_seed()
			var s: Dictionary = saved_sound.duplicate(true)
			var ch_locks: Dictionary = Presets.effective_locks(state.active_channel_locks())
			var new_patch: Dictionary = Presets.randomize_all(s.channels[state.active_channel], ch_locks)
			s.channels[state.active_channel] = new_patch
			sounds.append(s)

	state.sound = saved_sound
	state.variation_seed = saved_seed

	var do_normalize: bool = export_normalize
	var sample_rate: int = export_sample_rate
	var bit_depth: int = export_bit_depth
	var ts := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")

	ui.flash_status("BATCH...")
	batch_thread = Thread.new()
	batch_thread.start(_batch_thread_fn.bind(sounds, dir_path, ts, sample_rate, bit_depth, do_normalize))


func _batch_thread_fn(sounds: Array[Dictionary], dir_path: String, ts: String,
		sample_rate: int, bit_depth: int, do_normalize: bool) -> void:
	var exported: int = 0
	for i in sounds.size():
		var rendered: PackedFloat32Array = Synth.render_sound(sounds[i])
		if do_normalize:
			rendered = SoundData.normalize(rendered)
		var bytes: PackedByteArray = SoundData.encode_wav(rendered, sample_rate, bit_depth)
		var filename: String = "%s/batch_%s_%03d.wav" % [dir_path, ts, i + 1]
		var f := FileAccess.open(filename, FileAccess.WRITE)
		if f != null:
			f.store_buffer(bytes)
			var err := f.get_error()
			f.close()
			if err == OK:
				exported += 1
			else:
				push_warning("Batch write failed for %s: %s" % [filename, error_string(err)])
	call_deferred("_batch_thread_done", exported)


func _batch_thread_done(exported: int) -> void:
	if batch_thread != null:
		batch_thread.wait_to_finish()
		batch_thread = null
	_re_render()
	ui.refresh_module_values()
	ui.flash_status("BATCH %d" % exported)


func _on_save_file_selected(path: String) -> void:
	# FileDialog's .wav filter doesn't enforce the extension on the typed
	# filename — append it ourselves so dragging the export into a DAW or
	# Godot project works without a manual rename.
	if not path.to_lower().ends_with(".wav"):
		path += ".wav"
	var bytes: PackedByteArray = _export_samples(state.samples)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		var err: int = FileAccess.get_open_error()
		ui.show_error_dialog("Export Failed", "Could not open file for writing.\n%s\n%s" % [path.get_file(), error_string(err)])
		return
	f.store_buffer(bytes)
	var write_err: int = f.get_error()
	f.close()
	if write_err != OK:
		ui.show_error_dialog("Export Failed", "Write failed mid-export.\n%s\n%s" % [path.get_file(), error_string(write_err)])
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
	var ok: bool = Persistence.add_user_preset(name, state.sound_string)
	ui.refresh_preset_panel()
	ui.flash_status("SAVED ★" if ok else "SAVE FAILED")


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


# ── Resolution handler ─────────────────────────────────────────────

# `sz` arrives in points; the Window API wants pixels.
func _on_resolution_changed(sz: Vector2i) -> void:
	var px: Vector2i = to_pixels(sz)
	get_window().size = px
	get_window().position = (DisplayServer.screen_get_size() - px) / 2
	Persistence.save_resolution(get_window().size, get_window().position)
	ui.update_resolution_label()


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
	elif event.is_action_pressed("mutate_sound"):
		_on_mutate_pressed()
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Persistence.save_resolution(get_window().size, get_window().position)
		get_tree().quit()
