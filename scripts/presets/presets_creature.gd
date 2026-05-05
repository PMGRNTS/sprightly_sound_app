class_name PresetsCreature
extends PresetsHelpers

# Animal / monster vocalisations. Most use voice + detune for body, plus
# vibrato or arp for character. Pitch sits in the mid range and the LP
# filter tames noise modes into something more "throaty".


# Yelp: short rising-then-falling cry — small creature in pain.
static func preset_yelp(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([2, 3]),
		"pitch": _rand(700.0, 1100.0),
		"length": _rand(0.1, 0.18),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.4, 0.7), "pitchAttack": _rand(0.15, 0.3), "pitchDecay": _rand(0.4, 0.6),
		"vibEnabled": true,
		"pitchMod": _rand(0.05, 0.12), "modShape": 3, "modRate": _rand(20.0, 35.0),
		"modAttack": 0.0, "modDecay": 1.0,
		"volume": 0.5,
	}))


# Hurt: gruff mid-range grunt with drive — generic "took damage".
static func preset_hurt(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 1,
		"pitch": _rand(150.0, 250.0),
		"length": _rand(0.15, 0.25),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.05),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.3, -0.1), "pitchAttack": 0.0, "pitchDecay": _rand(0.5, 0.7),
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 0.9,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1300.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.4,
		"volume": 0.5,
	}))


# Death: descending, longer — "I am dying" voice trail.
static func preset_death(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([1, 2]),
		"pitch": _rand(200.0, 350.0),
		"length": _rand(0.5, 0.8),
		"voice": _rand_int(1, 2), "detune": _rand(0.02, 0.05),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.7, -0.4), "pitchAttack": 0.0, "pitchDecay": _rand(0.7, 1.0),
		"driveEnabled": true, "driveAmount": _rand(0.3, 0.5), "driveMix": 0.8,
		"ampAttack": _rand(0.02, 0.06), "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.6,
		"volume": 0.5,
	}))


# Idle: short ambient grunt — creature sitting around between actions.
static func preset_idle(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([1, 2]),
		"pitch": _rand(120.0, 200.0),
		"length": _rand(0.2, 0.35),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.04),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.15, 0.15), "pitchAttack": _rand(0.2, 0.5), "pitchDecay": _rand(0.4, 0.7),
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(500.0, 900.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": _rand(0.05, 0.15), "ampDecay": 0.3, "ampSustain": 0.5, "ampRelease": 0.4,
		"volume": 0.4,
	}))


# Roar: long sustained low growl with heavy drive — boss / dragon / bear.
static func preset_roar(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 1,
		"pitch": _rand(70.0, 120.0),
		"length": _rand(0.7, 1.2),
		"voice": _rand_int(2, 3), "detune": _rand(0.05, 0.1),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.1, 0.25), "pitchAttack": _rand(0.3, 0.5), "pitchDecay": 0.0,
		"driveEnabled": true, "driveAmount": _rand(0.6, 0.85), "driveMix": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(700.0, 1200.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(0.1, 0.3), "filterAttack": _rand(0.2, 0.4), "filterDecay": _rand(0.5, 0.8),
		"ampAttack": _rand(0.1, 0.2), "ampDecay": 0.3, "ampSustain": 0.7, "ampRelease": 0.5,
		"volume": 0.5,
	}))


# Chitter: rapid arpeggio on a high tone — small rodent / insect chatter.
static func preset_chitter(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(1500.0, 2200.0),
		"length": _rand(0.15, 0.3),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(30.0, 50.0),
		"arpStep1": _pick([0, 3, 5]), "arpStep2": _pick([0, 5, 7]), "arpStep3": _pick([3, 5, 7]),
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.4,
		"volume": 0.4,
	}))


# Squeak: very brief high vibrato — mouse / bat / pinched toy.
static func preset_squeak(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([2, 3]),
		"pitch": _rand(2000.0, 3000.0),
		"length": _rand(0.06, 0.12),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.2, 0.5), "pitchAttack": _rand(0.2, 0.4), "pitchDecay": _rand(0.4, 0.6),
		"vibEnabled": true,
		"pitchMod": _rand(0.1, 0.25), "modShape": 3, "modRate": _rand(40.0, 70.0),
		"modAttack": 0.0, "modDecay": 1.0,
		"volume": 0.4,
	}))


# Flap: rhythmic noise tremolo — wings beating, cape flapping.
static func preset_flap(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"tremEnabled": true,
		"tremDepth": _rand(0.6, 0.9), "tremShape": _pick([0, 3]), "tremRate": _rand(8.0, 14.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": _rand(0.03, 0.08), "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.4,
		"volume": 0.45,
	}))


# Slither: sustained LP-filtered noise — snake on dirt, serpent emerging.
static func preset_slither(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.6, 1.0),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.1, 0.2), "ampDecay": 0.4, "ampSustain": 0.5, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(200.0, 350.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(0.3, 0.5), "filterAttack": _rand(0.2, 0.5), "filterDecay": _rand(0.5, 0.8),
		"tremEnabled": true,
		"tremDepth": _rand(0.3, 0.5), "tremShape": 3, "tremRate": _rand(3.0, 6.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": 0.4,
	}))
