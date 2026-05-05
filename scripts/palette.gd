class_name Palette
extends RefCounted

# Centralised UI tokens for the SFX generator. Keeping the colour palette,
# font sizes, and key spacing values out of main.gd lets you re-skin the
# whole app from one file. Sizes that are deeply specific to one layout
# (e.g. fixed control widths) intentionally stay near their use sites.

# ── Colours ────────────────────────────────────────────────────────
const BG          := Color("#14110d")  # canvas background
const PANEL       := Color("#1c1814")  # raised panel surface
const INSET       := Color("#0e0b08")  # sunken / input field background
const BORDER      := Color("#3a342a")  # default 1 px border on panels & inputs
const BORDER_HI   := Color("#5c5345")  # active / hovered border highlight
const TEXT        := Color("#e8dcc4")  # primary text
const TEXT_MUTE   := Color("#8a8275")  # secondary / metadata text
const TEXT_DIM    := Color("#5c5345")  # tertiary / placeholder text
const ACCENT      := Color("#ff8c1a")  # active state, status flash, channel-tab fill

# Auxiliary tokens used by specific UI patterns. Kept here (not inline) so
# re-skinning a single token propagates everywhere it's referenced.
const TRANSPARENT     := Color(0, 0, 0, 0)            # hollow button backgrounds
const INDICATOR_OFF   := Color("#332a1f")             # always-on module indicator backdrop
const SEPARATOR       := Color("#221d17")             # bin-row hairline (lower contrast than BORDER)
const ACCENT_GHOST    := Color(1, 0.55, 0.1, 0.08)    # ACCENT at 8% — soft channel-tab hover
const MODULATE_MUTED  := Color(1, 1, 1, 0.5)          # half-opacity for muted channel button
const MODULATE_DIM    := Color(1, 1, 1, 0.55)         # 55% for disabled module panel

# ── Font sizes ─────────────────────────────────────────────────────
const FONT_TITLE    := 26  # app title
const FONT_VALUE    := 11  # slider value labels, sound-string input, channel-tab labels
const FONT_LABEL    := 12  # status pill, module checkbox/title, secondary buttons
const FONT_SMALL    := 10  # mix-row level value, lock icons

# ── Layout sizes ───────────────────────────────────────────────────
# Sizes that recur across the layout. Single-use sizes still live near
# their call site (Vector2(82, 22) for VAR spinbox, etc.) when changing
# them is unlikely to need to ripple anywhere else.
const COLUMN_LEFT_MIN     := Vector2(420, 0)
const COLUMN_RIGHT_MIN    := Vector2(380, 0)
const HEADER_INPUT_SIZE   := Vector2(240, 28)         # onomatopoeia input
const HEADER_BTN_SIZE     := Vector2(36, 28)          # → apply button
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

# ── Window margins ─────────────────────────────────────────────────
const WINDOW_MARGIN_H := 24
const WINDOW_MARGIN_V := 18

# ── Timing ─────────────────────────────────────────────────────────
# Debounce intervals tuned against typical interaction. Keep 0.03 short
# enough that drag tails render without lag, and 0.18 long enough that
# brushing past a button doesn't fire a hover preview.
const RENDER_DEBOUNCE_S := 0.03
const HOVER_DEBOUNCE_S  := 0.18

# ── Status pill ────────────────────────────────────────────────────
const STATUS_HOLD_SEC := 1.4  # how long a transient flash ("GEN", "EXPORTED") sticks
