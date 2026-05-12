class_name PresetsMusicUI
extends PresetsHelpers

# Stingers, transitions, and short musical cues. Use arpeggios with
# major / minor triads to convey mood.


static func preset_stinger_win() -> Dictionary:
	var melody: Dictionary = _ch({
		"mode": _pick([0, 3]), "pitch": _rand(440.0, 523.0), "length": 0.45,
		"voice": 1,
		"ampAttack": 0.0, "ampDecay": 0.2, "ampSustain": 0.6, "ampRelease": 0.5,
		"arpEnabled": true,
		"arpRate": 18.0, "arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"volume": 0.5, "level": 0.85,
	})
	var pad: Dictionary = _ch({
		"mode": 3, "pitch": _rand(220.0, 261.0), "length": 0.5,
		"voice": 3, "detune": 0.06,
		"ampAttack": 0.05, "ampDecay": 0.2, "ampSustain": 0.5, "ampRelease": 0.6,
		"filterEnabled": true, "filterType": 0, "filterCutoff": 3000.0, "filterRes": 0.1,
		"volume": 0.3, "level": 0.65,
	})
	return {
		"channels": [melody, pad],
		"master": {"masterVolume": 1.0, "reverbMix": 0.35, "reverbSize": 0.5},
	}


static func preset_stinger_lose() -> Dictionary:
	var melody: Dictionary = _ch({
		"mode": _pick([0, 1]),
		"pitch": _rand(300.0, 450.0),
		"length": _rand(0.4, 0.6),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.04),
		"arpEnabled": true,
		"arpRate": _rand(8.0, 14.0),
		"arpStep1": -3, "arpStep2": -5, "arpStep3": -10,
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.5, "ampRelease": 0.5,
		"volume": _rand(0.4, 0.55), "level": 0.85,
	})
	var sub: Dictionary = _ch({
		"mode": 3, "pitch": _rand(100.0, 150.0),
		"length": 0.5, "voice": 2, "detune": 0.05,
		"ampAttack": 0.1, "ampDecay": 0.2, "ampSustain": 0.4, "ampRelease": 0.6,
		"filterEnabled": true, "filterType": 0, "filterCutoff": 500.0, "filterRes": 0.15,
		"volume": 0.3, "level": 0.55,
	})
	return {
		"channels": [melody, sub],
		"master": {"masterVolume": 1.0, "reverbMix": 0.3, "reverbSize": 0.5},
	}


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


static func preset_fanfare() -> Dictionary:
	var melody: Dictionary = _ch({
		"mode": _pick([0, 3]),
		"pitch": _rand(350.0, 500.0),
		"length": _rand(0.6, 0.9),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.03),
		"arpEnabled": true,
		"arpRate": _rand(16.0, 24.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"ampAttack": _rand(0.02, 0.06), "ampDecay": 0.2, "ampSustain": 0.7, "ampRelease": 0.5,
		"volume": _rand(0.45, 0.6), "level": 0.85,
	})
	var pad: Dictionary = _ch({
		"mode": 3, "pitch": _rand(175.0, 250.0),
		"length": 0.7, "voice": 3, "detune": 0.06,
		"ampAttack": 0.08, "ampDecay": 0.15, "ampSustain": 0.6, "ampRelease": 0.6,
		"filterEnabled": true, "filterType": 0, "filterCutoff": 2500.0, "filterRes": 0.1,
		"volume": 0.3, "level": 0.6,
	})
	return {
		"channels": [melody, pad],
		"master": {"masterVolume": 1.0, "reverbMix": 0.35, "reverbSize": 0.5},
	}
