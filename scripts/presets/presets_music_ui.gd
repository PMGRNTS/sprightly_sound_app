class_name PresetsMusicUI
extends PresetsHelpers

# Stingers, transitions, and short musical cues. Use arpeggios with
# major / minor triads to convey mood.


# Stinger win: ascending major triad — victory / level complete.
static func preset_stinger_win(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(400.0, 550.0),
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(15.0, 22.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"ampAttack": 0.0, "ampDecay": 0.2, "ampSustain": 0.6, "ampRelease": 0.5,
		"volume": _rand(0.45, 0.6),
	}))


# Stinger lose: descending minor — defeat / failure.
static func preset_stinger_lose(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(300.0, 450.0),
		"length": _rand(0.4, 0.6),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.04),
		"arpEnabled": true,
		"arpRate": _rand(8.0, 14.0),
		"arpStep1": -3, "arpStep2": -5, "arpStep3": -10,
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.5, "ampRelease": 0.5,
		"volume": _rand(0.4, 0.55),
	}))


# Fade-in: slow attack of a sustained tone — scene start / music swell.
static func preset_fade_in(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(200.0, 350.0),
		"length": _rand(0.8, 1.4),
		"voice": _rand_int(2, 3), "detune": _rand(0.03, 0.06),
		"ampAttack": _rand(0.5, 0.7), "ampDecay": 0.1, "ampSustain": 0.85, "ampRelease": 0.0,
		"volume": _rand(0.35, 0.5),
	}))


# Fade-out: opposite of fade-in — release-heavy tail.
static func preset_fade_out(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(200.0, 350.0),
		"length": _rand(0.8, 1.4),
		"voice": _rand_int(2, 3), "detune": _rand(0.03, 0.06),
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.1, "ampSustain": 0.85, "ampRelease": _rand(0.6, 0.85),
		"volume": _rand(0.35, 0.5),
	}))


# Pause: short low square dip — generic "system halted" cue.
static func preset_pause(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(250.0, 400.0),
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.3, -0.15), "pitchAttack": 0.0, "pitchDecay": _rand(0.5, 0.7),
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.5, "ampRelease": 0.4,
		"volume": 0.4,
	}))


# Resume: short rising counterpart to PAUSE.
static func preset_resume(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(250.0, 400.0),
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.2, 0.4), "pitchAttack": _rand(0.3, 0.5), "pitchDecay": 0.0,
		"ampAttack": _rand(0.02, 0.06), "ampDecay": 0.3, "ampSustain": 0.6, "ampRelease": 0.4,
		"volume": 0.4,
	}))


# Fanfare: extended ascending arp — level-up / new milestone.
static func preset_fanfare(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(350.0, 500.0),
		"length": _rand(0.6, 0.9),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.03),
		"arpEnabled": true,
		"arpRate": _rand(16.0, 24.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"ampAttack": _rand(0.02, 0.06), "ampDecay": 0.2, "ampSustain": 0.7, "ampRelease": 0.5,
		"volume": _rand(0.45, 0.6),
	}))
