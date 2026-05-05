class_name PresetsUI
extends PresetsHelpers

# Subtle interface feedback. Most are very short (<100 ms) and use modest
# volume so they layer over a game's existing audio without competing.


# Hover: very brief sine tip — non-intrusive cursor feedback.
static func preset_hover(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(1500.0, 2200.0),
		"length": _rand(0.025, 0.05),
		"voice": 1, "detune": 0.0,
		"volume": _rand(0.25, 0.35),
	}))


# Press: short click with a tiny pitch dip — the "physical" button feel.
static func preset_press(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(800.0, 1200.0),
		"length": _rand(0.04, 0.08),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.15, -0.05), "pitchAttack": 0.0, "pitchDecay": _rand(0.4, 0.6),
		"volume": 0.4,
	}))


# Toggle-on / Toggle-off: paired rising / falling chirps — the mental
# model is "switch flips up" vs. "switch flips down".
static func preset_toggle_on(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(500.0, 700.0),
		"length": _rand(0.08, 0.12),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.4, 0.6), "pitchAttack": _rand(0.4, 0.7), "pitchDecay": 0.0,
		"volume": 0.4,
	}))


static func preset_toggle_off(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(700.0, 900.0),
		"length": _rand(0.08, 0.12),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.5, -0.3), "pitchAttack": 0.0, "pitchDecay": _rand(0.5, 0.8),
		"volume": 0.4,
	}))


# Menu: chunkier than press — the "I committed to opening this" feel.
static func preset_menu(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(400.0, 600.0),
		"length": _rand(0.12, 0.18),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.1, 0.2), "pitchAttack": _rand(0.2, 0.4), "pitchDecay": 0.0,
		"volume": 0.45,
	}))


# Cancel: descending counterpart to MENU.
static func preset_cancel(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(700.0, 900.0),
		"length": _rand(0.12, 0.18),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.4, -0.2), "pitchAttack": 0.0, "pitchDecay": _rand(0.6, 0.8),
		"volume": 0.4,
	}))


# Error: low driven buzz — short, impossible to miss, doesn't startle.
static func preset_error(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([1, 4]),
		"pitch": _rand(100.0, 180.0),
		"length": _rand(0.18, 0.28),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.4,
		"driveEnabled": true, "driveAmount": _rand(0.3, 0.5), "driveMix": 1.0,
		"volume": 0.5,
	}))


# Notify: two-tone pulse via the arpeggio (alternating fifth) — the
# generic "you got mail" / quest-objective beep.
static func preset_notify(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(700.0, 900.0),
		"length": _rand(0.2, 0.3),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(10.0, 14.0),
		"arpStep1": 5, "arpStep2": 0, "arpStep3": 5,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.5,
		"volume": 0.45,
	}))


# Type: HP-filtered square stub — a single typewriter / mechanical-key click.
static func preset_typing(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(300.0, 450.0),
		"length": _rand(0.02, 0.04),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(700.0, 1100.0), "filterRes": 0.2,
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.25, 0.35),
	}))


# Open / Close: paired LP-filtered noise sweeps. Open BRIGHTENS over time
# (filter env opens up); Close DARKENS (filter env closes down).
static func preset_open(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.18, 0.28),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.6, 0.8), "filterAttack": _rand(0.1, 0.3), "filterDecay": _rand(0.5, 0.7),
		"volume": 0.4,
	}))


static func preset_close(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.18, 0.28),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.0, 0.05), "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1200.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.6, -0.4), "filterAttack": 0.0, "filterDecay": _rand(0.6, 0.8),
		"volume": 0.4,
	}))
