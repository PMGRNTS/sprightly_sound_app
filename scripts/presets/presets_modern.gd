class_name PresetsModern
extends PresetsHelpers

# Modern shooter / RPG game cues — heartbeat, low-health alerts, weapon
# handling clicks. Lean toward realism rather than chiptune.


# Heartbeat: 2ch — sub sine thump + filtered noise body resonance.
static func preset_heartbeat() -> Dictionary:
	var thump: Dictionary = _ch({
		"mode": 3, "pitch": _rand(50.0, 75.0), "length": 0.25, "voice": 1,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": _rand(150.0, 250.0), "filterRes": _rand(0.3, 0.5),
		"volume": 0.55, "level": 0.9,
	})
	thump.merge(ENV_DECAY_ONLY, true)
	var body: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0, "length": 0.35, "voice": 1,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": 300.0, "filterRes": 0.5,
		"filterEnv": -0.3, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": 0.35, "level": 0.55,
	})
	body.merge(ENV_DECAY_ONLY, true)
	return {
		"channels": [thump, body],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.2},
	}


static func preset_low_health() -> Dictionary:
	var pulse: Dictionary = _ch({
		"mode": 0,
		"pitch": _rand(180.0, 280.0),
		"length": _rand(0.3, 0.5), "voice": 1,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 2, "filterCutoff": _rand(700.0, 1200.0), "filterRes": _rand(0.55, 0.75),
		"filterEnv": _rand(-0.3, 0.0), "filterAttack": 0.0, "filterDecay": _rand(0.4, 0.6),
		"tremEnabled": true,
		"tremDepth": _rand(0.4, 0.6), "tremShape": 3, "tremRate": _rand(2.5, 4.5),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": _rand(0.4, 0.55), "level": 0.85,
	})
	var sub: Dictionary = _ch({
		"mode": 3, "pitch": _rand(50.0, 70.0),
		"length": 0.25, "voice": 1,
		"filterEnabled": true, "filterType": 0,
		"filterCutoff": 200.0, "filterRes": 0.3,
		"volume": 0.4, "level": 0.6,
	})
	sub.merge(ENV_DECAY_ONLY, true)
	return {
		"channels": [pulse, sub],
		"master": {"masterVolume": 1.0, "reverbMix": 0.1, "reverbSize": 0.2},
	}


# Reload: 3ch — HP noise click + sine ping ring + LP noise slide.
static func preset_reload() -> Dictionary:
	var ping: Dictionary = _ch({
		"mode": 3, "pitch": _rand(1200.0, 2000.0), "length": 0.15, "voice": 1,
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.2, "ampRelease": 0.5,
		"filterEnabled": true, "filterType": 1,
		"filterCutoff": _rand(1500.0, 2500.0), "filterRes": 0.4,
		"volume": 0.4, "level": 0.7,
	})
	return {
		"channels": [
			_hp_noise_transient(0.03, _rand(3000.0, 5000.0), 0.25, 0.5, 0.8),
			ping,
			_lp_noise_tail(0.12, 800.0, 0.3, -0.3, 0.4, 0.35, 0.5),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.15},
	}


# Empty chamber: dry click — out-of-ammo / wrong-key feedback.
static func preset_empty_chamber(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(800.0, 1200.0),
		"length": _rand(0.04, 0.07),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(2500.0, 3500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.35, 0.5),
	}))


# Switch weapon: crisp slide — weapon swap / inventory tab change.
static func preset_switch_weapon(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.1, 0.18),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.3, 0.6), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"volume": _rand(0.35, 0.5),
	}))


static func preset_cover_enter() -> Dictionary:
	var whoosh: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0,
		"length": _rand(0.15, 0.25), "voice": 1,
		"ampAttack": _rand(0.03, 0.08), "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.4, -0.2), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"volume": _rand(0.35, 0.5), "level": 0.85,
	})
	var thud: Dictionary = _tonal_body(
		0, _rand(60.0, 100.0), 0.06, 1, 0.0, 0.0, 300.0, 0.35, 0.5)
	return {
		"channels": [whoosh, thud],
		"master": {"masterVolume": 1.0, "reverbMix": 0.06, "reverbSize": 0.15},
	}
