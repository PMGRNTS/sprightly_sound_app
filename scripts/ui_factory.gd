class_name UIFactory
extends RefCounted

# Pure UI construction helpers. Everything here is a static factory or
# styling pass that takes input + Palette tokens and returns a styled
# Control. Stateful, signal-wiring builders (param rows, module panels,
# channel tabs) stay in main.gd because they read/write the controller's
# cached node maps and connect handlers.
#
# Why a class instead of free functions: keeps the factories grouped,
# documents the boundary between "pure styling" and "controller wiring",
# and lets new modules (a future ui_factory_pro for spectrum / pitch
# ladder views) extend UIFactory cleanly.


# ── Labels ─────────────────────────────────────────────────────────

# Solid Label with theme overrides applied. `letter_spacing` is reserved
# for a future custom-font upgrade — currently a no-op (see note below).
static func make_label(text: String, font_size: int, color: Color, letter_spacing: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if letter_spacing > 0.0:
		_set_label_letter_spacing(l, letter_spacing)
	return l


# Approximates the JS letter-spacing by injecting non-breaking spaces.
# Letter-spacing as a font setting needs a custom font; left as a single
# upgrade point for when we wire one up.
static func _set_label_letter_spacing(_l: Label, _spacing_em: float) -> void:
	pass


# ── Padding ────────────────────────────────────────────────────────

# Wraps `child` in a MarginContainer with explicit per-side padding.
# Used wherever a section needs symmetric or asymmetric inner padding.
static func wrap_padded(child: Control, l: int, r: int, t: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_bottom", b)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(child)
	return m


# ── Styleboxes ─────────────────────────────────────────────────────

# 1 px border, 6×3 padding, square corners. The default panel/input look.
static func make_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
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


# Styled background for a non-padded surface (the panel itself, not its
# content). PanelContainer expects "panel" theme key; everything else
# (e.g. Label) takes "normal".
static func apply_panel_style(node: Control, bg: Color, border: Color) -> void:
	var s := make_stylebox(bg, border)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	if node is PanelContainer:
		node.add_theme_stylebox_override("panel", s)
	else:
		node.add_theme_stylebox_override("normal", s)


static func apply_lineedit_style(le: LineEdit) -> void:
	var n := make_stylebox(Palette.INSET, Palette.BORDER)
	var f := make_stylebox(Palette.INSET, Palette.ACCENT)
	le.add_theme_stylebox_override("normal", n)
	le.add_theme_stylebox_override("focus", f)


# ── Buttons ────────────────────────────────────────────────────────

# Lock button (🔒/🔓) styling. Filled accent when locked, hollow when
# unlocked. Hover always inverts to accent.
static func apply_button_style(b: Button, locked: bool) -> void:
	var bg: Color = Palette.ACCENT if locked else Color(0, 0, 0, 0)
	var border: Color = Palette.ACCENT if locked else Palette.BORDER_HI
	var fg: Color = Palette.BG if locked else Palette.TEXT_DIM

	var normal := make_stylebox(bg, border)
	var hover := make_stylebox(Palette.ACCENT, Palette.ACCENT)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", Palette.BG)
	b.text = "🔒" if locked else "🔓"


static func make_lock_button() -> Button:
	var b := Button.new()
	b.text = "🔒"
	b.tooltip_text = "Lock to preserve while randomizing"
	b.custom_minimum_size = Vector2(22, 22)
	b.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	b.toggle_mode = false
	apply_button_style(b, false)
	return b


# Custom checkbox-style toggle. The React app uses a small filled box
# instead of the default Godot CheckBox (which doesn't accept the same
# styling), so we replicate that look here.
static func apply_check_style(b: Button, on: bool) -> void:
	var bg: Color = Palette.ACCENT if on else Color(0, 0, 0, 0)
	var fg: Color = Palette.BG if on else Palette.TEXT_MUTE
	var border: Color = Palette.ACCENT if on else Palette.BORDER_HI
	var normal := make_stylebox(bg, border)
	var hover := make_stylebox(bg.lightened(0.05) if on else Palette.BORDER, border)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", fg)
	b.text = "■" if on else " "
	b.add_theme_font_size_override("font_size", Palette.FONT_SMALL)


static func make_check_button(text: String, on: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = on
	apply_check_style(b, on)
	return b


# Primary or secondary action button (GEN, PLAY, EXPORT, …). When
# `primary` is true the resting state has a subtle filled background;
# false leaves it transparent until hover.
static func make_action_button(text: String, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_color_override("font_color", Palette.TEXT)
	b.add_theme_color_override("font_hover_color", Palette.BG)
	b.add_theme_color_override("font_pressed_color", Palette.BG)
	b.add_theme_font_size_override("font_size", Palette.FONT_VALUE)
	b.custom_minimum_size = Vector2(0, 26)

	var normal := make_stylebox(Color("#261f17") if primary else Color(0, 0, 0, 0), Palette.BORDER_HI)
	var hover := make_stylebox(Palette.ACCENT, Palette.ACCENT)
	var pressed := make_stylebox(Palette.ACCENT, Palette.ACCENT)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", normal)
	return b


# ── Knob boxes ─────────────────────────────────────────────────────

# Most PARAM_DEFS labels fit a 56 px knob box at 10 pt; a handful don't, so
# we override the display text here for the knob view only. The PARAM_DEFS
# label is still used by the value-readout formatter and by anything that
# wants the long form.
const KNOB_LABEL_OVERRIDES: Dictionary = {
	"crushBits": "BITS",
	"crushRate": "S.RATE",
	"delayFeedback": "FB",
	"filterRes": "RES",
	"filterCutoff": "CUTOFF",
}


# Builds a 56 × 72 knob box (label · knob · value). Returns a dictionary so
# the controller can cache the inner controls the same way it caches sliders
# today (param_knobs / param_value_labels / param_lock-equivalents).
static func make_knob_box(param_key: String) -> Dictionary:
	var def: Dictionary = SoundData.PARAM_DEFS[param_key]
	var label_text: String = KNOB_LABEL_OVERRIDES.get(param_key, def.label)
	return _build_knob_box(label_text, def.label, def.min, def.max, def.step)


# Master / generic flavour. The header label is also used as the tooltip
# title so we don't need a separate PARAM_DEFS entry for master output.
static func make_master_knob_box(label_text: String, lo: float, hi: float, st: float) -> Dictionary:
	return _build_knob_box(label_text, label_text, lo, hi, st)


static func _build_knob_box(label_text: String, tooltip_title: String, lo: float, hi: float, st: float) -> Dictionary:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.custom_minimum_size = Vector2(56, 72)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label_btn := Button.new()
	label_btn.text = label_text
	label_btn.flat = true
	label_btn.add_theme_color_override("font_color", Palette.TEXT_MUTE)
	label_btn.add_theme_color_override("font_hover_color", Palette.ACCENT)
	label_btn.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	label_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_btn.tooltip_text = "Click to reset · alt-click knob to lock"
	label_btn.custom_minimum_size = Vector2(0, 13)
	label_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Strip the default Button stylebox padding so the label row is actually 13 px.
	var empty_sb := StyleBoxEmpty.new()
	label_btn.add_theme_stylebox_override("normal", empty_sb)
	label_btn.add_theme_stylebox_override("hover", empty_sb)
	label_btn.add_theme_stylebox_override("pressed", empty_sb)
	label_btn.add_theme_stylebox_override("focus", empty_sb)
	box.add_child(label_btn)

	var knob := Knob.new()
	knob.min_value = lo
	knob.max_value = hi
	knob.step = st
	knob.tooltip_text = "%s · drag · right-click reset · alt-click lock" % tooltip_title
	knob.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	knob.size_flags_vertical = Control.SIZE_EXPAND_FILL
	knob.custom_minimum_size = Vector2(36, 36)
	box.add_child(knob)

	var value_label := Label.new()
	value_label.text = "—"
	value_label.add_theme_color_override("font_color", Palette.TEXT)
	value_label.add_theme_font_size_override("font_size", Palette.FONT_SMALL)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(0, 12)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(value_label)

	return {
		"box": box,
		"knob": knob,
		"value_label": value_label,
		"label_btn": label_btn,
	}


# ── Section panels ─────────────────────────────────────────────────

# Returns a PanelContainer whose body is a child VBoxContainer. The
# panel carries metadata so callers can append into the body and
# (optionally) the title row without re-walking the tree:
#   panel.get_meta("body")       VBoxContainer for the section's content
#   panel.get_meta("title_row")  HBoxContainer beside the title (for status pills, etc.)
#   panel.get_meta("title")      The title Label itself
static func make_section_panel(title_text: String, _flexible_height: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	apply_panel_style(panel, Palette.PANEL, Palette.BORDER)

	var v := VBoxContainer.new()
	panel.add_child(v)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	v.add_child(wrap_padded(title_row, 10, 10, 3, 3))

	var title := make_label(title_text, Palette.FONT_SMALL, Palette.TEXT_MUTE, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var border := ColorRect.new()
	border.color = Palette.BORDER
	border.custom_minimum_size = Vector2(0, 1)
	border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(border)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	v.add_child(wrap_padded(body, 10, 10, 4, 6))

	panel.set_meta("body", body)
	panel.set_meta("title", title)
	panel.set_meta("title_row", title_row)
	return panel
