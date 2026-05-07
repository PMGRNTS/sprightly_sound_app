class_name PresetsMovement
extends PresetsHelpers

# Footsteps and locomotion. The MATERIAL distinguishes the sub-presets
# (wood / stone / metal / water) — each tweaks pitch, filter, and
# transient character to evoke that surface.


# Wood footstep: HP-filtered noise with mid-range body — old floorboard.
static func preset_step_wood(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(150.0, 250.0),
		"length": _rand(0.06, 0.1),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(800.0, 1400.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(-0.3, -0.1), "filterAttack": 0.0, "filterDecay": _rand(0.4, 0.6),
		"volume": _rand(0.3, 0.45),
	}))


# Stone footstep: drier and sharper — boots on rock.
static func preset_step_stone(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(200.0, 350.0),
		"length": _rand(0.04, 0.08),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.35, 0.5),
	}))


# Metal footstep: bright with delay — boot on a steel grate.
static func preset_step_metal(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(900.0, 1400.0),
		"length": _rand(0.05, 0.1),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(2000.0, 3500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"delayEnabled": true,
		"delayTime": _rand(20.0, 50.0), "delayFeedback": _rand(0.2, 0.4), "delayMix": 0.3,
		"volume": _rand(0.35, 0.5),
	}))


# Water step: filtered noise — splashing through shallow water.
static func preset_step_water(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.1, 0.18),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(0.4, 0.6), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.5,
		"volume": _rand(0.35, 0.5),
	}))


# Land: soft thud + a hint of noise — generic landing impact.
static func preset_land(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(80.0, 150.0),
		"length": _rand(0.1, 0.18),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.4, -0.2), "pitchAttack": 0.0, "pitchDecay": _rand(0.4, 0.6),
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.45, 0.6),
	}))


# Slide: extended noise sweep with downward filter movement.
static func preset_slide(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1400.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.6, -0.4), "filterAttack": 0.0, "filterDecay": _rand(0.6, 0.85),
		"volume": _rand(0.35, 0.5),
	}))


# Climb: rhythmic tremolo'd noise — stepping/grabbing in sequence.
static func preset_climb(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.2, 0.35),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(700.0, 1100.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"tremEnabled": true,
		"tremDepth": _rand(0.5, 0.8), "tremShape": 0, "tremRate": _rand(4.0, 8.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.4,
		"volume": _rand(0.3, 0.45),
	}))


# Jump-land: 3ch — noise impact + sub thump body + filtered debris.
static func preset_jump_land() -> Dictionary:
	var thump: Dictionary = _tonal_body(0, _rand(60.0, 110.0), 0.2, _rand_int(1, 2),
		_rand(0.0, 0.05), _rand(0.3, 0.5), _rand(350.0, 600.0), 0.55, 0.85)
	thump.merge(_pitch_env_decay(-0.4, 0.6), true)
	return {
		"channels": [
			_hp_noise_transient(0.04, 1800.0, 0.25, 0.5, 0.75),
			thump,
			_lp_noise_tail(0.2, 500.0, 0.3, -0.2, 0.5, 0.35, 0.5),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.1, "reverbSize": 0.2},
	}


# Roll: tumbling noise — rapid tremolo on filtered noise.
static func preset_roll(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"tremEnabled": true,
		"tremDepth": _rand(0.5, 0.8), "tremShape": 0, "tremRate": _rand(15.0, 25.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": _rand(0.35, 0.5),
	}))
