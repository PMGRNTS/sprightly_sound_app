class_name PresetsDestruct
extends PresetsHelpers

# Things breaking. Most use noise + HP-filter for the bright shatter
# transient, plus delay or short reverb-via-decay for the debris feel.


# Glass: 3ch — HP noise shatter + resonant sine ring + LP noise debris.
static func preset_glass_break() -> Dictionary:
	var ring: Dictionary = _ch({
		"mode": 3, "pitch": _rand(1800.0, 2800.0), "length": 0.35,
		"voice": _rand_int(2, 3), "detune": _rand(0.03, 0.06),
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.6,
		"filterEnabled": true, "filterType": 1,
		"filterCutoff": _rand(1500.0, 2200.0), "filterRes": 0.4,
		"volume": 0.4, "level": 0.75,
	})
	return {
		"channels": [
			_hp_noise_transient(0.05, _rand(2500.0, 4000.0), _rand(0.3, 0.5), 0.55, 0.85),
			ring,
			_lp_noise_tail(0.4, 600.0, 0.35, -0.3, 0.6, 0.4, 0.6),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.15, "reverbSize": 0.35},
	}


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


# Metal clang: 3ch — HP noise click + detuned sine ring + LP noise decay.
static func preset_metal_clang() -> Dictionary:
	var ring: Dictionary = _ch({
		"mode": 3, "pitch": _rand(800.0, 1400.0), "length": 0.5,
		"voice": _rand_int(2, 3), "detune": _rand(0.03, 0.07),
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.6,
		"filterEnabled": true, "filterType": 1,
		"filterCutoff": _rand(1500.0, 2200.0), "filterRes": _rand(0.3, 0.5),
		"delayEnabled": true,
		"delayTime": _rand(60.0, 120.0), "delayFeedback": 0.5, "delayMix": 0.4,
		"volume": 0.45, "level": 0.85,
	})
	return {
		"channels": [
			_hp_noise_transient(0.03, _rand(3000.0, 5000.0), 0.2, 0.5, 0.7),
			ring,
			_lp_noise_tail(0.35, 500.0, 0.3, -0.4, 0.5, 0.35, 0.5),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.2, "reverbSize": 0.4},
	}


# Rubble: 3ch — noise burst + tremolo'd body + long LP tail.
static func preset_rubble() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0, "length": 0.6, "voice": 1,
		"ampAttack": 0.02, "ampDecay": 0.5, "ampSustain": 0.4, "ampRelease": 0.5,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": -0.2, "filterAttack": 0.0, "filterDecay": 0.7,
		"tremEnabled": true,
		"tremDepth": _rand(0.3, 0.5), "tremShape": 4, "tremRate": _rand(8.0, 15.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": 0.45, "level": 0.8,
	})
	return {
		"channels": [
			_hp_noise_transient(0.06, 1800.0, 0.3, 0.55, 0.75),
			body,
			_lp_noise_tail(0.8, 400.0, 0.3, -0.25, 0.8, 0.4, 0.55),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.18, "reverbSize": 0.45},
	}


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


# Impact heavy: 3ch — pitched square impact + LP noise body + sub thump.
static func preset_impact_heavy() -> Dictionary:
	var body: Dictionary = _tonal_body(0, _rand(50.0, 90.0), 0.2, _rand_int(1, 2),
		_rand(0.0, 0.05), _rand(0.5, 0.7), _rand(300.0, 500.0), 0.55, 0.9)
	body.merge(_pitch_env_decay(-0.4, 0.6), true)
	var sub: Dictionary = _pitched_transient(3, _rand(35.0, 55.0), 0.25, 0.5, 0.7)
	return {
		"channels": [
			_hp_noise_transient(0.04, 1500.0, 0.25, 0.5, 0.7),
			body,
			sub,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.1, "reverbSize": 0.25},
	}


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
