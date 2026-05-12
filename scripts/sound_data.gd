class_name SoundData
extends RefCounted

# Constants, parameter metadata, default state, serialization, and WAV
# encoding. No synthesis here — see Synth. No UI here — see main.gd.

const SAMPLE_RATE: int = 44100
const MAX_CHANNELS: int = 4
const MODES: Array[String] = ["SQR", "SAW", "TRI", "SIN", "NSE", "PNK", "BRN"]

# Format kinds used by ParamRow to render the right-hand value label.
# (Stored as strings rather than Callables so PARAM_DEFS stays a plain dict.)
enum {
	FMT_DEC2,    # 0.00
	FMT_DEC3,    # 0.000
	FMT_INT,     # 1
	FMT_HZ,      # 440Hz / 1.5kHz
	FMT_HZ1,     # 1.5Hz (one decimal)
	FMT_MS,      # 150ms
	FMT_SEC,     # 0.40s
	FMT_MODE,    # SQR/SAW/TRI/SIN/NSE
	FMT_FILTER,  # LP/HP/BP
	FMT_BITS,    # 8BIT
	FMT_CRUSH,   # 44.1kHz / 11.0kHz
	FMT_STEP,    # +5st / -7st
}

# Per-parameter definitions. Module groupings live in MODULES.
const PARAM_DEFS: Dictionary = {
	"volume":        {"label": "VOLUME",       "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"mode":          {"label": "MODE",         "min": 0.0,    "max": 6.0,     "step": 1.0,   "fmt": FMT_MODE},
	"pitch":         {"label": "PITCH",        "min": 50.0,   "max": 4000.0,  "step": 1.0,   "fmt": FMT_HZ},
	"voice":         {"label": "VOICES",       "min": 1.0,    "max": 4.0,     "step": 1.0,   "fmt": FMT_INT},
	"detune":        {"label": "DETUNE",       "min": 0.0,    "max": 0.2,     "step": 0.005, "fmt": FMT_DEC3},

	"length":        {"label": "LENGTH",       "min": 0.05,   "max": 4.0,     "step": 0.01,  "fmt": FMT_SEC},
	"ampAttack":     {"label": "ATTACK",       "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"ampDecay":      {"label": "DECAY",        "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"ampSustain":    {"label": "SUSTAIN",      "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"ampRelease":    {"label": "RELEASE",      "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"pitchEnv":      {"label": "AMOUNT",       "min": -1.0,   "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"pitchAttack":   {"label": "ATTACK",       "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"pitchDecay":    {"label": "DECAY",        "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"pitchMod":      {"label": "DEPTH",        "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"modShape":      {"label": "SHAPE",        "min": 0.0,    "max": 4.0,     "step": 1.0,   "fmt": FMT_MODE},
	"modRate":       {"label": "RATE",         "min": 0.0,    "max": 30.0,    "step": 0.1,   "fmt": FMT_HZ1},
	"modAttack":     {"label": "ATTACK",       "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"modDecay":      {"label": "DECAY",        "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"tremDepth":     {"label": "DEPTH",        "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"tremShape":     {"label": "SHAPE",        "min": 0.0,    "max": 4.0,     "step": 1.0,   "fmt": FMT_MODE},
	"tremRate":      {"label": "RATE",         "min": 0.1,    "max": 30.0,    "step": 0.1,   "fmt": FMT_HZ1},
	"tremAttack":    {"label": "ATTACK",       "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"tremDecay":     {"label": "DECAY",        "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"arpRate":       {"label": "RATE",         "min": 1.0,    "max": 50.0,    "step": 0.5,   "fmt": FMT_HZ1},
	"arpStep1":      {"label": "STEP 2",       "min": -24.0,  "max": 24.0,    "step": 1.0,   "fmt": FMT_STEP},
	"arpStep2":      {"label": "STEP 3",       "min": -24.0,  "max": 24.0,    "step": 1.0,   "fmt": FMT_STEP},
	"arpStep3":      {"label": "STEP 4",       "min": -24.0,  "max": 24.0,    "step": 1.0,   "fmt": FMT_STEP},

	"delayTime":     {"label": "TIME",         "min": 10.0,   "max": 500.0,   "step": 1.0,   "fmt": FMT_MS},
	"delayFeedback": {"label": "FEEDBACK",     "min": 0.0,    "max": 0.9,     "step": 0.01,  "fmt": FMT_DEC2},
	"delayMix":      {"label": "MIX",          "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"crushBits":     {"label": "BIT DEPTH",    "min": 1.0,    "max": 16.0,    "step": 1.0,   "fmt": FMT_BITS},
	"crushRate":     {"label": "SAMPLE RATE",  "min": 1.0,    "max": 64.0,    "step": 1.0,   "fmt": FMT_CRUSH},

	"driveAmount":   {"label": "AMOUNT",       "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"driveMix":      {"label": "MIX",          "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"filterType":    {"label": "TYPE",         "min": 0.0,    "max": 2.0,     "step": 1.0,   "fmt": FMT_FILTER},
	"filterCutoff":  {"label": "CUTOFF",       "min": 50.0,   "max": 15000.0, "step": 1.0,   "fmt": FMT_HZ},
	"filterRes":     {"label": "RESONANCE",    "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"filterEnv":     {"label": "ENV",          "min": -1.0,   "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"filterAttack":  {"label": "ATTACK",       "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"filterDecay":   {"label": "DECAY",        "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"flangerDepth":    {"label": "DEPTH",      "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
	"flangerRate":     {"label": "RATE",        "min": 0.1,    "max": 10.0,    "step": 0.1,   "fmt": FMT_HZ1},
	"flangerFeedback": {"label": "FEEDBACK",    "min": -0.9,   "max": 0.9,     "step": 0.01,  "fmt": FMT_DEC2},
	"flangerMix":      {"label": "MIX",         "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},

	"chordNote1":      {"label": "NOTE 2",     "min": -24.0,  "max": 24.0,    "step": 1.0,   "fmt": FMT_STEP},
	"chordNote2":      {"label": "NOTE 3",     "min": -24.0,  "max": 24.0,    "step": 1.0,   "fmt": FMT_STEP},
	"chordNote3":      {"label": "NOTE 4",     "min": -24.0,  "max": 24.0,    "step": 1.0,   "fmt": FMT_STEP},
	"chordMix":        {"label": "MIX",         "min": 0.0,    "max": 1.0,     "step": 0.01,  "fmt": FMT_DEC2},
}

# Module rendering order. enable_key empty string ⇒ always-on module.
const MODULES: Array = [
	{"key": "source",   "title": "SOURCE",         "enable_key": "", "params": ["volume", "mode", "pitch", "voice", "detune"]},
	{"key": "amp",      "title": "AMP ENVELOPE",   "enable_key": "", "params": ["length", "ampAttack", "ampDecay", "ampSustain", "ampRelease"]},
	{"key": "drive",    "title": "DRIVE",          "enable_key": "driveEnabled",    "params": ["driveAmount", "driveMix"]},
	{"key": "filter",   "title": "FILTER",         "enable_key": "filterEnabled",   "params": ["filterType", "filterCutoff", "filterRes", "filterEnv", "filterAttack", "filterDecay"]},
	{"key": "pitchEnv", "title": "PITCH ENVELOPE", "enable_key": "pitchEnvEnabled", "params": ["pitchEnv", "pitchAttack", "pitchDecay"]},
	{"key": "vibrato",  "title": "VIBRATO",        "enable_key": "vibEnabled",      "params": ["pitchMod", "modShape", "modRate", "modAttack", "modDecay"]},
	{"key": "tremolo",  "title": "TREMOLO",        "enable_key": "tremEnabled",     "params": ["tremDepth", "tremShape", "tremRate", "tremAttack", "tremDecay"]},
	{"key": "arpeggio", "title": "ARPEGGIO",       "enable_key": "arpEnabled",      "params": ["arpRate", "arpStep1", "arpStep2", "arpStep3"]},
	{"key": "delay",    "title": "DELAY",          "enable_key": "delayEnabled",    "params": ["delayTime", "delayFeedback", "delayMix"]},
	{"key": "crush",    "title": "CRUSH",          "enable_key": "crushEnabled",    "params": ["crushBits", "crushRate"]},
	{"key": "flanger", "title": "FLANGER",        "enable_key": "flangerEnabled",  "params": ["flangerDepth", "flangerRate", "flangerFeedback", "flangerMix"]},
	{"key": "chord",   "title": "CHORD",          "enable_key": "chordEnabled",    "params": ["chordNote1", "chordNote2", "chordNote3", "chordMix"]},
]

# Default per-channel patch: instant attack + full-length decay matches the
# original (1-progress)^1.5 curve so legacy presets still sound right.
const DEFAULT_PARAMS: Dictionary = {
	"volume": 0.5, "mode": 0, "pitch": 440.0, "voice": 1, "detune": 0.0,
	"length": 0.4, "ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
	"pitchEnvEnabled": false,
	"pitchEnv": 0.3, "pitchAttack": 0.0, "pitchDecay": 0.5,
	"vibEnabled": false,
	"pitchMod": 0.1, "modShape": 3, "modRate": 6.0, "modAttack": 0.0, "modDecay": 1.0,
	"tremEnabled": false,
	"tremDepth": 0.5, "tremShape": 3, "tremRate": 8.0, "tremAttack": 0.0, "tremDecay": 1.0,
	"arpEnabled": false,
	"arpRate": 12.0, "arpStep1": 4, "arpStep2": 7, "arpStep3": 12,
	"delayEnabled": false,
	"delayTime": 150.0, "delayFeedback": 0.4, "delayMix": 0.4,
	"crushEnabled": false,
	"crushBits": 8, "crushRate": 4,
	"driveEnabled": false,
	"driveAmount": 0.4, "driveMix": 1.0,
	"filterEnabled": false,
	"filterType": 0, "filterCutoff": 5000.0, "filterRes": 0.0,
	"filterEnv": 0.0, "filterAttack": 0.0, "filterDecay": 0.5,
	"flangerEnabled": false,
	"flangerDepth": 0.5, "flangerRate": 0.5, "flangerFeedback": 0.3, "flangerMix": 0.5,
	"chordEnabled": false,
	"chordNote1": 4, "chordNote2": 7, "chordNote3": 12, "chordMix": 0.5,
	"level": 1.0, "muted": false, "soloed": false,
}

const DEFAULT_MASTER: Dictionary = {
	"masterVolume": 1.0, "reverbMix": 0.0, "reverbSize": 0.5,
}

# v7 channel field order — must match the JS schema for cross-compatibility
# of sound strings between the React app and this port.
const V7_CHANNEL_KEYS: Array[String] = [
	"volume", "mode", "pitch", "voice", "detune",
	"length", "ampAttack", "ampDecay", "ampSustain", "ampRelease",
	"pitchEnvEnabled", "pitchEnv", "pitchAttack", "pitchDecay",
	"vibEnabled", "pitchMod", "modShape", "modRate", "modAttack", "modDecay",
	"tremEnabled", "tremDepth", "tremShape", "tremRate", "tremAttack", "tremDecay",
	"arpEnabled", "arpRate", "arpStep1", "arpStep2", "arpStep3",
	"delayEnabled", "delayTime", "delayFeedback", "delayMix",
	"crushEnabled", "crushBits", "crushRate",
	"driveEnabled", "driveAmount", "driveMix",
	"filterEnabled", "filterType", "filterCutoff", "filterRes",
	"filterEnv", "filterAttack", "filterDecay",
	"flangerEnabled", "flangerDepth", "flangerRate", "flangerFeedback", "flangerMix",
	"chordEnabled", "chordNote1", "chordNote2", "chordNote3", "chordMix",
	"level", "muted", "soloed",
]
const V7_MASTER_KEYS: Array[String] = ["masterVolume", "reverbMix", "reverbSize"]


static func clone_params() -> Dictionary:
	return DEFAULT_PARAMS.duplicate(true)


static func clone_master() -> Dictionary:
	return DEFAULT_MASTER.duplicate(true)


static func default_sound() -> Dictionary:
	return {
		"channels": [clone_params()],
		"master": clone_master(),
	}


static func clone_sound(s: Dictionary) -> Dictionary:
	return s.duplicate(true)


# ── Value formatting (replaces JS Callable formatters) ──────────────

static func format_value(param_key: String, value: float) -> String:
	var def: Dictionary = PARAM_DEFS.get(param_key, {})
	var fmt: int = def.get("fmt", FMT_DEC2)
	match fmt:
		FMT_DEC2:
			return "%.2f" % value
		FMT_DEC3:
			return "%.3f" % value
		FMT_INT:
			return "%d" % int(round(value))
		FMT_HZ:
			if value >= 1000.0:
				return "%.1fkHz" % (value / 1000.0)
			return "%dHz" % int(round(value))
		FMT_HZ1:
			return "%.1fHz" % value
		FMT_MS:
			return "%dms" % int(round(value))
		FMT_SEC:
			return "%.2fs" % value
		FMT_MODE:
			var idx: int = clampi(int(round(value)), 0, MODES.size() - 1)
			return MODES[idx]
		FMT_FILTER:
			var types: Array[String] = ["LP", "HP", "BP"]
			var ti: int = clampi(int(round(value)), 0, 2)
			return types[ti]
		FMT_BITS:
			return "%dBIT" % int(round(value))
		FMT_CRUSH:
			var r: int = int(round(value))
			if r <= 1:
				return "44.1kHz"
			return "%.1fkHz" % (44100.0 / r / 1000.0)
		FMT_STEP:
			var v: int = int(round(value))
			return ("+%dst" % v) if v >= 0 else ("%dst" % v)
	return "%.2f" % value


# ── Sound string serialization ──────────────────────────────────────

static func _fmt_field(key: String, value) -> String:
	if typeof(value) == TYPE_BOOL:
		return "1" if value else "0"
	var def: Dictionary = PARAM_DEFS.get(key, {})
	if def.has("step") and def["step"] >= 1.0:
		return "%d" % int(round(float(value)))
	return "%.3f" % float(value)


static func sound_to_string(sound: Dictionary) -> String:
	var parts: Array[String] = ["sfx7", "%d" % sound.channels.size()]
	for k in V7_MASTER_KEYS:
		parts.append(_fmt_field(k, sound.master[k]))
	for ch in sound.channels:
		for k in V7_CHANNEL_KEYS:
			parts.append(_fmt_field(k, ch[k]))
	return ":".join(parts)


# Decode `count` fields starting at `offset`. Returns null on malformed input.
# `type_ref` provides the expected types so we know whether to parse bool/int.
static func _decode_keys(parts: PackedStringArray, offset: int, keys: Array, type_ref: Dictionary) -> Variant:
	var out: Dictionary = {}
	for i in keys.size():
		var k: String = keys[i]
		var idx: int = offset + i
		if idx >= parts.size():
			return null
		var raw: String = parts[idx]
		var ref_value = type_ref.get(k)
		if typeof(ref_value) == TYPE_BOOL:
			out[k] = raw == "1"
		elif typeof(ref_value) == TYPE_INT:
			if not raw.is_valid_int() and not raw.is_valid_float():
				return null
			out[k] = int(raw.to_float())
		else:
			if not raw.is_valid_float():
				return null
			out[k] = raw.to_float()
	return out


static func sound_from_string(s: String) -> Variant:
	var parts: PackedStringArray = s.strip_edges().split(":")
	if parts.size() < 1:
		return null

	# v7: multi-channel. Tolerates strings from older builds that may have
	# fewer channel fields (new params get their DEFAULT_PARAMS value).
	if parts[0] == "sfx7":
		if parts.size() < 2:
			return null
		var num_ch: int = int(parts[1])
		if num_ch < 1 or num_ch > MAX_CHANNELS:
			return null
		var header: int = 2 + V7_MASTER_KEYS.size()
		if parts.size() < header:
			return null
		var fields_per_ch: int = (parts.size() - header) / num_ch

		var master = _decode_keys(parts, 2, V7_MASTER_KEYS, DEFAULT_MASTER)
		if master == null:
			return null

		var channels: Array = []
		var off: int = header
		for i in num_ch:
			var keys_to_read: Array = V7_CHANNEL_KEYS.slice(0, mini(fields_per_ch, V7_CHANNEL_KEYS.size()))
			var ch = _decode_keys(parts, off, keys_to_read, DEFAULT_PARAMS)
			if ch == null:
				return null
			var merged: Dictionary = clone_params()
			merged.merge(ch, true)
			channels.append(merged)
			off += fields_per_ch

		var merged_master: Dictionary = clone_master()
		merged_master.merge(master, true)
		return {"channels": channels, "master": merged_master}

	# Older formats not supported in this port — copy a v7 string from the JS
	# app or upgrade once via the JS app first.
	return null


# ── WAV encoding ──────────────────────────────────────────────────

static func resample(samples: PackedFloat32Array, target_rate: int) -> PackedFloat32Array:
	if target_rate == SAMPLE_RATE:
		return samples
	var ratio: float = float(SAMPLE_RATE) / float(target_rate)
	var new_len: int = int(float(samples.size()) / ratio)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(new_len)
	for i in new_len:
		var src_pos: float = float(i) * ratio
		var idx: int = int(src_pos)
		var frac: float = src_pos - float(idx)
		var s0: float = samples[mini(idx, samples.size() - 1)]
		var s1: float = samples[mini(idx + 1, samples.size() - 1)]
		out[i] = s0 + (s1 - s0) * frac
	return out


static func encode_wav(samples: PackedFloat32Array, sample_rate: int = SAMPLE_RATE, bits: int = 16) -> PackedByteArray:
	var src: PackedFloat32Array = resample(samples, sample_rate)
	var bytes_per_sample: int = 1 if bits == 8 else 2
	var data_size: int = src.size() * bytes_per_sample
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(44 + data_size)

	var riff: PackedByteArray = "RIFF".to_ascii_buffer()
	var wave: PackedByteArray = "WAVE".to_ascii_buffer()
	var fmt:  PackedByteArray = "fmt ".to_ascii_buffer()
	var data: PackedByteArray = "data".to_ascii_buffer()
	for i in 4:
		buffer[i] = riff[i]
		buffer[8 + i] = wave[i]
		buffer[12 + i] = fmt[i]
		buffer[36 + i] = data[i]

	buffer.encode_u32(4, 36 + data_size)
	buffer.encode_u32(16, 16)
	buffer.encode_u16(20, 1)
	buffer.encode_u16(22, 1)
	buffer.encode_u32(24, sample_rate)
	buffer.encode_u32(28, sample_rate * bytes_per_sample)
	buffer.encode_u16(32, bytes_per_sample)
	buffer.encode_u16(34, bits)
	buffer.encode_u32(40, data_size)

	if bits == 8:
		for i in src.size():
			var v: float = clamp(src[i], -1.0, 1.0)
			buffer[44 + i] = int((v + 1.0) * 0.5 * 255.0)
	else:
		for i in src.size():
			var v: float = clamp(src[i], -1.0, 1.0)
			buffer.encode_s16(44 + i * 2, int(v * 32767.0))
	return buffer


static func normalize(samples: PackedFloat32Array) -> PackedFloat32Array:
	var peak: float = 0.0
	for i in samples.size():
		peak = maxf(peak, absf(samples[i]))
	if peak <= 0.0 or peak >= 1.0:
		return samples
	var gain: float = 1.0 / peak
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(samples.size())
	for i in samples.size():
		out[i] = samples[i] * gain
	return out
