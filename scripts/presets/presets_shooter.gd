class_name PresetsShooter
extends PresetsHelpers

# Multi-channel "sound" presets that replace the entire Sound (rather than
# patching the active channel). Layered SFX: transient + body + tail —
# the standard recipe for impact-style sounds.


static func preset_gunshot() -> Dictionary:
	# Body: low square through drive + LP (the "thump"). Custom envelope
	# (ampDecay 0.4, not full 1.0) so the body lands tight.
	var body: Dictionary = _ch({
		"mode": 0, "pitch": 90.0, "length": 0.18, "voice": 1,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.0, "ampRelease": 0.0,
		"driveEnabled": true, "driveAmount": 0.65, "driveMix": 1.0,
		"filterEnabled": true, "filterType": 0, "filterCutoff": 900.0, "filterRes": 0.2,
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": 0.55, "level": 0.85,
	})
	body.merge(_pitch_env_decay(-0.4, 0.4), true)
	return {
		"channels": [
			_hp_noise_transient(0.04, 2000.0, 0.2, 0.6, 0.8),     # snap
			body,                                                  # thump
			_lp_noise_tail(0.22, 700.0, 0.4, 0.6, 0.7, 0.4, 0.5),  # sizzle
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.12, "reverbSize": 0.3},
	}


static func preset_heavy_gun() -> Dictionary:
	# Body: detuned dual-voice low square — heavier "thunk" than gunshot.
	var body: Dictionary = _ch({
		"mode": 0, "pitch": 55.0, "length": 0.3, "voice": 2, "detune": 0.04,
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.0, "ampRelease": 0.0,
		"driveEnabled": true, "driveAmount": 0.8, "driveMix": 1.0,
		"filterEnabled": true, "filterType": 0, "filterCutoff": 600.0, "filterRes": 0.3,
		"volume": 0.6, "level": 0.95,
	})
	body.merge(_pitch_env_decay(-0.5, 0.5), true)
	return {
		"channels": [
			_hp_noise_transient(0.05, 1500.0, 0.3, 0.65, 0.85),
			body,
			_lp_noise_tail(0.4, 500.0, 0.5, 0.7, 0.8, 0.45, 0.55),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.2, "reverbSize": 0.5},
	}


static func preset_burst() -> Dictionary:
	return {
		"channels": [
			_ch({
				"mode": 1, "pitch": _rand(700.0, 1000.0), "length": 0.18, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.2, "ampRelease": 0.5,
				"pitchEnvEnabled": true, "pitchEnv": -0.5, "pitchAttack": 0.0, "pitchDecay": 0.6,
				"driveEnabled": true, "driveAmount": 0.5, "driveMix": 1.0,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 1500.0, "filterRes": 0.5,
				"filterEnv": 0.4, "filterAttack": 0.0, "filterDecay": 0.5,
				"volume": 0.5,
			}),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.1, "reverbSize": 0.3},
	}


static func preset_dash() -> Dictionary:
	return {
		"channels": [
			_ch({
				"mode": 4, "pitch": 1000.0, "length": 0.32, "voice": 1,
				"ampAttack": 0.04, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.5,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 200.0, "filterRes": 0.4,
				"filterEnv": 0.8, "filterAttack": 0.0, "filterDecay": 0.85,
				"volume": 0.45, "level": 0.85,
			}),
			_ch({
				"mode": 3, "pitch": 80.0, "length": 0.12, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"pitchEnvEnabled": true, "pitchEnv": -0.3, "pitchAttack": 0.0, "pitchDecay": 0.5,
				"volume": 0.45, "level": 0.6,
			}),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.05, "reverbSize": 0.2},
	}


static func preset_confirm() -> Dictionary:
	var bell: Dictionary = _ch({
		"mode": 3, "pitch": 1400.0, "length": 0.1, "voice": 1,
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": 0.5, "level": 0.85,
	})
	bell.merge(_pitch_env_decay(0.15, 0.4), true)
	return {
		"channels": [
			_hp_noise_transient(0.025, 3000.0, 0.3, 0.55, 0.7),  # tick
			bell,                                                # bright bell
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.25},
	}


static func preset_headshot() -> Dictionary:
	var ring: Dictionary = _ch({
		"mode": 3, "pitch": 2200.0, "length": 0.4, "voice": 1,
		"ampAttack": 0.0, "ampDecay": 0.2, "ampSustain": 0.5, "ampRelease": 0.6,
		"volume": 0.4, "level": 0.8,
	})
	ring.merge(_pitch_env_decay(0.08, 0.3), true)
	return {
		"channels": [
			_hp_noise_transient(0.04, 4000.0, 0.4, 0.5, 0.7),  # high snap
			ring,                                              # ringing tail
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.25, "reverbSize": 0.5},
	}


static func preset_shield() -> Dictionary:
	return {
		"channels": [
			_ch({
				"mode": 0, "pitch": 350.0, "length": 0.5, "voice": 1,
				"ampAttack": 0.1, "ampDecay": 0.2, "ampSustain": 0.6, "ampRelease": 0.4,
				"arpEnabled": true, "arpRate": 14.0, "arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 1500.0, "filterRes": 0.3,
				"delayEnabled": true, "delayTime": 80.0, "delayFeedback": 0.35, "delayMix": 0.3,
				"volume": 0.45, "level": 0.85,
			}),
			_ch({
				"mode": 4, "pitch": 1000.0, "length": 0.5, "voice": 1,
				"ampAttack": 0.15, "ampDecay": 0.2, "ampSustain": 0.5, "ampRelease": 0.5,
				"filterEnabled": true, "filterType": 1, "filterCutoff": 3500.0, "filterRes": 0.3,
				"volume": 0.3, "level": 0.5,
			}),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.3, "reverbSize": 0.6},
	}


static func preset_kill() -> Dictionary:
	return {
		"channels": [
			_ch({
				"mode": 0, "pitch": 70.0, "length": 0.5, "voice": 2, "detune": 0.04,
				"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.2, "ampRelease": 0.5,
				"pitchEnvEnabled": true, "pitchEnv": -0.3, "pitchAttack": 0.0, "pitchDecay": 0.6,
				"driveEnabled": true, "driveAmount": 0.7, "driveMix": 1.0,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 600.0, "filterRes": 0.3,
				"volume": 0.55, "level": 0.95,
			}),
			_ch({
				"mode": 3, "pitch": 1100.0, "length": 0.6, "voice": 1,
				"ampAttack": 0.02, "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.6,
				"pitchEnvEnabled": true, "pitchEnv": 0.12, "pitchAttack": 0.0, "pitchDecay": 0.4,
				"filterEnabled": true, "filterType": 2, "filterCutoff": 1100.0, "filterRes": 0.7,
				"volume": 0.35, "level": 0.7,
			}),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.35, "reverbSize": 0.7},
	}


static func preset_click() -> Dictionary:
	return {
		"channels": [
			_ch({
				"mode": 0, "pitch": 1600.0, "length": 0.04, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 4000.0, "filterRes": 0.2,
				"volume": 0.4,
			}),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.0, "reverbSize": 0.2},
	}
