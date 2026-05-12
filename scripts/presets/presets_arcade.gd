class_name PresetsArcade
extends PresetsHelpers

# Classic single-channel arcade SFX. All "patch" presets — they mutate the
# active channel's params, respecting the user's lock map.


static func preset_jump() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": _pick([0, 1]),
		"pitch": _rand(200.0, 500.0),
		"length": _rand(0.15, 0.35),
		"voice": 1, "detune": 0.0,
		"volume": 0.6, "level": 0.85,
	})
	body.merge(ENV_DECAY_ONLY, true)
	body.merge(_pitch_env_rise(_rand(0.3, 0.6), _rand(0.5, 1.0)), true)
	return {
		"channels": [
			_hp_noise_transient(0.02, 2500.0, 0.1, 0.4, 0.5),
			body,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.15},
	}


static func preset_shoot() -> Dictionary:
	var beam: Dictionary = _ch({
		"mode": _pick([1, 3]),
		"pitch": _rand(600.0, 1200.0),
		"length": _rand(0.1, 0.25),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.05),
		"volume": 0.5, "level": 0.85,
	})
	beam.merge(ENV_DECAY_ONLY, true)
	beam.merge(_pitch_env_decay(_rand(0.4, 0.8), _rand(0.6, 1.0)), true)
	return {
		"channels": [
			_hp_noise_transient(0.025, 3500.0, 0.12, 0.5, 0.6),
			beam,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.15},
	}


static func preset_hit() -> Dictionary:
	var body: Dictionary = _tonal_body(
		_pick([0, 1]), _rand(100.0, 200.0), _rand(0.08, 0.2),
		1, 0.0, 0.3, 600.0, 0.5, 0.75)
	body.merge(_pitch_env_decay(_rand(-0.15, -0.05), 0.5), true)
	return {
		"channels": [
			_hp_noise_transient(0.03, _rand(2000.0, 3000.0), 0.15, 0.55, 0.7),
			body,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.1},
	}


static func preset_coin() -> Dictionary:
	var chime: Dictionary = _ch({
		"mode": 0,
		"pitch": _rand(800.0, 1100.0),
		"length": _rand(0.15, 0.25),
		"voice": 1,
		"arpEnabled": true,
		"arpRate": _rand(15.0, 25.0),
		"arpStep1": _pick([5, 7]), "arpStep2": _pick([5, 7]), "arpStep3": _pick([5, 7]),
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.2, "ampRelease": 0.3,
		"volume": 0.5, "level": 0.85,
	})
	var shimmer: Dictionary = _ch({
		"mode": 3,
		"pitch": _rand(1600.0, 2200.0),
		"length": 0.12,
		"voice": 2, "detune": 0.06,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.0, "ampRelease": 0.3,
		"volume": 0.3, "level": 0.5,
	})
	return {
		"channels": [chime, shimmer],
		"master": {"masterVolume": 1.0, "reverbMix": 0.15, "reverbSize": 0.25},
	}


static func preset_explode() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": 4, "pitch": _rand(60.0, 120.0), "length": _rand(0.6, 1.0),
		"voice": 3, "detune": 0.1,
		"ampAttack": 0.0, "ampDecay": 0.8, "ampSustain": 0.1, "ampRelease": 0.2,
		"driveEnabled": true, "driveAmount": 0.7, "driveMix": 1.0,
		"filterEnabled": true, "filterType": 0, "filterCutoff": 400.0, "filterRes": 0.3,
		"filterEnv": 0.5, "filterAttack": 0.0, "filterDecay": 0.7,
		"volume": 0.6, "level": 0.9,
	})
	body.merge(_pitch_env_decay(0.4, 0.9), true)
	return {
		"channels": [
			_hp_noise_transient(0.06, 1800.0, 0.15, 0.7, 0.8),
			body,
			_lp_noise_tail(0.8, 300.0, 0.4, 0.6, 0.8, 0.5, 0.7),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.25, "reverbSize": 0.6},
	}


static func preset_powerup() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": _pick([0, 1]),
		"pitch": _rand(300.0, 500.0),
		"length": _rand(0.4, 0.7),
		"voice": 1,
		"ampAttack": 0.15, "ampDecay": 0.2, "ampSustain": 0.7, "ampRelease": 0.4,
		"arpEnabled": true,
		"arpRate": _rand(12.0, 20.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"volume": 0.55, "level": 0.85,
	})
	var sweep: Dictionary = _resonant_sweep(
		0.5, _rand(2500.0, 4000.0), 0.35, 0.5, 0.6, 0.3, 0.5)
	return {
		"channels": [body, sweep],
		"master": {"masterVolume": 1.0, "reverbMix": 0.12, "reverbSize": 0.3},
	}


static func preset_blip(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(800.0, 1500.0),
		"length": _rand(0.05, 0.1),
		"voice": 1, "detune": 0.0,
		"volume": 0.4,
	}))


static func preset_laser() -> Dictionary:
	var beam: Dictionary = _ch({
		"mode": _pick([1, 3]), "pitch": _rand(900.0, 1400.0), "length": 0.25,
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.6, "ampSustain": 0.0, "ampRelease": 0.3,
		"delayEnabled": true,
		"delayTime": _rand(60.0, 100.0), "delayFeedback": 0.4, "delayMix": 0.35,
		"volume": 0.5, "level": 0.85,
	})
	beam.merge(_pitch_env_decay(_rand(-0.9, -0.5), 0.9), true)
	return {
		"channels": [
			_hp_noise_transient(0.03, 3000.0, 0.1, 0.5, 0.6),
			beam,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.2},
	}


# Alarm: tremolo on a sustained tone — alarms don't decay, they nag.
static func preset_alarm(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(600.0, 900.0),
		"length": _rand(0.7, 1.2),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.05, "ampDecay": 0.1, "ampSustain": 0.9, "ampRelease": 0.15,
		"tremEnabled": true,
		"tremDepth": _rand(0.7, 1.0), "tremShape": _pick([0, 3]), "tremRate": _rand(4.0, 8.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": 0.45,
	}))


static func preset_chirp(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(800.0, 1200.0),
		"length": _rand(0.1, 0.2),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.3, 0.5), "pitchAttack": 0.0, "pitchDecay": _rand(0.2, 0.4),
		"volume": 0.5,
	}))


static func preset_thud(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(60.0, 150.0),
		"length": _rand(0.1, 0.2),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.1, 0.0), "pitchAttack": 0.0, "pitchDecay": _rand(0.3, 0.6),
		"volume": 0.6,
	}))


static func preset_boing(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([2, 3]),
		"pitch": _rand(200.0, 400.0),
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.01, "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.55,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.2, 0.4), "pitchAttack": 0.0, "pitchDecay": _rand(0.7, 1.0),
		"vibEnabled": true,
		"pitchMod": _rand(0.15, 0.3), "modShape": 3, "modRate": _rand(15.0, 25.0),
		"modAttack": 0.0, "modDecay": _rand(0.7, 1.0),
		"volume": 0.5,
	}))


static func preset_step(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(100.0, 300.0),
		"length": _rand(0.05, 0.1),
		"voice": 1, "detune": 0.0,
		"volume": _rand(0.3, 0.5),
	}))


static func preset_zap() -> Dictionary:
	var buzz: Dictionary = _ch({
		"mode": 1,
		"pitch": _rand(1000.0, 2000.0),
		"length": _rand(0.15, 0.3),
		"voice": 1,
		"vibEnabled": true,
		"pitchMod": _rand(0.2, 0.4), "modShape": _pick([0, 1]), "modRate": _rand(20.0, 30.0),
		"modAttack": 0.0, "modDecay": 1.0,
		"crushEnabled": true,
		"crushBits": _rand_int(4, 8), "crushRate": 1,
		"volume": 0.5, "level": 0.85,
	})
	buzz.merge(ENV_DECAY_ONLY, true)
	buzz.merge(_pitch_env_decay(_rand(-0.6, -0.3), _rand(0.6, 1.0)), true)
	return {
		"channels": [
			_hp_noise_transient(0.02, 4000.0, 0.1, 0.4, 0.5),
			buzz,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.1},
	}


static func preset_bubble(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(200.0, 400.0),
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.05, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.5,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.5, 0.8), "pitchAttack": _rand(0.5, 0.8), "pitchDecay": 0.0,
		"volume": 0.45,
	}))


static func preset_whoosh() -> Dictionary:
	var sweep: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0,
		"length": _rand(0.3, 0.5), "voice": 1,
		"ampAttack": 0.02, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(150.0, 250.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.6, 0.85), "filterAttack": 0.0, "filterDecay": _rand(0.7, 0.9),
		"volume": 0.45, "level": 0.85,
	})
	var sub: Dictionary = _tonal_body(
		3, _rand(80.0, 120.0), _rand(0.2, 0.35),
		1, 0.0, 0.0, 300.0, 0.35, 0.5)
	return {
		"channels": [sweep, sub],
		"master": {"masterVolume": 1.0, "reverbMix": 0.1, "reverbSize": 0.2},
	}


static func preset_wub(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(80.0, 130.0),
		"length": _rand(0.35, 0.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.1, "ampSustain": 0.7, "ampRelease": 0.3,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(180.0, 240.0), "filterRes": _rand(0.75, 0.9),
		"filterEnv": _rand(0.4, 0.6), "filterAttack": _rand(0.25, 0.4), "filterDecay": _rand(0.5, 0.7),
		"volume": 0.5,
	}))


static func preset_growl() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": 1,
		"pitch": _rand(90.0, 130.0),
		"length": _rand(0.4, 0.6),
		"voice": _rand_int(2, 3), "detune": _rand(0.04, 0.08),
		"ampAttack": 0.01, "ampDecay": 0.2, "ampSustain": 0.6, "ampRelease": 0.4,
		"driveEnabled": true,
		"driveAmount": _rand(0.5, 0.8), "driveMix": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(-0.3, 0.0), "filterAttack": 0.0, "filterDecay": _rand(0.6, 1.0),
		"volume": 0.45, "level": 0.85,
	})
	return {
		"channels": [
			_lp_noise_tail(0.3, 500.0, 0.35, -0.2, 0.5, 0.35, 0.5),
			body,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.2},
	}
