class_name PresetsModern
extends PresetsHelpers

# Modern shooter / RPG game cues — heartbeat, low-health alerts, weapon
# handling clicks. Lean toward realism rather than chiptune.


# Heartbeat: low pulsing sine — health-critical drumbeat.
static func preset_heartbeat(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(60.0, 90.0),
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.0, 0.03), "ampDecay": 0.5, "ampSustain": 0.0, "ampRelease": 0.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(150.0, 250.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.5, 0.65),
	}))


# Low-health: pulsing bandpass tone — danger warning.
static func preset_low_health(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(180.0, 280.0),
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 2, "filterCutoff": _rand(700.0, 1200.0), "filterRes": _rand(0.55, 0.75),
		"filterEnv": _rand(-0.3, 0.0), "filterAttack": 0.0, "filterDecay": _rand(0.4, 0.6),
		"tremEnabled": true,
		"tremDepth": _rand(0.4, 0.6), "tremShape": 3, "tremRate": _rand(2.5, 4.5),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": _rand(0.4, 0.55),
	}))


# Reload: short mechanical click — gun action / drawer / latch.
static func preset_reload(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(600.0, 1000.0),
		"length": _rand(0.06, 0.12),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.2, 0.0), "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.4, 0.55),
	}))


# Empty chamber: dry click — out-of-ammo / wrong-key feedback.
static func preset_empty_chamber(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(800.0, 1200.0),
		"length": _rand(0.04, 0.07),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(2500.0, 3500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.35, 0.5),
	}))


# Switch weapon: crisp slide — weapon swap / inventory tab change.
static func preset_switch_weapon(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.1, 0.18),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.3, 0.6), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"volume": _rand(0.35, 0.5),
	}))


# Cover-enter: short whoosh — sliding into cover / hugging wall.
static func preset_cover_enter(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.03, 0.08), "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.4, -0.2), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"volume": _rand(0.35, 0.5),
	}))
