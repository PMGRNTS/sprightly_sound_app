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

# ── Font sizes ─────────────────────────────────────────────────────
const FONT_TITLE    := 26  # app title
const FONT_VALUE    := 11  # slider value labels, sound-string input, channel-tab labels
const FONT_LABEL    := 12  # status pill, module checkbox/title, secondary buttons
const FONT_SMALL    := 10  # mix-row level value, lock icons

# ── Status pill ────────────────────────────────────────────────────
const STATUS_HOLD_SEC := 1.4  # how long a transient flash ("GEN", "EXPORTED") sticks
