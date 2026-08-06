class_name PresetsHelpers
extends RefCounted

# Shared infrastructure for all preset groups. Patch presets call helpers
# via the `H` alias in each per-group file (preload at the top of each
# file). Sound presets and randomize_all live here too because they share
# the same toolkit.


# ── RNG / picking ──────────────────────────────────────────────────

static func _rand(a: float, b: float) -> float:
	return randf() * (b - a) + a


static func _rand_int(a: int, b: int) -> int:
	return int(floor(randf() * float(b - a + 1))) + a


static func _pick(arr: Array):
	return arr[_rand_int(0, arr.size() - 1)]


# ── Patch application ──────────────────────────────────────────────

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
	"flangerEnabled": false,
	"chordEnabled": false,
}


# Build a preset target by merging ALL_OFF with `extra`.
static func _off_with(extra: Dictionary) -> Dictionary:
	var out: Dictionary = ALL_OFF.duplicate(true)
	out.merge(extra, true)
	return out


# ── Shared envelope / channel helpers ──────────────────────────────

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


# Build a channel by merging defaults with overrides + ALL_OFF. Used
# exclusively by sound (multi-channel) presets.
static func _ch(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = SoundData.clone_params()
	c.merge(ALL_OFF, true)
	c.merge(overrides, true)
	return c


# Tonal body: pitched waveform with optional drive and LP filter.
static func _tonal_body(mode: int, pitch: float, length: float, voices: int,
		detune: float, drive: float, cutoff: float, volume: float,
		level: float = 1.0) -> Dictionary:
	var overrides: Dictionary = {
		"mode": mode, "pitch": pitch, "length": length,
		"voice": voices, "detune": detune,
		"volume": volume, "level": level,
	}
	if drive > 0.0:
		overrides.merge({"driveEnabled": true, "driveAmount": drive, "driveMix": 1.0}, true)
	if cutoff > 0.0:
		overrides.merge({
			"filterEnabled": true, "filterType": 0,
			"filterCutoff": cutoff, "filterRes": 0.2,
		}, true)
	var ch: Dictionary = _ch(overrides)
	ch.merge(ENV_DECAY_ONLY, true)
	return ch


# Resonant sweep: bandpass or LP filter sweep for shimmer/texture layers.
static func _resonant_sweep(length: float, cutoff: float, res: float,
		filter_env: float, filter_decay: float, volume: float,
		level: float = 1.0, filter_type: int = 2) -> Dictionary:
	var ch: Dictionary = _ch({
		"mode": 4, "pitch": 1000.0, "length": length, "voice": 1,
		"filterEnabled": true, "filterType": filter_type,
		"filterCutoff": cutoff, "filterRes": res,
		"filterEnv": filter_env, "filterAttack": 0.0, "filterDecay": filter_decay,
		"volume": volume, "level": level,
	})
	ch.merge(ENV_DECAY_ONLY, true)
	return ch


# Pitched transient: very short tonal hit for clicky/thuddy attack layers.
static func _pitched_transient(mode: int, pitch: float, length: float,
		volume: float, level: float = 1.0) -> Dictionary:
	var ch: Dictionary = _ch({
		"mode": mode, "pitch": pitch, "length": length, "voice": 1,
		"volume": volume, "level": level,
	})
	ch.merge(ENV_DECAY_ONLY, true)
	return ch


# ── Randomize-all (the GEN button) ──────────────────────────────────

# Nudge every unlocked param by up to ±MUTATE_AMOUNT of its range,
# in place. Locked params hold, same as they do through GEN.
const MUTATE_AMOUNT := 0.1


static func mutate_channel(ch: Dictionary, locked: Dictionary) -> void:
	for key in SoundData.PARAM_DEFS:
		if bool(locked.get(key, false)):
			continue
		var def: Dictionary = SoundData.PARAM_DEFS[key]
		var range_span: float = def.max - def.min
		var nudge: float = (randf() * 2.0 - 1.0) * range_span * MUTATE_AMOUNT
		var old_val: float = float(ch.get(key, def.get("min", 0.0)))
		var new_val: float = clampf(old_val + nudge, def.min, def.max)
		if def.step >= 1.0:
			ch[key] = int(round(new_val))
		else:
			ch[key] = snappedf(new_val, def.step)


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
		"mode": _rand_int(0, 6),
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
		"flangerEnabled": randf() < 0.2,
		"flangerDepth": _rand(0.2, 0.8),
		"flangerRate": _rand(0.2, 5.0),
		"flangerFeedback": _rand(-0.5, 0.5),
		"flangerMix": _rand(0.3, 0.7),
		"chordEnabled": randf() < 0.15,
		"chordNote1": _pick([3, 4, 5, 7, 12]),
		"chordNote2": _pick([7, 12, -12, 0]),
		"chordNote3": _pick([12, 0, -5, -12]),
		"chordMix": _rand(0.3, 0.7),
	}
	target.merge(amp_shape, true)
	return _apply_target(params, locked, target)
