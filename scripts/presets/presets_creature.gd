class_name PresetsCreature
extends PresetsHelpers

# Animal / monster vocalisations. Most use voice + detune for body, plus
# vibrato or arp for character. Pitch sits in the mid range and the LP
# filter tames noise modes into something more "throaty".


static func preset_yelp() -> Dictionary:
	var cry: Dictionary = _ch({
		"mode": _pick([2, 3]),
		"pitch": _rand(700.0, 1100.0),
		"length": _rand(0.1, 0.18),
		"voice": 1,
		"vibEnabled": true,
		"pitchMod": _rand(0.05, 0.12), "modShape": 3, "modRate": _rand(20.0, 35.0),
		"modAttack": 0.0, "modDecay": 1.0,
		"volume": 0.5, "level": 0.85,
	})
	cry.merge(ENV_DECAY_ONLY, true)
	cry.merge(_pitch_env_rise(_rand(0.4, 0.7), _rand(0.15, 0.3)), true)
	return {
		"channels": [
			_hp_noise_transient(0.015, 3000.0, 0.1, 0.35, 0.45),
			cry,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.15},
	}


static func preset_hurt() -> Dictionary:
	var impact: Dictionary = _ch({
		"mode": 4, "pitch": 800.0, "length": 0.04,
		"voice": 1,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"filterEnabled": true, "filterType": 1, "filterCutoff": 2500.0, "filterRes": 0.15,
		"volume": 0.55, "level": 0.7,
	})
	var grunt: Dictionary = _ch({
		"mode": 1, "pitch": _rand(150.0, 220.0), "length": 0.2,
		"voice": 2, "detune": 0.04,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.4,
		"driveEnabled": true, "driveAmount": 0.5, "driveMix": 0.9,
		"filterEnabled": true, "filterType": 0, "filterCutoff": 1000.0, "filterRes": 0.3,
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": 0.5, "level": 0.85,
	})
	grunt.merge(_pitch_env_decay(-0.2, 0.6), true)
	return {
		"channels": [impact, grunt],
		"master": {"masterVolume": 1.0, "reverbMix": 0.1, "reverbSize": 0.25},
	}


# Death: 3ch — pitched vocal + descending saw trail + noise breath tail.
static func preset_death() -> Dictionary:
	var vocal: Dictionary = _ch({
		"mode": _pick([1, 2]), "pitch": _rand(200.0, 350.0), "length": 0.6,
		"voice": _rand_int(1, 2), "detune": _rand(0.02, 0.05),
		"ampAttack": 0.03, "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.6,
		"driveEnabled": true, "driveAmount": _rand(0.3, 0.5), "driveMix": 0.8,
		"volume": 0.5, "level": 0.85,
	})
	vocal.merge(_pitch_env_decay(-0.5, 0.8), true)
	var trail: Dictionary = _ch({
		"mode": 1, "pitch": _rand(120.0, 200.0), "length": 0.8,
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.1, "ampDecay": 0.4, "ampSustain": 0.2, "ampRelease": 0.6,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": 500.0, "filterRes": 0.3,
		"filterEnv": -0.3, "filterAttack": 0.0, "filterDecay": 0.7,
		"volume": 0.4, "level": 0.65,
	})
	trail.merge(_pitch_env_decay(-0.7, 1.0), true)
	return {
		"channels": [
			vocal,
			trail,
			_lp_noise_tail(0.5, 400.0, 0.3, -0.2, 0.6, 0.3, 0.45),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.2, "reverbSize": 0.4},
	}


static func preset_idle() -> Dictionary:
	var vocal: Dictionary = _ch({
		"mode": _pick([1, 2]),
		"pitch": _rand(120.0, 200.0),
		"length": _rand(0.2, 0.35),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.04),
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(500.0, 900.0), "filterRes": _rand(0.2, 0.4),
		"ampAttack": _rand(0.05, 0.15), "ampDecay": 0.3, "ampSustain": 0.5, "ampRelease": 0.4,
		"volume": 0.4, "level": 0.85,
	})
	vocal.merge(_pitch_env_rise(_rand(-0.15, 0.15), _rand(0.2, 0.5)), true)
	var breath: Dictionary = _lp_noise_tail(
		0.15, 400.0, 0.25, -0.2, 0.4, 0.25, 0.4)
	return {
		"channels": [vocal, breath],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.2},
	}


# Roar: 3ch — noise breath transient + driven saw vocal body + sub rumble.
static func preset_roar() -> Dictionary:
	var vocal: Dictionary = _ch({
		"mode": 1, "pitch": _rand(70.0, 120.0), "length": 0.9,
		"voice": _rand_int(2, 3), "detune": _rand(0.05, 0.1),
		"ampAttack": 0.12, "ampDecay": 0.3, "ampSustain": 0.7, "ampRelease": 0.5,
		"driveEnabled": true, "driveAmount": _rand(0.6, 0.85), "driveMix": 1.0,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": _rand(700.0, 1200.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.2, "filterAttack": 0.3, "filterDecay": 0.6,
		"volume": 0.5, "level": 0.9,
	})
	vocal.merge(_pitch_env_rise(0.15, 0.4), true)
	var rumble: Dictionary = _ch({
		"mode": 3, "pitch": _rand(35.0, 55.0), "length": 1.0, "voice": 1,
		"ampAttack": 0.15, "ampDecay": 0.3, "ampSustain": 0.5, "ampRelease": 0.5,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": 180.0, "filterRes": 0.3,
		"volume": 0.45, "level": 0.65,
	})
	return {
		"channels": [
			_lp_noise_tail(0.15, 600.0, 0.4, 0.3, 0.3, 0.45, 0.6),
			vocal,
			rumble,
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.15, "reverbSize": 0.35},
	}


static func preset_chitter() -> Dictionary:
	var tone: Dictionary = _ch({
		"mode": _pick([0, 3]),
		"pitch": _rand(1500.0, 2200.0),
		"length": _rand(0.15, 0.3),
		"voice": 1,
		"arpEnabled": true,
		"arpRate": _rand(30.0, 50.0),
		"arpStep1": _pick([0, 3, 5]), "arpStep2": _pick([0, 5, 7]), "arpStep3": _pick([3, 5, 7]),
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.4,
		"volume": 0.4, "level": 0.85,
	})
	var clicks: Dictionary = _hp_noise_transient(0.08, _rand(4000.0, 6000.0), 0.2, 0.3, 0.4)
	clicks["tremEnabled"] = true
	clicks["tremDepth"] = _rand(0.7, 0.9)
	clicks["tremShape"] = 0
	clicks["tremRate"] = _rand(30.0, 50.0)
	clicks["tremAttack"] = 0.0
	clicks["tremDecay"] = 1.0
	return {
		"channels": [tone, clicks],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.1},
	}


static func preset_squeak() -> Dictionary:
	var tone: Dictionary = _ch({
		"mode": _pick([2, 3]),
		"pitch": _rand(2000.0, 3000.0),
		"length": _rand(0.06, 0.12),
		"voice": 1,
		"vibEnabled": true,
		"pitchMod": _rand(0.1, 0.25), "modShape": 3, "modRate": _rand(40.0, 70.0),
		"modAttack": 0.0, "modDecay": 1.0,
		"volume": 0.4, "level": 0.85,
	})
	tone.merge(ENV_DECAY_ONLY, true)
	tone.merge(_pitch_env_rise(_rand(0.2, 0.5), _rand(0.2, 0.4)), true)
	var pop: Dictionary = _pitched_transient(3, _rand(3000.0, 4000.0), 0.015, 0.3, 0.4)
	return {
		"channels": [pop, tone],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.1},
	}


static func preset_flap() -> Dictionary:
	var wings: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0,
		"length": _rand(0.4, 0.6), "voice": 1,
		"tremEnabled": true,
		"tremDepth": _rand(0.6, 0.9), "tremShape": _pick([0, 3]), "tremRate": _rand(8.0, 14.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.2, 0.4),
		"ampAttack": _rand(0.03, 0.08), "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.4,
		"volume": 0.45, "level": 0.85,
	})
	var thump: Dictionary = _tonal_body(
		3, _rand(60.0, 100.0), 0.04, 1, 0.0, 0.0, 0.0, 0.3, 0.4)
	return {
		"channels": [wings, thump],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.15},
	}


static func preset_slither() -> Dictionary:
	var body: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0,
		"length": _rand(0.6, 1.0), "voice": 1,
		"ampAttack": _rand(0.1, 0.2), "ampDecay": 0.4, "ampSustain": 0.5, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(200.0, 350.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(0.3, 0.5), "filterAttack": _rand(0.2, 0.5), "filterDecay": _rand(0.5, 0.8),
		"tremEnabled": true,
		"tremDepth": _rand(0.3, 0.5), "tremShape": 3, "tremRate": _rand(3.0, 6.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": 0.4, "level": 0.85,
	})
	var hiss: Dictionary = _resonant_sweep(
		0.5, _rand(4000.0, 6000.0), 0.2, -0.3, 0.6, 0.25, 0.4, 1)
	return {
		"channels": [body, hiss],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.1},
	}
