class_name PresetsHelpers
extends RefCounted

# Shared infrastructure for all preset groups (each extends this class):
# RNG helpers, lock handling, the sound-building toolkit (`_layer` plus
# one small dict builder per module), and GEN / MUTATE.
#
# Every function here has a hand-written twin in docs/js/presets-helpers.js;
# tools/convert_presets.py imports them into the generated JS presets, so
# keep the two in step and add new names to the converter's import list.


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


# ── Sound-building toolkit ─────────────────────────────────────────

# Readable names for the `mode` and `filterType` ints.
const SQR := 0
const SAW := 1
const TRI := 2
const SIN := 3
const NSE := 4
const PNK := 5
const BRN := 6

const LP := 0
const HP := 1
const BP := 2


# Build a channel: defaults, then ALL_OFF, then `base`, then each module
# dict in `mods` in order. The default amp envelope is instant attack +
# full-length decay — the percussive shape most layers want.
static func _layer(base: Dictionary, mods: Array = []) -> Dictionary:
	var c: Dictionary = SoundData.clone_params()
	c.merge(ALL_OFF, true)
	c.merge(base, true)
	for m in mods:
		c.merge(m, true)
	return c


# Wrap channels into a full Sound with a master reverb setting.
static func _sound(channels: Array, reverb_mix: float, reverb_size: float, master_volume: float = 1.0) -> Dictionary:
	return {
		"channels": channels,
		"master": {"masterVolume": master_volume, "reverbMix": reverb_mix, "reverbSize": reverb_size},
	}


# ── Module dicts (pass in `_layer`'s mods array) ───────────────────

# Amp ADSR; times are fractions of the channel length.
static func _env(attack: float, decay: float, sustain: float, release: float) -> Dictionary:
	return {"ampAttack": attack, "ampDecay": decay, "ampSustain": sustain, "ampRelease": release}


# Filter with an AD cutoff envelope (env ±1 ≈ ±4 octaves at its peak).
static func _filt(ftype: int, cutoff: float, res: float, env: float = 0.0, attack: float = 0.0, decay: float = 0.5) -> Dictionary:
	return {
		"filterEnabled": true, "filterType": ftype, "filterCutoff": cutoff, "filterRes": res,
		"filterEnv": env, "filterAttack": attack, "filterDecay": decay,
	}


static func _drive(amount: float, mix: float = 1.0) -> Dictionary:
	return {"driveEnabled": true, "driveAmount": amount, "driveMix": mix}


# Pitch envelope (amount ±1 ≈ ±2 octaves at its peak). attack 0 starts at
# the peak and falls back to the base pitch over `decay`. The envelope
# drops to zero once attack + decay has elapsed, so a rise that should
# hold to the end uses attack 1.0, decay 0.0.
static func _bend(amount: float, attack: float, decay: float) -> Dictionary:
	return {"pitchEnvEnabled": true, "pitchEnv": amount, "pitchAttack": attack, "pitchDecay": decay}


# Vibrato: depth is a ± frequency ratio (0.1 = ±10 %). A SAW shape gives
# repeating upward sweeps (chirps); NSE gives a rough, gravelly voice.
static func _vib(depth: float, rate: float, shape: int = SIN, attack: float = 0.0, decay: float = 1.0) -> Dictionary:
	return {
		"vibEnabled": true, "pitchMod": depth, "modShape": shape, "modRate": rate,
		"modAttack": attack, "modDecay": decay,
	}


static func _trem(depth: float, rate: float, shape: int = SIN, attack: float = 0.0, decay: float = 1.0) -> Dictionary:
	return {
		"tremEnabled": true, "tremDepth": depth, "tremShape": shape, "tremRate": rate,
		"tremAttack": attack, "tremDecay": decay,
	}


# Pulse train: a SAW tremolo restarts the amplitude at the top of every
# cycle and ramps it down, so one channel becomes `rate` separate hits
# per second (gunfire bursts, rattles, insect chirps, engine firing).
# The gating fades as the tremolo envelope decays, so keep the hits in
# the first half of the channel and let the amp envelope end them.
static func _pulses(rate: float, depth: float = 1.0) -> Dictionary:
	return _trem(depth, rate, SAW)


# Late onset: hold a channel silent until `at` seconds, then hit hard and
# ring for `ring` seconds. A square tremolo closes the gate for the first
# half-cycle and opens it for the second (`at` → 2·`at`), and the amp
# attack ramps up to peak right as it opens. `length` must be the
# channel's length, and ~4× `at` or more: the gate leaks a little as the
# tremolo envelope fades. Keep `ring` ≤ `at` so the layer dies before
# the gate closes again.
static func _at(at: float, length: float, ring: float) -> Dictionary:
	var d: Dictionary = _trem(1.0, 0.5 / at, SQR)
	d.merge(_env(at / length, ring / length, 0.0, 0.0), true)
	return d


# Note sequence: base, +s1, +s2, +s3 semitones, cycling at `rate` Hz.
static func _arp(rate: float, s1: int, s2: int, s3: int) -> Dictionary:
	return {"arpEnabled": true, "arpRate": rate, "arpStep1": s1, "arpStep2": s2, "arpStep3": s3}


# Delay. With mix 1.0 and no feedback the echo plays at full level and
# the dry hit at half — a cheap way to place a second event `ms` later
# (heel-toe, knock-knock, a slide racking after a shot).
static func _echo(ms: float, mix: float, feedback: float = 0.0) -> Dictionary:
	return {"delayEnabled": true, "delayTime": ms, "delayFeedback": feedback, "delayMix": mix}


static func _crush(bits: int, rate: int) -> Dictionary:
	return {"crushEnabled": true, "crushBits": bits, "crushRate": rate}


static func _flange(depth: float, rate: float, feedback: float, mix: float) -> Dictionary:
	return {
		"flangerEnabled": true, "flangerDepth": depth, "flangerRate": rate,
		"flangerFeedback": feedback, "flangerMix": mix,
	}


# Chord: pitch-shifted copies of the rendered channel. Upward copies are
# also time-compressed, so they die sooner — handy for bell and metal
# partials, where the upper modes ring shorter than the fundamental.
static func _chord(n1: int, n2: int, n3: int, mix: float) -> Dictionary:
	return {"chordEnabled": true, "chordNote1": n1, "chordNote2": n2, "chordNote3": n3, "chordMix": mix}


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
