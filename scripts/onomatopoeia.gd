class_name Onomatopoeia
extends RefCounted

# Maps written words like BOOM / tick / whoooosh to a single-channel patch.
# This is the "Lite" parser — single-channel only; multi-channel composition
# (e.g. "kaboom" = transient + body + tail) is reserved for a Pro pass.
#
# The phoneme inventory is intentionally crude (English-flavoured ASCII)
# but enough to cover the bulk of game-onomatopoeia. Locks are respected
# via Presets._apply_target — anything the user pinned is preserved.

const PLOSIVES   := {"B": true, "P": true, "T": true, "K": true, "D": true, "G": true, "C": true, "Q": true}
const FRICATIVES := {"F": true, "S": true, "H": true, "Z": true, "V": true, "X": true,
					"SH": true, "TH": true, "CH": true, "WH": true}
const NASALS     := {"M": true, "N": true, "NG": true}
const LIQUIDS    := {"L": true, "R": true}
# WH treated as a fricative for game-onomatopoeia: "whoosh", "whir" should
# read as noise, not a tonal glide. Pure-glide W/Y stay here.
const GLIDES     := {"W": true, "Y": true, "J": true}
const VOWELS     := {"A": true, "E": true, "I": true, "O": true, "U": true}

# Pitch + cutoff per vowel — cutoff approximates formant brightness using
# the state-variable filter we already have (no real formant DSP yet).
const VOWEL_PITCH  := {"A": 200.0, "E": 300.0, "I": 400.0, "O": 180.0, "U": 120.0}
const VOWEL_CUTOFF := {"A": 2500.0, "E": 3500.0, "I": 4000.0, "O": 2000.0, "U": 1500.0}

# Digraphs that bind first during tokenisation. Two letters consumed before
# falling back to single-letter matching.
const DIGRAPHS := ["SH", "TH", "CH", "WH", "NG"]


# Public entry point. Returns a merged channel params dict; locked keys are
# passed through unchanged.
static func text_to_patch(text: String, params: Dictionary, locked: Dictionary) -> Dictionary:
	var phonemes: Array = tokenize(text)
	if phonemes.is_empty():
		return params.duplicate(true)
	var target: Dictionary = _build_target(phonemes)
	return Presets._apply_target(params, locked, Presets._off_with(target))


# Greedy left-to-right tokenisation. Anything outside the phoneme tables
# (digits, punctuation) is silently dropped.
static func tokenize(text: String) -> Array:
	var s: String = text.to_upper()
	var out: Array = []
	var i: int = 0
	while i < s.length():
		var matched: bool = false
		for d in DIGRAPHS:
			if s.substr(i, 2) == d:
				out.append(d)
				i += 2
				matched = true
				break
		if matched:
			continue
		var ch: String = s.substr(i, 1)
		if _is_known(ch):
			out.append(ch)
		i += 1
	return out


# Human-readable summary of the parsed phonemes — handy for status flashes.
static func describe(phonemes: Array) -> String:
	if phonemes.is_empty():
		return ""
	return "·".join(phonemes)


static func _is_known(p: String) -> bool:
	return PLOSIVES.has(p) or FRICATIVES.has(p) or NASALS.has(p) \
		or LIQUIDS.has(p) or GLIDES.has(p) or VOWELS.has(p)


static func _category(p: String) -> String:
	if VOWELS.has(p):     return "VOWEL"
	if PLOSIVES.has(p):   return "PLOSIVE"
	if FRICATIVES.has(p): return "FRICATIVE"
	if NASALS.has(p):     return "NASAL"
	if LIQUIDS.has(p):    return "LIQUID"
	if GLIDES.has(p):     return "GLIDE"
	return ""


# Build the target params dict from a phoneme list.
static func _build_target(phonemes: Array) -> Dictionary:
	var counts: Dictionary = {"VOWEL": 0, "PLOSIVE": 0, "FRICATIVE": 0, "NASAL": 0, "LIQUID": 0, "GLIDE": 0}
	var leading_cat: String = _category(phonemes[0])
	var trailing_cat: String = _category(phonemes[-1])
	var vowels_seen: Array = []
	var repeat_bonus: int = 0
	var prev: String = ""
	for p in phonemes:
		counts[_category(p)] = counts[_category(p)] + 1
		if VOWELS.has(p):
			vowels_seen.append(p)
		if p == prev:
			repeat_bonus += 1
		prev = p

	# Average vowel pitch + cutoff. Fallback if no vowels.
	var dom_pitch: float = 220.0
	var dom_cutoff: float = 2500.0
	if not vowels_seen.is_empty():
		var sum_p: float = 0.0
		var sum_c: float = 0.0
		for v in vowels_seen:
			sum_p += float(VOWEL_PITCH[v])
			sum_c += float(VOWEL_CUTOFF[v])
		dom_pitch = sum_p / float(vowels_seen.size())
		dom_cutoff = sum_c / float(vowels_seen.size())

	var has_vowel: bool = counts.VOWEL > 0
	var leading_plosive: bool = leading_cat == "PLOSIVE"
	var leading_fricative: bool = leading_cat == "FRICATIVE"
	var trailing_fricative: bool = trailing_cat == "FRICATIVE"

	# Branch is decided by the LEADING phoneme — that's what gives a word its
	# character ("ahhh" = vowel-led even with trailing H's; "whoosh" =
	# fricative-led because WH leads). Per-branch base length keeps "tick"
	# snappy and sustained vowels long.
	var base_length: float
	if not has_vowel and counts.FRICATIVE > 0:
		base_length = 0.30
	elif leading_fricative:
		base_length = 0.30
	elif leading_plosive and has_vowel:
		base_length = 0.15
	else:
		base_length = 0.40

	var length: float = base_length + 0.20 * float(repeat_bonus)
	if trailing_fricative and not leading_fricative:
		length += 0.15
	length = clampf(length, 0.05, 4.0)

	var t: Dictionary = {
		"volume": 0.5,
		"voice": 1, "detune": 0.0,
		"length": length,
		"ampAttack": 0.0, "ampDecay": 1.0, "ampSustain": 0.0, "ampRelease": 0.0,
	}

	if not has_vowel and counts.FRICATIVE > 0:
		# Pure fricative ("hsss", "shh") → noise + HP filter.
		t["mode"] = 4
		t["pitch"] = 400.0
		t["filterEnabled"] = true
		t["filterType"] = 1
		t["filterCutoff"] = 4500.0
		t["filterRes"] = 0.2
	elif leading_fricative:
		# Fricative-led ("whoosh", "splash", "hush") → noise body, HP filter.
		t["mode"] = 4
		t["pitch"] = dom_pitch
		t["filterEnabled"] = true
		t["filterType"] = 1
		t["filterCutoff"] = clampf(dom_cutoff + 1500.0, 2000.0, 8000.0)
		t["filterRes"] = 0.15
		t["ampAttack"] = 0.05
	elif leading_plosive and has_vowel:
		# Classic "boom" / "thud" / "pop" — tonal body, pitch dive, drive.
		t["mode"] = 0  # square
		t["pitch"] = dom_pitch
		t["pitchEnvEnabled"] = true
		t["pitchEnv"] = -0.5
		t["pitchAttack"] = 0.0
		t["pitchDecay"] = 0.7
		t["driveEnabled"] = true
		t["driveAmount"] = 0.4
		t["driveMix"] = 1.0
		t["filterEnabled"] = true
		t["filterType"] = 0
		t["filterCutoff"] = dom_cutoff
		t["filterRes"] = 0.2
	else:
		# Vowel-led / nasal-led / glide-led / liquid-led — sustained tonal.
		# Even a trailing fricative ("ahhh", "ouch") doesn't change the mode
		# here — the leading vowel/sonorant carries the character.
		t["mode"] = 3  # sine
		t["pitch"] = dom_pitch
		t["filterEnabled"] = true
		t["filterType"] = 0
		t["filterCutoff"] = dom_cutoff
		t["filterRes"] = 0.1
		if leading_cat == "GLIDE" or leading_cat == "LIQUID" or leading_cat == "NASAL":
			t["ampAttack"] = 0.15

	# Repeated vowels lengthen sustain so the body doesn't decay before the
	# repeats are "spent".
	if repeat_bonus > 0:
		t["ampSustain"] = clampf(0.4 + 0.15 * float(repeat_bonus), 0.0, 1.0)

	return t
