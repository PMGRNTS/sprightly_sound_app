class_name PresetsAmbient
extends PresetsHelpers

# Sustained / textural sounds. Length defaults toward the long end
# (1–3 s) so each render is loop-tile-sized — for true infinite loops,
# extend via the LENGTH slider and crossfade-loop in the game engine.


# Wind: sustained LP-filtered noise with slow tremolo — outdoor ambience.
static func preset_wind(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(1.5, 2.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.2, 0.4), "ampDecay": 0.3, "ampSustain": 0.7, "ampRelease": _rand(0.3, 0.5),
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(250.0, 450.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.2, 0.2), "filterAttack": _rand(0.3, 0.6), "filterDecay": _rand(0.4, 0.7),
		"tremEnabled": true,
		"tremDepth": _rand(0.2, 0.4), "tremShape": 3, "tremRate": _rand(0.8, 2.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": 0.4,
	}))


# Rain: HP-filtered noise — softer / brighter than wind.
static func preset_rain(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(1.5, 2.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.15, 0.3), "ampDecay": 0.2, "ampSustain": 0.8, "ampRelease": _rand(0.3, 0.5),
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": 0.35,
	}))


# Fire crackle: noise + bit-crush + irregular tremolo — campfire pop.
static func preset_fire_crackle(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(1.0, 2.0),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.15), "ampDecay": 0.3, "ampSustain": 0.7, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1400.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"tremEnabled": true,
		"tremDepth": _rand(0.6, 0.9), "tremShape": 4, "tremRate": _rand(20.0, 35.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"crushEnabled": true,
		"crushBits": _rand_int(6, 10), "crushRate": _rand_int(2, 5),
		"volume": 0.4,
	}))


# Electric hum: low square + drive — neon sign / mains hum / generator.
static func preset_electric_hum(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _pick([60.0, 120.0, 240.0]),
		"length": _rand(1.5, 2.5),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.02),
		"ampAttack": _rand(0.1, 0.2), "ampDecay": 0.2, "ampSustain": 0.85, "ampRelease": _rand(0.3, 0.5),
		"driveEnabled": true, "driveAmount": _rand(0.2, 0.4), "driveMix": 0.7,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(700.0, 1200.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"tremEnabled": true,
		"tremDepth": _rand(0.1, 0.25), "tremShape": 3, "tremRate": _rand(110.0, 130.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": 0.35,
	}))


# Water drip: solitary high vibrato'd sine — cave drip, leaky pipe.
static func preset_water_drip(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(1200.0, 1800.0),
		"length": _rand(0.2, 0.35),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.3, -0.1), "pitchAttack": 0.0, "pitchDecay": _rand(0.4, 0.6),
		"vibEnabled": true,
		"pitchMod": _rand(0.05, 0.15), "modShape": 3, "modRate": _rand(15.0, 25.0),
		"modAttack": 0.0, "modDecay": _rand(0.5, 0.8),
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.0, "ampRelease": 0.5,
		"volume": 0.4,
	}))


# Engine idle: low square + slow tremolo — vehicle engine idling.
static func preset_engine_idle(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(60.0, 100.0),
		"length": _rand(1.5, 2.5),
		"voice": _rand_int(2, 3), "detune": _rand(0.05, 0.08),
		"ampAttack": _rand(0.15, 0.3), "ampDecay": 0.2, "ampSustain": 0.85, "ampRelease": _rand(0.3, 0.5),
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 0.9,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"tremEnabled": true,
		"tremDepth": _rand(0.2, 0.4), "tremShape": 3, "tremRate": _rand(8.0, 15.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": 0.4,
	}))
