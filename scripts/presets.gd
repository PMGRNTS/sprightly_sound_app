class_name Presets
extends RefCounted

# All presets respect the user's lock map. Two kinds:
#   • patch  → mutates the active channel's params
#   • sound  → replaces the entire Sound (used for layered, multi-channel SFX)


static func _rand(a: float, b: float) -> float:
	return randf() * (b - a) + a


static func _rand_int(a: int, b: int) -> int:
	return int(floor(randf() * float(b - a + 1))) + a


static func _pick(arr: Array):
	return arr[_rand_int(0, arr.size() - 1)]


# Apply a target dict on top of `params`, skipping any key that's locked.
static func _apply_target(params: Dictionary, locked: Dictionary, target: Dictionary) -> Dictionary:
	var out: Dictionary = params.duplicate(true)
	for k in target.keys():
		if not bool(locked.get(k, false)):
			out[k] = target[k]
	return out


# Implicitly lock a module's enable flag if any of its params are locked —
# otherwise GEN could turn off a module the user clearly wants kept on.
static func effective_locks(locked: Dictionary) -> Dictionary:
	var out: Dictionary = locked.duplicate(true)
	for mod in SoundData.MODULES:
		var ek: String = mod.enable_key
		if ek == "":
			continue
		if bool(out.get(ek, false)):
			continue
		for p in mod.params:
			if bool(out.get(p, false)):
				out[ek] = true
				break
	return out


# Standard "off" block: applied as the base of every preset so the user
# isn't surprised by leftover modules from the previous patch.
const ALL_OFF: Dictionary = {
	"pitchEnvEnabled": false,
	"vibEnabled": false,
	"tremEnabled": false,
	"arpEnabled": false,
	"delayEnabled": false,
	"crushEnabled": false,
	"driveEnabled": false,
	"filterEnabled": false,
}


# Build a preset target by merging ALL_OFF with `extra`.
static func _off_with(extra: Dictionary) -> Dictionary:
	var out: Dictionary = ALL_OFF.duplicate(true)
	out.merge(extra, true)
	return out


# ── Randomize-all (the GEN button) ──────────────────────────────────

static func randomize_all(params: Dictionary, locked: Dictionary) -> Dictionary:
	# Bias ADSR toward percussive shapes (most SFX are hits).
	var sustained: bool = randf() < 0.2
	var amp_shape: Dictionary
	if sustained:
		amp_shape = {
			"ampAttack": _rand(0.0, 0.2),
			"ampDecay": _rand(0.0, 0.3),
			"ampSustain": _rand(0.4, 0.9),
			"ampRelease": _rand(0.2, 0.6),
		}
	else:
		amp_shape = {
			"ampAttack": _rand(0.0, 0.05),
			"ampDecay": _rand(0.5, 1.0),
			"ampSustain": _rand(0.0, 0.2),
			"ampRelease": _rand(0.0, 0.3),
		}

	var target: Dictionary = {
		"volume": _rand(0.3, 0.8),
		"mode": _rand_int(0, 4),
		"pitch": _rand(80.0, 2000.0),
		"length": _rand(0.1, 1.0),
		"voice": _rand_int(1, 4),
		"detune": _rand(0.0, 0.1),
		"pitchEnvEnabled": randf() < 0.6,
		"pitchEnv": _rand(-0.5, 0.5),
		"pitchAttack": _rand(0.0, 0.4),
		"pitchDecay": _rand(0.2, 1.0),
		"vibEnabled": randf() < 0.4,
		"pitchMod": _rand(0.05, 0.5),
		"modShape": _rand_int(0, 4),
		"modRate": _rand(2.0, 25.0),
		"modAttack": _rand(0.0, 0.3),
		"modDecay": _rand(0.2, 1.0),
		"tremEnabled": randf() < 0.25,
		"tremDepth": _rand(0.3, 0.8),
		"tremShape": _rand_int(0, 4),
		"tremRate": _rand(4.0, 20.0),
		"tremAttack": _rand(0.0, 0.2),
		"tremDecay": _rand(0.5, 1.0),
		"arpEnabled": randf() < 0.2,
		"arpRate": _rand(8.0, 30.0),
		"arpStep1": _pick([3, 4, 5, 7, -5, -7, 12]),
		"arpStep2": _pick([7, 12, -12, 5]),
		"arpStep3": _pick([12, 0, -12, 7]),
		"delayEnabled": randf() < 0.3,
		"delayTime": _rand(50.0, 300.0),
		"delayFeedback": _rand(0.2, 0.6),
		"delayMix": _rand(0.3, 0.6),
		"crushEnabled": randf() < 0.3,
		"crushBits": _rand_int(2, 8),
		"crushRate": _rand_int(1, 16),
		"driveEnabled": randf() < 0.25,
		"driveAmount": _rand(0.2, 0.7),
		"driveMix": _rand(0.7, 1.0),
		"filterEnabled": randf() < 0.4,
		"filterType": _rand_int(0, 2),
		"filterCutoff": _rand(300.0, 8000.0),
		"filterRes": _rand(0.0, 0.7),
		"filterEnv": _rand(-0.7, 0.7),
		"filterAttack": _rand(0.0, 0.4),
		"filterDecay": _rand(0.3, 1.0),
	}
	target.merge(amp_shape, true)
	return _apply_target(params, locked, target)


# ── Single-channel patches ──────────────────────────────────────────

static func preset_jump(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(200.0, 500.0),
		"length": _rand(0.15, 0.35),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.3, 0.6), "pitchAttack": _rand(0.5, 1.0), "pitchDecay": 0.0,
		"volume": 0.6,
	}))


static func preset_shoot(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([1, 4]),
		"pitch": _rand(600.0, 1200.0),
		"length": _rand(0.1, 0.25),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.05),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.4, 0.8), "pitchAttack": 0.0, "pitchDecay": _rand(0.6, 1.0),
		"volume": 0.5,
	}))


static func preset_hit(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(200.0, 600.0),
		"length": _rand(0.08, 0.2),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.2, 0.5), "pitchAttack": 0.0, "pitchDecay": _rand(0.3, 0.6),
		"volume": 0.55,
	}))


static func preset_coin(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(800.0, 1100.0),
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(15.0, 25.0),
		"arpStep1": _pick([5, 7]), "arpStep2": _pick([5, 7]), "arpStep3": _pick([5, 7]),
		"volume": 0.5,
	}))


static func preset_explode(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(80.0, 200.0),
		"length": _rand(0.5, 1.2),
		"voice": _rand_int(2, 4), "detune": _rand(0.05, 0.15),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.3, 0.6), "pitchAttack": 0.0, "pitchDecay": _rand(0.8, 1.0),
		"volume": 0.6,
	}))


# Powerup: ascending arp + swell-in attack — feels like an ability charging.
static func preset_powerup(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(300.0, 500.0),
		"length": _rand(0.4, 0.7),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.15, "ampDecay": 0.2, "ampSustain": 0.7, "ampRelease": 0.4,
		"arpEnabled": true,
		"arpRate": _rand(12.0, 20.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"volume": 0.55,
	}))


static func preset_blip(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(800.0, 1500.0),
		"length": _rand(0.05, 0.1),
		"voice": 1, "detune": 0.0,
		"volume": 0.4,
	}))


static func preset_laser(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([1, 3]),
		"pitch": _rand(800.0, 1600.0),
		"length": _rand(0.15, 0.3),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.9, -0.5), "pitchAttack": 0.0, "pitchDecay": _rand(0.7, 1.0),
		"delayEnabled": true,
		"delayTime": _rand(60.0, 120.0), "delayFeedback": _rand(0.3, 0.5), "delayMix": 0.4,
		"volume": 0.5,
	}))


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


static func preset_zap(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 1,
		"pitch": _rand(1000.0, 2000.0),
		"length": _rand(0.15, 0.3),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.6, -0.3), "pitchAttack": 0.0, "pitchDecay": _rand(0.6, 1.0),
		"vibEnabled": true,
		"pitchMod": _rand(0.2, 0.4), "modShape": _pick([0, 1]), "modRate": _rand(20.0, 30.0),
		"modAttack": 0.0, "modDecay": 1.0,
		"crushEnabled": true,
		"crushBits": _rand_int(4, 8), "crushRate": 1,
		"volume": 0.5,
	}))


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


static func preset_whoosh(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.02, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(150.0, 250.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.6, 0.85), "filterAttack": 0.0, "filterDecay": _rand(0.7, 0.9),
		"volume": 0.45,
	}))


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


static func preset_growl(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 1,
		"pitch": _rand(90.0, 130.0),
		"length": _rand(0.4, 0.6),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.05),
		"ampAttack": 0.01, "ampDecay": 0.2, "ampSustain": 0.6, "ampRelease": 0.4,
		"driveEnabled": true,
		"driveAmount": _rand(0.5, 0.8), "driveMix": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(-0.3, 0.0), "filterAttack": 0.0, "filterDecay": _rand(0.6, 1.0),
		"volume": 0.45,
	}))


# ── Multi-channel "sound" presets ───────────────────────────────────

# Helper: build a channel by merging defaults with overrides + ALL_OFF.
static func _ch(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = SoundData.clone_params()
	c.merge(ALL_OFF, true)
	c.merge(overrides, true)
	return c


static func preset_gunshot() -> Dictionary:
	return {
		"channels": [
			# Transient: ultra-short HP-filtered noise burst (the "snap")
			_ch({
				"mode": 4, "pitch": 1000.0, "length": 0.04, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"filterEnabled": true, "filterType": 1, "filterCutoff": 2000.0, "filterRes": 0.2,
				"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
				"volume": 0.6, "level": 0.8,
			}),
			# Body: low square through drive + LP (the "thump")
			_ch({
				"mode": 0, "pitch": 90.0, "length": 0.18, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.0, "ampRelease": 0.0,
				"pitchEnvEnabled": true, "pitchEnv": -0.4, "pitchAttack": 0.0, "pitchDecay": 0.4,
				"driveEnabled": true, "driveAmount": 0.65, "driveMix": 1.0,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 900.0, "filterRes": 0.2,
				"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
				"volume": 0.55, "level": 0.85,
			}),
			# Tail: filtered noise sweeping (the "sizzle")
			_ch({
				"mode": 4, "pitch": 1000.0, "length": 0.22, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 700.0, "filterRes": 0.4,
				"filterEnv": 0.6, "filterAttack": 0.0, "filterDecay": 0.7,
				"volume": 0.4, "level": 0.5,
			}),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.12, "reverbSize": 0.3},
	}


static func preset_heavy_gun() -> Dictionary:
	return {
		"channels": [
			_ch({
				"mode": 4, "pitch": 800.0, "length": 0.05, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"filterEnabled": true, "filterType": 1, "filterCutoff": 1500.0, "filterRes": 0.3,
				"volume": 0.65, "level": 0.85,
			}),
			_ch({
				"mode": 0, "pitch": 55.0, "length": 0.3, "voice": 2, "detune": 0.04,
				"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.0, "ampRelease": 0.0,
				"pitchEnvEnabled": true, "pitchEnv": -0.5, "pitchAttack": 0.0, "pitchDecay": 0.5,
				"driveEnabled": true, "driveAmount": 0.8, "driveMix": 1.0,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 600.0, "filterRes": 0.3,
				"volume": 0.6, "level": 0.95,
			}),
			_ch({
				"mode": 4, "pitch": 1000.0, "length": 0.4, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"filterEnabled": true, "filterType": 0, "filterCutoff": 500.0, "filterRes": 0.5,
				"filterEnv": 0.7, "filterAttack": 0.0, "filterDecay": 0.8,
				"volume": 0.45, "level": 0.55,
			}),
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
	return {
		"channels": [
			_ch({
				"mode": 4, "pitch": 1000.0, "length": 0.025, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"filterEnabled": true, "filterType": 1, "filterCutoff": 3000.0, "filterRes": 0.3,
				"volume": 0.55, "level": 0.7,
			}),
			_ch({
				"mode": 3, "pitch": 1400.0, "length": 0.1, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.0, "ampRelease": 0.0,
				"pitchEnvEnabled": true, "pitchEnv": 0.15, "pitchAttack": 0.0, "pitchDecay": 0.4,
				"volume": 0.5, "level": 0.85,
			}),
		],
		"master": {"masterVolume": 1.0, "reverbMix": 0.08, "reverbSize": 0.25},
	}


static func preset_headshot() -> Dictionary:
	return {
		"channels": [
			_ch({
				"mode": 4, "pitch": 1000.0, "length": 0.04, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
				"filterEnabled": true, "filterType": 1, "filterCutoff": 4000.0, "filterRes": 0.4,
				"volume": 0.5, "level": 0.7,
			}),
			_ch({
				"mode": 3, "pitch": 2200.0, "length": 0.4, "voice": 1,
				"ampAttack": 0.0, "ampDecay": 0.2, "ampSustain": 0.5, "ampRelease": 0.6,
				"pitchEnvEnabled": true, "pitchEnv": 0.08, "pitchAttack": 0.0, "pitchDecay": 0.3,
				"volume": 0.4, "level": 0.8,
			}),
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


# Registry: kind=sound replaces the entire Sound; kind=patch mutates the
# active channel only. The UI walks this list to render the preset buttons.
const REGISTRY: Array = [
	{"name": "GUN",     "kind": "sound", "group": "SHOOTER", "fn": "preset_gunshot"},
	{"name": "HVY",     "kind": "sound", "group": "SHOOTER", "fn": "preset_heavy_gun"},
	{"name": "BURST",   "kind": "sound", "group": "SHOOTER", "fn": "preset_burst"},
	{"name": "DASH",    "kind": "sound", "group": "SHOOTER", "fn": "preset_dash"},
	{"name": "CONF",    "kind": "sound", "group": "SHOOTER", "fn": "preset_confirm"},
	{"name": "HEAD",    "kind": "sound", "group": "SHOOTER", "fn": "preset_headshot"},
	{"name": "SHIELD",  "kind": "sound", "group": "SHOOTER", "fn": "preset_shield"},
	{"name": "KILL",    "kind": "sound", "group": "SHOOTER", "fn": "preset_kill"},
	{"name": "CLICK",   "kind": "sound", "group": "SHOOTER", "fn": "preset_click"},

	{"name": "JUMP",    "kind": "patch", "group": "ARCADE",  "fn": "preset_jump"},
	{"name": "SHOOT",   "kind": "patch", "group": "ARCADE",  "fn": "preset_shoot"},
	{"name": "HIT",     "kind": "patch", "group": "ARCADE",  "fn": "preset_hit"},
	{"name": "COIN",    "kind": "patch", "group": "ARCADE",  "fn": "preset_coin"},
	{"name": "EXPLODE", "kind": "patch", "group": "ARCADE",  "fn": "preset_explode"},
	{"name": "POWERUP", "kind": "patch", "group": "ARCADE",  "fn": "preset_powerup"},
	{"name": "BLIP",    "kind": "patch", "group": "ARCADE",  "fn": "preset_blip"},
	{"name": "LASER",   "kind": "patch", "group": "ARCADE",  "fn": "preset_laser"},
	{"name": "ALARM",   "kind": "patch", "group": "ARCADE",  "fn": "preset_alarm"},
	{"name": "CHIRP",   "kind": "patch", "group": "ARCADE",  "fn": "preset_chirp"},
	{"name": "THUD",    "kind": "patch", "group": "ARCADE",  "fn": "preset_thud"},
	{"name": "BOING",   "kind": "patch", "group": "ARCADE",  "fn": "preset_boing"},
	{"name": "STEP",    "kind": "patch", "group": "ARCADE",  "fn": "preset_step"},
	{"name": "ZAP",     "kind": "patch", "group": "ARCADE",  "fn": "preset_zap"},
	{"name": "BUBBLE",  "kind": "patch", "group": "ARCADE",  "fn": "preset_bubble"},
	{"name": "WHOOSH",  "kind": "patch", "group": "ARCADE",  "fn": "preset_whoosh"},
	{"name": "WUB",     "kind": "patch", "group": "ARCADE",  "fn": "preset_wub"},
	{"name": "GROWL",   "kind": "patch", "group": "ARCADE",  "fn": "preset_growl"},
]


# Dispatch a preset by string name. `params` and `locked` are only used by
# patch presets; sound presets ignore them. We dispatch with `match` rather
# than reflection because GDScript can't `callv` a static method on a class
# directly — and putting Callables in the const REGISTRY would require
# evaluating them at parse time.
static func run_preset(entry: Dictionary, params: Dictionary, locked: Dictionary) -> Variant:
	var n: String = entry.fn
	if entry.kind == "sound":
		match n:
			"preset_gunshot":   return preset_gunshot()
			"preset_heavy_gun": return preset_heavy_gun()
			"preset_burst":     return preset_burst()
			"preset_dash":      return preset_dash()
			"preset_confirm":   return preset_confirm()
			"preset_headshot":  return preset_headshot()
			"preset_shield":    return preset_shield()
			"preset_kill":      return preset_kill()
			"preset_click":     return preset_click()
		return null

	match n:
		"preset_jump":    return preset_jump(params, locked)
		"preset_shoot":   return preset_shoot(params, locked)
		"preset_hit":     return preset_hit(params, locked)
		"preset_coin":    return preset_coin(params, locked)
		"preset_explode": return preset_explode(params, locked)
		"preset_powerup": return preset_powerup(params, locked)
		"preset_blip":    return preset_blip(params, locked)
		"preset_laser":   return preset_laser(params, locked)
		"preset_alarm":   return preset_alarm(params, locked)
		"preset_chirp":   return preset_chirp(params, locked)
		"preset_thud":    return preset_thud(params, locked)
		"preset_boing":   return preset_boing(params, locked)
		"preset_step":    return preset_step(params, locked)
		"preset_zap":     return preset_zap(params, locked)
		"preset_bubble":  return preset_bubble(params, locked)
		"preset_whoosh":  return preset_whoosh(params, locked)
		"preset_wub":     return preset_wub(params, locked)
		"preset_growl":   return preset_growl(params, locked)
	return null
