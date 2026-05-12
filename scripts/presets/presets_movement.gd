class_name PresetsMovement
extends PresetsHelpers

# Footsteps and locomotion. The MATERIAL distinguishes the sub-presets
# (wood / stone / metal / water) — each tweaks pitch, filter, and
# transient character to evoke that surface.


static func preset_step_wood() -> Dictionary:
	var impact: Dictionary = _hp_noise_transient(0.02, _rand(1200.0, 1800.0), 0.25, 0.4, 0.6)
	var resonance: Dictionary = _tonal_body(
		0, _rand(150.0, 250.0), _rand(0.06, 0.1),
		1, 0.0, 0.0, _rand(800.0, 1200.0), _rand(0.3, 0.45), 0.7)
	return {
		"channels": [impact, resonance],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.15},
	}


static func preset_step_stone() -> Dictionary:
	var click: Dictionary = _hp_noise_transient(0.015, _rand(2000.0, 3000.0), 0.3, 0.45, 0.65)
	var body: Dictionary = _tonal_body(
		4, _rand(200.0, 350.0), _rand(0.04, 0.08),
		1, 0.0, 0.2, _rand(600.0, 900.0), _rand(0.35, 0.5), 0.7)
	return {
		"channels": [click, body],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.2},
	}


static func preset_step_metal() -> Dictionary:
	var ring: Dictionary = _ch({
		"mode": 3, "pitch": _rand(900.0, 1400.0),
		"length": _rand(0.05, 0.1), "voice": 2, "detune": 0.04,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(2000.0, 3500.0), "filterRes": _rand(0.3, 0.5),
		"delayEnabled": true,
		"delayTime": _rand(20.0, 50.0), "delayFeedback": _rand(0.2, 0.4), "delayMix": 0.3,
		"volume": _rand(0.35, 0.5), "level": 0.8,
	})
	ring.merge(ENV_DECAY_ONLY, true)
	var click: Dictionary = _hp_noise_transient(0.01, _rand(3000.0, 5000.0), 0.2, 0.4, 0.55)
	return {
		"channels": [click, ring],
		"master": {"masterVolume": 1.0, "reverbMix": 0.1, "reverbSize": 0.25},
	}


static func preset_step_water() -> Dictionary:
	var splash: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0,
		"length": _rand(0.1, 0.18), "voice": 1,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(0.4, 0.6), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.5,
		"volume": _rand(0.35, 0.5), "level": 0.85,
	})
	var bubble: Dictionary = _ch({
		"mode": 3, "pitch": _rand(300.0, 500.0),
		"length": 0.08, "voice": 1,
		"volume": 0.25, "level": 0.4,
	})
	bubble.merge(ENV_DECAY_ONLY, true)
	bubble.merge(_pitch_env_rise(_rand(0.3, 0.5), 0.6), true)
	return {
		"channels": [splash, bubble],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.2},
	}


static func preset_land() -> Dictionary:
	var thud: Dictionary = _tonal_body(
		_pick([0, 3]), _rand(80.0, 150.0), _rand(0.1, 0.18),
		1, 0.0, 0.0, _rand(400.0, 700.0), _rand(0.45, 0.6), 0.85)
	thud.merge(_pitch_env_decay(_rand(-0.4, -0.2), _rand(0.4, 0.6)), true)
	var dust: Dictionary = _lp_noise_tail(
		0.08, 500.0, 0.25, -0.2, 0.4, 0.3, 0.45)
	return {
		"channels": [
			_hp_noise_transient(0.015, 2000.0, 0.15, 0.4, 0.55),
			thud,
			dust,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.06, "reverbSize": 0.15},
	}


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
