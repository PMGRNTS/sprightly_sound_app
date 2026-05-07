class_name Palette
extends RefCounted

# Centralised UI tokens for the SFX generator. Colour values are runtime-
# swappable static vars driven by THEMES below; sizes/timings stay const.
# Re-skinning a token propagates everywhere the var is referenced AFTER
# rebuild_ui() runs (StyleBox instances bake their colours at construction
# time, so a theme switch needs the UI to be torn down and rebuilt).

# ── Colours (theme-driven) ─────────────────────────────────────────
# These 12 colour vars are overwritten by Palette.apply_theme(name).
# Defaults below match THEMES["Charcoal"] so the app renders correctly
# on first run before any theme has been loaded from disk.
static var BG          : Color = Color("#1a1814")
static var PANEL       : Color = Color("#23201a")
static var INSET       : Color = Color("#14120d")
static var BORDER      : Color = Color("#3a342a")
static var BORDER_HI   : Color = Color("#5c5345")
static var TEXT        : Color = Color("#d8ccb4")
static var TEXT_MUTE   : Color = Color("#847d70")
static var TEXT_DIM    : Color = Color("#4d473d")
static var ACCENT      : Color = Color("#c9882d")
static var INDICATOR_OFF: Color = Color("#2a241a")
static var SEPARATOR   : Color = Color("#1f1c16")
static var ACCENT_GHOST: Color = Color(0.79, 0.53, 0.18, 0.08)

# ── Colours (theme-agnostic) ───────────────────────────────────────
# Pure opacity / hollow tokens — no hue, so they don't change per theme.
const TRANSPARENT     := Color(0, 0, 0, 0)
const MODULATE_MUTED  := Color(1, 1, 1, 0.5)
const MODULATE_DIM    := Color(1, 1, 1, 0.55)

# ── Theme registry ─────────────────────────────────────────────────
# Seven curated themes. All desaturated for an editorial / studio feel —
# no neon, no full-saturation accents. ORDER below is the order they
# appear in the picker menu (Charcoal first = default).
const THEMES := {
	"Charcoal": {
		"BG":          Color("#1a1814"),
		"PANEL":       Color("#23201a"),
		"INSET":       Color("#14120d"),
		"BORDER":      Color("#3a342a"),
		"BORDER_HI":   Color("#5c5345"),
		"TEXT":        Color("#d8ccb4"),
		"TEXT_MUTE":   Color("#847d70"),
		"TEXT_DIM":    Color("#4d473d"),
		"ACCENT":      Color("#c9882d"),
		"INDICATOR_OFF": Color("#2a241a"),
		"SEPARATOR":   Color("#1f1c16"),
		"ACCENT_GHOST": Color(0.79, 0.53, 0.18, 0.08),
	},
	"Onyx": {
		"BG":          Color("#14171a"),
		"PANEL":       Color("#1c2024"),
		"INSET":       Color("#0d1014"),
		"BORDER":      Color("#2c3239"),
		"BORDER_HI":   Color("#4a525c"),
		"TEXT":        Color("#c8cdd3"),
		"TEXT_MUTE":   Color("#76808a"),
		"TEXT_DIM":    Color("#424952"),
		"ACCENT":      Color("#6b9bb5"),
		"INDICATOR_OFF": Color("#1a1f24"),
		"SEPARATOR":   Color("#181c20"),
		"ACCENT_GHOST": Color(0.42, 0.61, 0.71, 0.08),
	},
	"Slate": {
		"BG":          Color("#181818"),
		"PANEL":       Color("#222222"),
		"INSET":       Color("#101010"),
		"BORDER":      Color("#303030"),
		"BORDER_HI":   Color("#4f4f4f"),
		"TEXT":        Color("#d0d0d0"),
		"TEXT_MUTE":   Color("#808080"),
		"TEXT_DIM":    Color("#4a4a4a"),
		"ACCENT":      Color("#b09a7a"),
		"INDICATOR_OFF": Color("#252525"),
		"SEPARATOR":   Color("#1c1c1c"),
		"ACCENT_GHOST": Color(0.69, 0.60, 0.48, 0.08),
	},
	"Moss": {
		"BG":          Color("#161a14"),
		"PANEL":       Color("#1d221a"),
		"INSET":       Color("#0e110c"),
		"BORDER":      Color("#2e3329"),
		"BORDER_HI":   Color("#4d5544"),
		"TEXT":        Color("#c8d0bc"),
		"TEXT_MUTE":   Color("#7a8472"),
		"TEXT_DIM":    Color("#444a3d"),
		"ACCENT":      Color("#8aa674"),
		"INDICATOR_OFF": Color("#1f241b"),
		"SEPARATOR":   Color("#191d16"),
		"ACCENT_GHOST": Color(0.54, 0.65, 0.45, 0.08),
	},
	"Plum": {
		"BG":          Color("#1a1418"),
		"PANEL":       Color("#221b20"),
		"INSET":       Color("#120d10"),
		"BORDER":      Color("#38303a"),
		"BORDER_HI":   Color("#5a4d5c"),
		"TEXT":        Color("#d4c4cc"),
		"TEXT_MUTE":   Color("#847680"),
		"TEXT_DIM":    Color("#4a3f48"),
		"ACCENT":      Color("#b58aaa"),
		"INDICATOR_OFF": Color("#251c25"),
		"SEPARATOR":   Color("#1c161a"),
		"ACCENT_GHOST": Color(0.71, 0.54, 0.67, 0.08),
	},
	"Sepia": {
		"BG":          Color("#e8dec9"),
		"PANEL":       Color("#f0e7d3"),
		"INSET":       Color("#d6cbb3"),
		"BORDER":      Color("#b8a988"),
		"BORDER_HI":   Color("#8e7e5a"),
		"TEXT":        Color("#2a2418"),
		"TEXT_MUTE":   Color("#685c44"),
		"TEXT_DIM":    Color("#9a8d72"),
		"ACCENT":      Color("#a85a2a"),
		"INDICATOR_OFF": Color("#cabf9f"),
		"SEPARATOR":   Color("#d4c8a8"),
		"ACCENT_GHOST": Color(0.66, 0.35, 0.16, 0.08),
	},
	"Paper": {
		"BG":          Color("#efeee8"),
		"PANEL":       Color("#f6f5f0"),
		"INSET":       Color("#ddddd6"),
		"BORDER":      Color("#c4c3bc"),
		"BORDER_HI":   Color("#8a8a82"),
		"TEXT":        Color("#1a1a18"),
		"TEXT_MUTE":   Color("#66665e"),
		"TEXT_DIM":    Color("#aaaaa3"),
		"ACCENT":      Color("#2c5a55"),
		"INDICATOR_OFF": Color("#d0d0c8"),
		"SEPARATOR":   Color("#e0dfd9"),
		"ACCENT_GHOST": Color(0.17, 0.35, 0.33, 0.08),
	},
	# Glass relies on the project's per-pixel transparency + the
	# borderless/transparent window flags. BG is fully transparent so
	# the OS desktop shows through; panels are smoked-glass at ~78%
	# alpha; borders and text stay near-opaque so the UI reads cleanly
	# against any wallpaper. Switching to any other theme repaints with
	# an opaque BG, hiding the transparency until you come back.
	"Glass": {
		"BG":          Color(0, 0, 0, 0),
		"PANEL":       Color(0.10, 0.11, 0.13, 0.78),
		"INSET":       Color(0.05, 0.06, 0.08, 0.66),
		"BORDER":      Color(0.45, 0.47, 0.52, 0.85),
		"BORDER_HI":   Color(0.70, 0.72, 0.78, 0.95),
		"TEXT":        Color(0.96, 0.96, 0.98, 1.0),
		"TEXT_MUTE":   Color(0.72, 0.74, 0.78, 0.95),
		"TEXT_DIM":    Color(0.48, 0.50, 0.55, 0.85),
		"ACCENT":      Color(0.66, 0.78, 0.92, 1.0),
		"INDICATOR_OFF": Color(0.20, 0.22, 0.25, 0.70),
		"SEPARATOR":   Color(0.25, 0.27, 0.30, 0.55),
		"ACCENT_GHOST": Color(0.66, 0.78, 0.92, 0.10),
	},
}

# Tracks which theme is currently applied. Read by the picker UI to mark
# the active row with a checkmark.
static var current_theme: String = "Charcoal"


# Waveform line colour: complement of ACCENT (180° hue rotation) with
# saturation knocked back so it stays in the same desaturated register
# as the rest of the theme. Computed on demand so it always tracks the
# active theme without a separate per-theme entry.
static func waveform_line() -> Color:
	var hue: float = fposmod(ACCENT.h + 0.5, 1.0)
	return Color.from_hsv(hue, ACCENT.s * 0.85, ACCENT.v, 1.0)


# Soft underlay glow: same hue as waveform_line, low alpha for a halo.
static func waveform_glow() -> Color:
	var c: Color = waveform_line()
	c.a = 0.25
	return c


# Switch the live colour vars to the named theme. Caller is responsible
# for rebuilding the UI afterwards — StyleBoxes don't pick up var changes
# retroactively. Unknown names are a no-op (keeps the current theme).
static func apply_theme(name: String) -> void:
	if not THEMES.has(name):
		push_warning("Unknown theme: %s" % name)
		return
	var t: Dictionary = THEMES[name]
	BG            = t.BG
	PANEL         = t.PANEL
	INSET         = t.INSET
	BORDER        = t.BORDER
	BORDER_HI     = t.BORDER_HI
	TEXT          = t.TEXT
	TEXT_MUTE     = t.TEXT_MUTE
	TEXT_DIM      = t.TEXT_DIM
	ACCENT        = t.ACCENT
	INDICATOR_OFF = t.INDICATOR_OFF
	SEPARATOR     = t.SEPARATOR
	ACCENT_GHOST  = t.ACCENT_GHOST
	current_theme = name


# ── Font sizes ─────────────────────────────────────────────────────
const FONT_TITLE    := 26  # app title
const FONT_VALUE    := 11  # slider value labels, sound-string input, channel-tab labels
const FONT_LABEL    := 12  # status pill, module checkbox/title, secondary buttons
const FONT_SMALL    := 10  # mix-row level value, lock icons

# ── Layout sizes ───────────────────────────────────────────────────
# Sizes that recur across the layout. Single-use sizes still live near
# their call site (Vector2(82, 22) for VAR spinbox, etc.) when changing
# them is unlikely to need to ripple anywhere else.
# Three-column body layout: modules grid (widest), controls stack
# (master/presets/actions/string), bin (narrowest). Mins keep each
# column usable even when the user shrinks the window aggressively.
const COLUMN_MODULES_MIN  := Vector2(420, 0)
const COLUMN_CONTROLS_MIN := Vector2(340, 0)
const COLUMN_BIN_MIN      := Vector2(220, 0)
const STATUS_LABEL_SIZE   := Vector2(120, 28)
const HAIRLINE_HEIGHT     := Vector2(0, 1)            # 1 px horizontal divider
const WAVEFORM_PANEL_MIN  := Vector2(0, 120)
const WAVEFORM_INFO_LEFT_POS  := Vector2(10, 6)
const WAVEFORM_INFO_RIGHT_POS := Vector2(-260, 6)
const WAVEFORM_INFO_RIGHT_SIZE := Vector2(250, 16)
const MODULE_CHECK_SIZE   := Vector2(18, 18)
const VARIATION_SEED_SIZE := Vector2(82, 22)
const REROLL_BTN_SIZE     := Vector2(28, 22)
const CHANNEL_TAB_SIZE    := Vector2(60, 28)
const CHANNEL_ADD_SIZE    := Vector2(40, 28)
const MIX_LABEL_SIZE      := Vector2(40, 22)
const MINI_BTN_SIZE       := Vector2(22, 22)          # mute / solo / delete / bin-row icons
const SAVE_DIALOG_SIZE    := Vector2i(720, 520)
const PRESET_NAME_DIALOG_SIZE := Vector2i(420, 140)
const PRESET_NAME_BODY_MIN := Vector2(380, 0)
const THEME_BTN_SIZE      := Vector2(28, 28)          # ◐ picker button in header

# ── Window margins ─────────────────────────────────────────────────
const WINDOW_MARGIN_H := 24
const WINDOW_MARGIN_V := 18

# ── Timing ─────────────────────────────────────────────────────────
# Render debounce kept short enough that drag tails render without lag.
const RENDER_DEBOUNCE_S := 0.03

# ── Status pill ────────────────────────────────────────────────────
const STATUS_HOLD_SEC := 1.4  # how long a transient flash ("GEN", "EXPORTED") sticks
