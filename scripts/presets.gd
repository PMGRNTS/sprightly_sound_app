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


# ── Shared envelope / channel helpers ──────────────────────────────
# These collapse the most-repeated idioms across presets. Use them to
# keep new presets concise and consistent — see Pillar 2 work.

# All-decay amp envelope: instant attack, full decay over the channel's
# length, no sustain or release. The percussive "transient layer" shape
# used in nearly every SHOOTER channel and most ARCADE one-shots.
const ENV_DECAY_ONLY: Dictionary = {
	"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
}


# Pitch envelope that DECAYS away from the modulation peak. Negative
# strength → downward sweep (laser/zap/explode). Positive strength → upward
# transient that settles. pitchAttack=0; modulation begins at full value
# and dies linearly over `decay` (a fraction of the channel length).
static func _pitch_env_decay(strength: float, decay: float) -> Dictionary:
	return {
		"pitchEnvEnabled": true,
		"pitchEnv": strength,
		"pitchAttack": 0.0,
		"pitchDecay": decay,
	}


# Pitch envelope that RISES into the modulation peak. Pitch starts at
# base, ramps up over `attack`, then sustains. Used for "swell up" sounds
# (jump, bubble) where the pitch climbs throughout the note.
static func _pitch_env_rise(strength: float, attack: float) -> Dictionary:
	return {
		"pitchEnvEnabled": true,
		"pitchEnv": strength,
		"pitchAttack": attack,
		"pitchDecay": 0.0,
	}


# HP-filtered short noise burst — the "snap" of a gunshot, click of a
# headshot. Always all-decay envelope; pitch fixed at 1000 Hz (irrelevant
# for noise mode). Tweak length / cutoff / res for character.
static func _hp_noise_transient(length: float, cutoff: float, res: float, volume: float, level: float = 1.0) -> Dictionary:
	var ch: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0, "length": length, "voice": 1,
		"filterEnabled": true, "filterType": 1, "filterCutoff": cutoff, "filterRes": res,
		"volume": volume, "level": level,
	})
	ch.merge(ENV_DECAY_ONLY, true)
	return ch


# LP-filtered noise tail — the "sizzle" / "sweep" after a transient. The
# filter envelope opens or closes over the channel's life (positive
# filter_env = brightening sweep, negative = darkening).
static func _lp_noise_tail(length: float, cutoff: float, res: float, filter_env: float, filter_decay: float, volume: float, level: float = 1.0) -> Dictionary:
	var ch: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0, "length": length, "voice": 1,
		"filterEnabled": true, "filterType": 0, "filterCutoff": cutoff, "filterRes": res,
		"filterEnv": filter_env, "filterAttack": 0.0, "filterDecay": filter_decay,
		"volume": volume, "level": level,
	})
	ch.merge(ENV_DECAY_ONLY, true)
	return ch


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


# ── UI patches ──────────────────────────────────────────────────────
# Subtle interface feedback. Most are very short (<100 ms) and use modest
# volume so they layer over a game's existing audio without competing.

# Hover: very brief sine tip — non-intrusive cursor feedback.
static func preset_hover(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(1500.0, 2200.0),
		"length": _rand(0.025, 0.05),
		"voice": 1, "detune": 0.0,
		"volume": _rand(0.25, 0.35),
	}))


# Press: short click with a tiny pitch dip — the "physical" button feel.
static func preset_press(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(800.0, 1200.0),
		"length": _rand(0.04, 0.08),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.15, -0.05), "pitchAttack": 0.0, "pitchDecay": _rand(0.4, 0.6),
		"volume": 0.4,
	}))


# Toggle-on / Toggle-off: paired rising / falling chirps — the mental
# model is "switch flips up" vs. "switch flips down".
static func preset_toggle_on(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(500.0, 700.0),
		"length": _rand(0.08, 0.12),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.4, 0.6), "pitchAttack": _rand(0.4, 0.7), "pitchDecay": 0.0,
		"volume": 0.4,
	}))


static func preset_toggle_off(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(700.0, 900.0),
		"length": _rand(0.08, 0.12),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.5, -0.3), "pitchAttack": 0.0, "pitchDecay": _rand(0.5, 0.8),
		"volume": 0.4,
	}))


# Menu: chunkier than press — the "I committed to opening this" feel.
static func preset_menu(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(400.0, 600.0),
		"length": _rand(0.12, 0.18),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.1, 0.2), "pitchAttack": _rand(0.2, 0.4), "pitchDecay": 0.0,
		"volume": 0.45,
	}))


# Cancel: descending counterpart to MENU.
static func preset_cancel(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(700.0, 900.0),
		"length": _rand(0.12, 0.18),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.4, -0.2), "pitchAttack": 0.0, "pitchDecay": _rand(0.6, 0.8),
		"volume": 0.4,
	}))


# Error: low driven buzz — short, impossible to miss, doesn't startle.
static func preset_error(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([1, 4]),
		"pitch": _rand(100.0, 180.0),
		"length": _rand(0.18, 0.28),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.4,
		"driveEnabled": true, "driveAmount": _rand(0.3, 0.5), "driveMix": 1.0,
		"volume": 0.5,
	}))


# Notify: two-tone pulse via the arpeggio (alternating fifth) — the
# generic "you got mail" / quest-objective beep.
static func preset_notify(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(700.0, 900.0),
		"length": _rand(0.2, 0.3),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(10.0, 14.0),
		"arpStep1": 5, "arpStep2": 0, "arpStep3": 5,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.5,
		"volume": 0.45,
	}))


# Type: HP-filtered square stub — a single typewriter / mechanical-key click.
static func preset_typing(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(300.0, 450.0),
		"length": _rand(0.02, 0.04),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(700.0, 1100.0), "filterRes": 0.2,
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.25, 0.35),
	}))


# Open / Close: paired LP-filtered noise sweeps. Open BRIGHTENS over time
# (filter env opens up); Close DARKENS (filter env closes down).
static func preset_open(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.18, 0.28),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.6, 0.8), "filterAttack": _rand(0.1, 0.3), "filterDecay": _rand(0.5, 0.7),
		"volume": 0.4,
	}))


static func preset_close(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.18, 0.28),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.0, 0.05), "ampDecay": 0.3, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1200.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.6, -0.4), "filterAttack": 0.0, "filterDecay": _rand(0.6, 0.8),
		"volume": 0.4,
	}))


# ── MAGIC patches ───────────────────────────────────────────────────
# Fantasy-style spell sounds. These layer arpeggios, vibrato, and pitch
# envelopes more aggressively than ARCADE one-shots so each spell has a
# recognisable "shape".

# Cast: rising arpeggio swell — generic "magic word" energy.
static func preset_cast(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 3]),
		"pitch": _rand(400.0, 600.0),
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"arpEnabled": true,
		"arpRate": _rand(14.0, 20.0),
		"arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.2, "ampSustain": 0.6, "ampRelease": 0.4,
		"volume": 0.45,
	}))


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


# Teleport: bright filter sweep + delay — the "phasing in / out" feel.
static func preset_teleport(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([1, 4]),
		"pitch": _rand(800.0, 1200.0),
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(0.6, 0.85), "filterAttack": _rand(0.1, 0.3), "filterDecay": _rand(0.4, 0.7),
		"delayEnabled": true,
		"delayTime": _rand(80.0, 150.0), "delayFeedback": _rand(0.3, 0.5), "delayMix": 0.4,
		"volume": 0.45,
	}))


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


# Fire whoosh: filtered noise sweep — flame, dragon breath, fireball cast.
static func preset_fire_whoosh(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.08, 0.15), "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.5,
		"driveEnabled": true, "driveAmount": _rand(0.3, 0.5), "driveMix": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(180.0, 300.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(0.6, 0.85), "filterAttack": _rand(0.15, 0.3), "filterDecay": _rand(0.4, 0.6),
		"volume": 0.45,
	}))


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


# Summon: low rumble that swells — boss spawn / ritual culmination.
static func preset_summon(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 1,
		"pitch": _rand(60.0, 100.0),
		"length": _rand(0.7, 1.0),
		"voice": _rand_int(2, 3), "detune": _rand(0.05, 0.08),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(0.25, 0.4), "pitchAttack": _rand(0.5, 0.7), "pitchDecay": 0.0,
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(600.0, 1000.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(0.3, 0.5), "filterAttack": _rand(0.3, 0.6), "filterDecay": _rand(0.4, 0.6),
		"ampAttack": _rand(0.15, 0.25), "ampDecay": 0.3, "ampSustain": 0.6, "ampRelease": 0.4,
		"volume": 0.5,
	}))


# ── CREATURE patches ───────────────────────────────────────────────
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


# ── MOVEMENT patches ──────────────────────────────────────────────
# Footsteps and locomotion. The MATERIAL distinguishes the sub-presets
# (wood / stone / metal / water) — each tweaks pitch, filter, and
# transient character to evoke that surface.

# Wood footstep: HP-filtered noise with mid-range body — old floorboard.
static func preset_step_wood(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(150.0, 250.0),
		"length": _rand(0.06, 0.1),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(800.0, 1400.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(-0.3, -0.1), "filterAttack": 0.0, "filterDecay": _rand(0.4, 0.6),
		"volume": _rand(0.3, 0.45),
	}))


# Stone footstep: drier and sharper — boots on rock.
static func preset_step_stone(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(200.0, 350.0),
		"length": _rand(0.04, 0.08),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.35, 0.5),
	}))


# Metal footstep: bright with delay — boot on a steel grate.
static func preset_step_metal(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(900.0, 1400.0),
		"length": _rand(0.05, 0.1),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(2000.0, 3500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"delayEnabled": true,
		"delayTime": _rand(20.0, 50.0), "delayFeedback": _rand(0.2, 0.4), "delayMix": 0.3,
		"volume": _rand(0.35, 0.5),
	}))


# Water step: filtered noise — splashing through shallow water.
static func preset_step_water(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.1, 0.18),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(0.4, 0.6), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"ampAttack": 0.0, "ampDecay": 0.5, "ampSustain": 0.3, "ampRelease": 0.5,
		"volume": _rand(0.35, 0.5),
	}))


# Land: soft thud + a hint of noise — generic landing impact.
static func preset_land(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(80.0, 150.0),
		"length": _rand(0.1, 0.18),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.4, -0.2), "pitchAttack": 0.0, "pitchDecay": _rand(0.4, 0.6),
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.45, 0.6),
	}))


# Slide: extended noise sweep with downward filter movement.
static func preset_slide(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.5,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(800.0, 1400.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.6, -0.4), "filterAttack": 0.0, "filterDecay": _rand(0.6, 0.85),
		"volume": _rand(0.35, 0.5),
	}))


# Climb: rhythmic tremolo'd noise — stepping/grabbing in sequence.
static func preset_climb(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.2, 0.35),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(700.0, 1100.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"tremEnabled": true,
		"tremDepth": _rand(0.5, 0.8), "tremShape": 0, "tremRate": _rand(4.0, 8.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.4, "ampRelease": 0.4,
		"volume": _rand(0.3, 0.45),
	}))


# Jump-land: harder than LAND — impact-heavy variant for big drops.
static func preset_jump_land(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(60.0, 110.0),
		"length": _rand(0.15, 0.25),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.05),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.5, -0.3), "pitchAttack": 0.0, "pitchDecay": _rand(0.5, 0.7),
		"driveEnabled": true, "driveAmount": _rand(0.3, 0.5), "driveMix": 0.8,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(350.0, 600.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.5, 0.65),
	}))


# Roll: tumbling noise — rapid tremolo on filtered noise.
static func preset_roll(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.05, 0.1), "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"tremEnabled": true,
		"tremDepth": _rand(0.5, 0.8), "tremShape": 0, "tremRate": _rand(15.0, 25.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": _rand(0.35, 0.5),
	}))


# ── DESTRUCT patches ──────────────────────────────────────────────
# Things breaking. Most use noise + HP-filter for the bright shatter
# transient, plus delay or short reverb-via-decay for the debris feel.

# Glass: bright shatter + decaying delay tails.
static func preset_glass_break(params: Dictionary, locked: Dictionary) -> Dictionary:
	var t: Dictionary = _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(2500.0, 4000.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.4, -0.2), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"delayEnabled": true,
		"delayTime": _rand(40.0, 80.0), "delayFeedback": _rand(0.4, 0.55), "delayMix": 0.5,
		"volume": _rand(0.4, 0.55),
	})
	t.merge(ENV_DECAY_ONLY, true)
	return _apply_target(params, locked, t)


# Wood crack: square stub + drive — splintering.
static func preset_wood_crack(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 1]),
		"pitch": _rand(200.0, 400.0),
		"length": _rand(0.08, 0.15),
		"voice": 1, "detune": 0.0,
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.4, -0.2), "pitchAttack": 0.0, "pitchDecay": _rand(0.4, 0.6),
		"driveEnabled": true, "driveAmount": _rand(0.5, 0.7), "driveMix": 0.9,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.45, 0.6),
	}))


# Stone crack: lower thud + drive — masonry / boulder snap.
static func preset_stone_crack(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": _rand(120.0, 200.0),
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 0.8,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(500.0, 900.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.3, 0.0), "filterAttack": 0.0, "filterDecay": _rand(0.4, 0.6),
		"volume": _rand(0.45, 0.6),
	}))


# Metal clang: bright sustained ring with delay — bell, anvil, cymbal.
static func preset_metal_clang(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(800.0, 1400.0),
		"length": _rand(0.4, 0.7),
		"voice": _rand_int(2, 3), "detune": _rand(0.03, 0.07),
		"ampAttack": 0.0, "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.6,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2200.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"delayEnabled": true,
		"delayTime": _rand(60.0, 120.0), "delayFeedback": _rand(0.4, 0.6), "delayMix": 0.4,
		"volume": _rand(0.4, 0.5),
	}))


# Rubble: extended noise tail — falling debris after a collapse.
static func preset_rubble(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.5, 0.9),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.0, 0.05), "ampDecay": 0.5, "ampSustain": 0.4, "ampRelease": 0.6,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": _rand(-0.3, -0.1), "filterAttack": 0.0, "filterDecay": _rand(0.6, 0.85),
		"tremEnabled": true,
		"tremDepth": _rand(0.3, 0.5), "tremShape": 4, "tremRate": _rand(8.0, 15.0),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": _rand(0.4, 0.55),
	}))


# Rip: filter sweep + drive — fabric tearing / wound opening.
static func preset_rip(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.2, 0.35),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.5,
		"driveEnabled": true, "driveAmount": _rand(0.4, 0.6), "driveMix": 0.9,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.4, 0.6),
		"filterEnv": _rand(-0.5, -0.3), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"volume": _rand(0.4, 0.55),
	}))


# Impact heavy: low thud with drive — crate dropping, wall punch.
static func preset_impact_heavy(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(50.0, 90.0),
		"length": _rand(0.15, 0.25),
		"voice": _rand_int(1, 2), "detune": _rand(0.0, 0.05),
		"pitchEnvEnabled": true,
		"pitchEnv": _rand(-0.5, -0.3), "pitchAttack": 0.0, "pitchDecay": _rand(0.5, 0.7),
		"driveEnabled": true, "driveAmount": _rand(0.5, 0.7), "driveMix": 1.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(300.0, 500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.5, 0.65),
	}))


# Impact light: tap — stylus, finger flick, tap on a surface.
static func preset_impact_light(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(400.0, 700.0),
		"length": _rand(0.04, 0.08),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.2, 0.4),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.35, 0.5),
	}))


# ── AMBIENT patches ───────────────────────────────────────────────
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


# ── MUSIC-UI patches ──────────────────────────────────────────────
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


# ── MODERN patches ────────────────────────────────────────────────
# Modern shooter / RPG game cues — heartbeat, low-health alerts, weapon
# handling clicks. Lean toward realism rather than chiptune.

# Heartbeat: low pulsing sine — health-critical drumbeat.
static func preset_heartbeat(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 3,
		"pitch": _rand(60.0, 90.0),
		"length": _rand(0.4, 0.6),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.0, 0.03), "ampDecay": 0.5, "ampSustain": 0.0, "ampRelease": 0.0,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(150.0, 250.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
		"volume": _rand(0.5, 0.65),
	}))


# Low-health: pulsing bandpass tone — danger warning.
static func preset_low_health(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 0,
		"pitch": _rand(180.0, 280.0),
		"length": _rand(0.3, 0.5),
		"voice": 1, "detune": 0.0,
		"ampAttack": 0.0, "ampDecay": 0.4, "ampSustain": 0.3, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 2, "filterCutoff": _rand(700.0, 1200.0), "filterRes": _rand(0.55, 0.75),
		"filterEnv": _rand(-0.3, 0.0), "filterAttack": 0.0, "filterDecay": _rand(0.4, 0.6),
		"tremEnabled": true,
		"tremDepth": _rand(0.4, 0.6), "tremShape": 3, "tremRate": _rand(2.5, 4.5),
		"tremAttack": 0.0, "tremDecay": 1.0,
		"volume": _rand(0.4, 0.55),
	}))


# Reload: short mechanical click — gun action / drawer / latch.
static func preset_reload(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": _pick([0, 4]),
		"pitch": _rand(600.0, 1000.0),
		"length": _rand(0.06, 0.12),
		"voice": 1, "detune": 0.0,
		"filterEnabled": true,
		"filterType": 1, "filterCutoff": _rand(1500.0, 2500.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.2, 0.0), "filterAttack": 0.0, "filterDecay": 0.5,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
		"volume": _rand(0.4, 0.55),
	}))


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


# Cover-enter: short whoosh — sliding into cover / hugging wall.
static func preset_cover_enter(params: Dictionary, locked: Dictionary) -> Dictionary:
	return _apply_target(params, locked, _off_with({
		"mode": 4,
		"pitch": 1000.0,
		"length": _rand(0.15, 0.25),
		"voice": 1, "detune": 0.0,
		"ampAttack": _rand(0.03, 0.08), "ampDecay": 0.3, "ampSustain": 0.4, "ampRelease": 0.4,
		"filterEnabled": true,
		"filterType": 0, "filterCutoff": _rand(400.0, 700.0), "filterRes": _rand(0.3, 0.5),
		"filterEnv": _rand(-0.4, -0.2), "filterAttack": 0.0, "filterDecay": _rand(0.5, 0.7),
		"volume": _rand(0.35, 0.5),
	}))


# ── Multi-channel "sound" presets ───────────────────────────────────

# Helper: build a channel by merging defaults with overrides + ALL_OFF.
static func _ch(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = SoundData.clone_params()
	c.merge(ALL_OFF, true)
	c.merge(overrides, true)
	return c


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

	{"name": "HOVER",   "kind": "patch", "group": "UI",      "fn": "preset_hover"},
	{"name": "PRESS",   "kind": "patch", "group": "UI",      "fn": "preset_press"},
	{"name": "TGL-ON",  "kind": "patch", "group": "UI",      "fn": "preset_toggle_on"},
	{"name": "TGL-OFF", "kind": "patch", "group": "UI",      "fn": "preset_toggle_off"},
	{"name": "MENU",    "kind": "patch", "group": "UI",      "fn": "preset_menu"},
	{"name": "CANCEL",  "kind": "patch", "group": "UI",      "fn": "preset_cancel"},
	{"name": "ERROR",   "kind": "patch", "group": "UI",      "fn": "preset_error"},
	{"name": "NOTIFY",  "kind": "patch", "group": "UI",      "fn": "preset_notify"},
	{"name": "TYPE",    "kind": "patch", "group": "UI",      "fn": "preset_typing"},
	{"name": "OPEN",    "kind": "patch", "group": "UI",      "fn": "preset_open"},
	{"name": "CLOSE",   "kind": "patch", "group": "UI",      "fn": "preset_close"},

	{"name": "CAST",    "kind": "patch", "group": "MAGIC",   "fn": "preset_cast"},
	{"name": "SPARKLE", "kind": "patch", "group": "MAGIC",   "fn": "preset_sparkle"},
	{"name": "HEAL",    "kind": "patch", "group": "MAGIC",   "fn": "preset_heal"},
	{"name": "BUFF",    "kind": "patch", "group": "MAGIC",   "fn": "preset_buff"},
	{"name": "DEBUFF",  "kind": "patch", "group": "MAGIC",   "fn": "preset_debuff"},
	{"name": "TELEPORT","kind": "patch", "group": "MAGIC",   "fn": "preset_teleport"},
	{"name": "FREEZE",  "kind": "patch", "group": "MAGIC",   "fn": "preset_freeze"},
	{"name": "FIRE",    "kind": "patch", "group": "MAGIC",   "fn": "preset_fire_whoosh"},
	{"name": "BREAK",   "kind": "patch", "group": "MAGIC",   "fn": "preset_shield_break"},
	{"name": "SUMMON",  "kind": "patch", "group": "MAGIC",   "fn": "preset_summon"},

	{"name": "YELP",    "kind": "patch", "group": "CREATURE","fn": "preset_yelp"},
	{"name": "HURT",    "kind": "patch", "group": "CREATURE","fn": "preset_hurt"},
	{"name": "DEATH",   "kind": "patch", "group": "CREATURE","fn": "preset_death"},
	{"name": "IDLE",    "kind": "patch", "group": "CREATURE","fn": "preset_idle"},
	{"name": "ROAR",    "kind": "patch", "group": "CREATURE","fn": "preset_roar"},
	{"name": "CHITTER", "kind": "patch", "group": "CREATURE","fn": "preset_chitter"},
	{"name": "SQUEAK",  "kind": "patch", "group": "CREATURE","fn": "preset_squeak"},
	{"name": "FLAP",    "kind": "patch", "group": "CREATURE","fn": "preset_flap"},
	{"name": "SLITHER", "kind": "patch", "group": "CREATURE","fn": "preset_slither"},

	{"name": "WOOD",    "kind": "patch", "group": "MOVEMENT","fn": "preset_step_wood"},
	{"name": "STONE",   "kind": "patch", "group": "MOVEMENT","fn": "preset_step_stone"},
	{"name": "METAL",   "kind": "patch", "group": "MOVEMENT","fn": "preset_step_metal"},
	{"name": "WATER",   "kind": "patch", "group": "MOVEMENT","fn": "preset_step_water"},
	{"name": "LAND",    "kind": "patch", "group": "MOVEMENT","fn": "preset_land"},
	{"name": "SLIDE",   "kind": "patch", "group": "MOVEMENT","fn": "preset_slide"},
	{"name": "CLIMB",   "kind": "patch", "group": "MOVEMENT","fn": "preset_climb"},
	{"name": "JLAND",   "kind": "patch", "group": "MOVEMENT","fn": "preset_jump_land"},
	{"name": "ROLL",    "kind": "patch", "group": "MOVEMENT","fn": "preset_roll"},

	{"name": "GLASS",   "kind": "patch", "group": "DESTRUCT","fn": "preset_glass_break"},
	{"name": "WOOD-CR", "kind": "patch", "group": "DESTRUCT","fn": "preset_wood_crack"},
	{"name": "STONE-CR","kind": "patch", "group": "DESTRUCT","fn": "preset_stone_crack"},
	{"name": "CLANG",   "kind": "patch", "group": "DESTRUCT","fn": "preset_metal_clang"},
	{"name": "RUBBLE",  "kind": "patch", "group": "DESTRUCT","fn": "preset_rubble"},
	{"name": "RIP",     "kind": "patch", "group": "DESTRUCT","fn": "preset_rip"},
	{"name": "IMP-HVY", "kind": "patch", "group": "DESTRUCT","fn": "preset_impact_heavy"},
	{"name": "IMP-LT",  "kind": "patch", "group": "DESTRUCT","fn": "preset_impact_light"},

	{"name": "WIND",    "kind": "patch", "group": "AMBIENT", "fn": "preset_wind"},
	{"name": "RAIN",    "kind": "patch", "group": "AMBIENT", "fn": "preset_rain"},
	{"name": "CRACKLE", "kind": "patch", "group": "AMBIENT", "fn": "preset_fire_crackle"},
	{"name": "HUM",     "kind": "patch", "group": "AMBIENT", "fn": "preset_electric_hum"},
	{"name": "DRIP",    "kind": "patch", "group": "AMBIENT", "fn": "preset_water_drip"},
	{"name": "ENGINE",  "kind": "patch", "group": "AMBIENT", "fn": "preset_engine_idle"},

	{"name": "WIN",     "kind": "patch", "group": "MUSIC-UI","fn": "preset_stinger_win"},
	{"name": "LOSE",    "kind": "patch", "group": "MUSIC-UI","fn": "preset_stinger_lose"},
	{"name": "FD-IN",   "kind": "patch", "group": "MUSIC-UI","fn": "preset_fade_in"},
	{"name": "FD-OUT",  "kind": "patch", "group": "MUSIC-UI","fn": "preset_fade_out"},
	{"name": "PAUSE",   "kind": "patch", "group": "MUSIC-UI","fn": "preset_pause"},
	{"name": "RESUME",  "kind": "patch", "group": "MUSIC-UI","fn": "preset_resume"},
	{"name": "FANFARE", "kind": "patch", "group": "MUSIC-UI","fn": "preset_fanfare"},

	{"name": "HEART",   "kind": "patch", "group": "MODERN",  "fn": "preset_heartbeat"},
	{"name": "LOW-HP",  "kind": "patch", "group": "MODERN",  "fn": "preset_low_health"},
	{"name": "RELOAD",  "kind": "patch", "group": "MODERN",  "fn": "preset_reload"},
	{"name": "DRY",     "kind": "patch", "group": "MODERN",  "fn": "preset_empty_chamber"},
	{"name": "SWITCH",  "kind": "patch", "group": "MODERN",  "fn": "preset_switch_weapon"},
	{"name": "COVER",   "kind": "patch", "group": "MODERN",  "fn": "preset_cover_enter"},
]


# Dispatch a preset via Callable. `params` and `locked` are only used by
# patch presets; sound presets ignore them.
#
# Confirmed in Godot 4.6: `Callable(Presets, "preset_jump")` resolves
# static methods and `.is_valid()` correctly returns false for unknown
# names — so adding a preset is now a one-line REGISTRY append + the
# new static func, with no dispatcher edit required.
static func run_preset(entry: Dictionary, params: Dictionary, locked: Dictionary) -> Variant:
	var c := Callable(Presets, entry.fn)
	if not c.is_valid():
		push_warning("Unknown preset fn: %s" % entry.fn)
		return null
	if entry.kind == "sound":
		return c.call()
	return c.call(params, locked)
