class_name PresetsMagic
extends PresetsHelpers

# Fantasy-style spell sounds. These layer arpeggios, vibrato, and pitch
# envelopes more aggressively than ARCADE one-shots so each spell has a
# recognisable "shape".


# Cast: 3ch — noise shimmer + arpeggiated sine body + HP sparkle tail.
static func preset_cast() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": 3, "pitch": _rand(400.0, 600.0), "length": 0.5, "voice": 1,
		"arpEnabled": true,
		"arpRate": _rand(14.0, 20.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"ampAttack": 0.08, "ampDecay": 0.2, "ampSustain": 0.6, "ampRelease": 0.4,
		"volume": 0.45, "level": 0.85,
	})
	return {
		"channels": [
			_resonant_sweep(0.15, _rand(2000.0, 3500.0), 0.4, -0.5, 0.4, 0.35, 0.6),
			body,
			_hp_noise_transient(0.3, _rand(3000.0, 5000.0), 0.3, 0.3, 0.45),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.2, "reverbSize": 0.4},
	}


# Sparkle: short high vibrato'd tone — fairy dust / pickup glint / item-found.
static func preset_sparkle(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(1500.0, 2500.0),
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"vibEnabled": true,
		"pitchMod": _rand(0.15, 0.3), "modShape": 3, "modRate": _rand(25.0, 40.0),
		"modAttack": 0.0, "modDecay": _rand(0.6, 1.0),
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.5,
		"volume": 0.4,
	}))


# Heal: gentle detuned chord that slightly rises — warm and sustained.
static func preset_heal(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(350.0, 500.0),
		"length": _rand(0.5, 0.7),
		"voice": _rand_int(2, 3), "detune": _rand(0.04, 0.07),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.15, 0.25), "pitchAttack": _rand(0.4, 0.6), "pitchDecay": 0.0,
		"ampAttack": _rand(0.08, 0.15), "ampDecay": 0.2, "ampSustain": 0.7, "ampRelease": 0.5,
		"volume": 0.45,
	}))


# Buff: ascending chime arp on a sine — uplift / blessing / power-up.
static func preset_buff(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(300.0, 450.0),
		"length": _rand(0.5, 0.7),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(12.0, 18.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"ampAttack": _rand(0.08, 0.15), "ampDecay": 0.15, "ampSustain": 0.8, "ampRelease": 0.4,
		"volume": 0.4,
	}))


# Debuff: descending dark arp + drive — sapping / curse / wither.
static func preset_debuff(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(200.0, 300.0),
		"length": _rand(0.5, 0.7),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(10.0, 14.0),
		"arpStep1": -3, "arpStep2": -7, "arpStep3": -12,
		"driveEnabled": true, "driveAmount": _rand(0.25, 0.4), "driveMix": 0.8,
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.5, "ampRelease": 0.5,
		"volume": 0.45,
	}))


# Teleport: 3ch — HP noise phase-in + filtered sweep body + delay tail.
static func preset_teleport() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": 1, "pitch": _rand(800.0, 1200.0), "length": 0.4, "voice": 1,
		"ampAttack": 0.08, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(0.6, 0.85), "filterAttack": 0.15, "filterDecay": 0.5,
		"volume": 0.45, "level": 0.8,
	})
	var tail: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0, "length": 0.5, "voice": 1,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": 500.0, "filterRes": 0.3,
		"filterEnv": -0.3, "filterAttack": 0.0, "filterDecay": 0.6,
		"delayEnabled": true,
		"delayTime": _rand(80.0, 150.0), "delayFeedback": _rand(0.3, 0.5), "delayMix": 0.5,
		"volume": 0.35, "level": 0.55,
	})
	tail.merge(ENV_DECAY_ONLY, true)
	return {
		"channels": [
			_hp_noise_transient(0.08, _rand(2000.0, 3000.0), 0.35, 0.45, 0.7),
			body,
			tail,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.25, "reverbSize": 0.5},
	}


# Freeze: high crystalline tone with rapid vibrato + short delay.
static func preset_freeze(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(1800.0, 2400.0),
		"length": _rand(0.25, 0.4),
		"voice": 1, "detune": 0.0,
		"vibEnabled": true,
		"pitchMod": _rand(0.2, 0.4), "modShape": 3, "modRate": _rand(40.0, 60.0),
		"modAttack": 0.0, "modDecay": _rand(0.5, 0.8),
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2200.0), "filterRes": 0.3,
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"delayEnabled": true,
		"delayTime": _rand(40.0, 80.0), "delayFeedback": _rand(0.25, 0.4), "delayMix": 0.3,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.5,
		"volume": 0.4,
	}))


# Fire whoosh: 3ch — HP noise ignition + driven noise roar + LP crackle tail.
static func preset_fire_whoosh() -> Dictionary:
	var roar: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0, "length": 0.5, "voice": 1,
		"ampAttack": 0.1, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.5,
		"driveEnabled": true, "driveAmount": _rand(0.3, 0.5), "driveMix": 1.0,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": _rand(180.0, 300.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.6, 0.85), "filterAttack": 0.2, "filterDecay": 0.5,
		"volume": 0.45, "level": 0.85,
	})
	return {
		"channels": [
			_hp_noise_transient(0.06, _rand(2500.0, 4000.0), 0.3, 0.5, 0.7),
			roar,
			_lp_noise_tail(0.6, 350.0, 0.4, -0.3, 0.7, 0.35, 0.5),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.15, "reverbSize": 0.3},
	}


# Shield-break: bright HP-filtered noise burst with delay tails.
static func preset_shield_break(params: Dictionary, locked: Dictionary) -> Dictionary:
	var t: Dictionary = _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.25, 0.4),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1800.0, 2800.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"delayEnabled": true,
		"delayTime": _rand(50.0, 90.0), "delayFeedback": _rand(0.4, 0.6), "delayMix": 0.5,
		"volume": 0.5,
	})
	t.merge(ENV_DECAY_ONLY, true)
	return _apply_target(params, locked, t)


# Summon: 3ch — sub rumble body + driven saw swell + noise shimmer.
static func preset_summon() -> Dictionary:
	var sub: Dictionary = _ch({
		"mode": 3, "pitch": _rand(40.0, 65.0), "length": 0.8, "voice": 1,
		"ampAttack": 0.2, "ampDecay": 0.3, "ampSustain": 0.6, "ampRelease": 0.4,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": 200.0, "filterRes": 0.3,
		"volume": 0.5, "level": 0.7,
	})
	var swell: Dictionary = _ch({
		"mode": 1, "pitch": _rand(60.0, 100.0), "length": 0.9,
		"voice": _rand_int(2, 3), "detune": _rand(0.05, 0.08),
		"ampAttack": 0.2, "ampDecay": 0.3, "ampSustain": 0.6, "ampRelease": 0.4,
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 1.0,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": _rand(600.0, 1000.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(0.3, 0.5), "filterAttack": 0.4, "filterDecay": 0.5,
		"volume": 0.45, "level": 0.85,
	})
	swell.merge(_pitch_env_rise(0.3, 0.6), true)
	return {
		"channels": [
			sub,
			swell,
			_resonant_sweep(0.7, _rand(2000.0, 3500.0), 0.35, 0.4, 0.6, 0.3, 0.5),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.25, "reverbSize": 0.55},
	}
