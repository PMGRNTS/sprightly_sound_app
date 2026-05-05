class_name PresetsDestruct
extends PresetsHelpers

# Things breaking. Most use noise + HP-filter for the bright shatter
# transient, plus delay or short reverb-via-decay for the debris feel.


# Glass: bright shatter + decaying delay tails.
static func preset_glass_break(params: Dictionary, locked: Dictionary) -> Dictionary:
	var t: Dictionary = _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(2500.0, 4000.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.4, -0.2), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"delayEnabled": true,
		"delayTime": _rand(40.0, 80.0), "delayFeedback": _rand(0.4, 0.55), "delayMix": 0.5,
		"volume": _rand(0.4, 0.55),
	})
	t.merge(ENV_DECAY_ONLY, true)
	return _apply_target(params, locked, t)


# Wood crack: square stub + drive — splintering.
static func preset_wood_crack(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(200.0, 400.0),
		"length": _rand(0.08, 0.15),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.4, -0.2), "pitchAttack": 0.0, "pitchDecay": _rand(0.4, 0.6),
		"driveEnabled": true, "driveAmount": _rand(0.5, 0.7), "driveMix": 0.9,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.45, 0.6),
	}))


# Stone crack: lower thud + drive — masonry / boulder snap.
static func preset_stone_crack(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(120.0, 200.0),
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 0.8,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(500.0, 900.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.3, 0.0), "filterAttack": 0.0, "filterDecay": _rand(0.4, 0.6),
		"volume": _rand(0.45, 0.6),
	}))


# Metal clang: bright sustained ring with delay — bell, anvil, cymbal.
static func preset_metal_clang(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(800.0, 1400.0),
		"length": _rand(0.4, 0.7),
		"voice": _rand_int(2, 3), "detune": _rand(0.03, 0.07),
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.6,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2200.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"delayEnabled": true,
		"delayTime": _rand(60.0, 120.0), "delayFeedback": _rand(0.4, 0.6), "delayMix": 0.4,
		"volume": _rand(0.4, 0.5),
	}))


# Rubble: extended noise tail — falling debris after a collapse.
static func preset_rubble(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.5, 0.9),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.0, 0.05), "ampDecay": 0.5, "ampSustain": 0.4, "ampRelease": 0.6,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(-0.3, -0.1), "filterAttack": 0.0, "filterDecay": _rand(0.6, 0.85),
		"tremEnabled": true,
		"tremDepth": _rand(0.3, 0.5), "tremShape": 4, "tremRate": _rand(8.0, 15.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": _rand(0.4, 0.55),
	}))


# Rip: filter sweep + drive — fabric tearing / wound opening.
static func preset_rip(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.2, 0.35),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.5,
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 0.9,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(-0.5, -0.3), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"volume": _rand(0.4, 0.55),
	}))


# Impact heavy: low thud with drive — crate dropping, wall punch.
static func preset_impact_heavy(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(50.0, 90.0),
		"length": _rand(0.15, 0.25),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.05),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.5, -0.3), "pitchAttack": 0.0, "pitchDecay": _rand(0.5, 0.7),
		"driveEnabled": true, "driveAmount": _rand(0.5, 0.7), "driveMix": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.5, 0.65),
	}))


# Impact light: tap — stylus, finger flick, tap on a surface.
static func preset_impact_light(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(400.0, 700.0),
		"length": _rand(0.04, 0.08),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.35, 0.5),
	}))
