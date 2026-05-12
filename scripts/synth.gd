class_name Synth
extends RefCounted

# Pure synthesis. Each effect is a (samples, params) → samples function.
# Composition: source(raw) → drive → filter → amp env → tremolo → delay → crush
# Drive and filter run before the amp envelope so they operate on a constant-
# amplitude signal (predictable saturation, stable resonance).

const SAMPLE_RATE: int = 44100


# ── Primitives ─────────────────────────────────────────────────────

# Returns one cycle of a unit-amplitude waveform sampled at `phase` ∈ [0, 1).
# All branches output in [-1, 1]. Mode IDs match SoundData.MODES order.
#
#   0 SQR — 50% duty square: +1 for phase < 0.5, else -1.
#   1 SAW — rising sawtooth: -1 at phase 0, +1 at phase 1.
#   2 TRI — symmetric triangle: -1 → +1 → -1 with peak at phase 0.5.
#         First half rises:  4·phase − 1     (= -1 at 0, 0 at 0.25, +1 at 0.5)
#         Second half falls: 3 − 4·phase     (= +1 at 0.5, 0 at 0.75, -1 at 1)
#         The two halves meet continuously at phase 0.5 (both yield +1).
#   3 SIN — pure sine over one full period (sin(2π·phase)).
#   4 NSE — uncorrelated white noise. Phase is ignored here; the source loop
#           handles per-voice band-limiting (see generate_dry_samples()).
static func waveform_at(mode: int, phase: float) -> float:
	match mode:
		0:
			return 1.0 if phase < 0.5 else -1.0
		1:
			return 2.0 * phase - 1.0
		2:
			return (4.0 * phase - 1.0) if phase < 0.5 else (3.0 - 4.0 * phase)
		3:
			return sin(phase * TAU)
		4, 5, 6:
			return randf() * 2.0 - 1.0
	return 0.0


# AD envelope (rise then fall). Both values are fractions of total length.
static func envelope_value(progress: float, attack: float, decay: float) -> float:
	if attack <= 0.0 and decay <= 0.0:
		return 0.0
	if progress < attack:
		return progress / attack if attack > 0.0 else 1.0
	if decay <= 0.0:
		return 0.0
	var phase: float = progress - attack
	if phase >= decay:
		return 0.0
	return 1.0 - phase / decay


# ADSR amp envelope. Decay/release use a mild ^1.5 curve so percussive sounds
# feel natural. If A+D+R > 1 the segments are scaled down proportionally.
static func adsr_value(progress: float, attack: float, decay: float, sustain: float, release: float) -> float:
	var total: float = attack + decay + release
	var scale: float = 1.0 / total if total > 1.0 else 1.0
	var a: float = attack * scale
	var d: float = decay * scale
	var r: float = release * scale
	var sustain_start: float = a + d
	var release_start: float = 1.0 - r

	if progress < a:
		return progress / a
	if progress < sustain_start:
		if d <= 0.0:
			return sustain
		var t: float = (progress - a) / d
		return sustain + (1.0 - sustain) * pow(1.0 - t, 1.5)
	if progress < release_start:
		return sustain
	if r > 0.0:
		var t: float = (progress - release_start) / r
		return sustain * pow(1.0 - t, 1.5)
	return 0.0


# ── Source: dry samples with pitch env, vibrato, arpeggio, voices, detune ──

static func generate_dry_samples(p: Dictionary) -> PackedFloat32Array:
	var total: int = max(1, int(float(p.length) * SAMPLE_RATE))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)

	var voice: int = int(p.voice)
	var phases: PackedFloat32Array = PackedFloat32Array()
	phases.resize(voice)

	var mod_phase: float = 0.0

	var arp_steps: Array = [0, int(p.arpStep1), int(p.arpStep2), int(p.arpStep3)]

	var pitch_env_enabled: bool = bool(p.pitchEnvEnabled)
	var arp_enabled: bool = bool(p.arpEnabled)
	var vib_enabled: bool = bool(p.vibEnabled)
	var pitch: float = float(p.pitch)
	var p_pitch_env: float = float(p.pitchEnv)
	var p_pitch_attack: float = float(p.pitchAttack)
	var p_pitch_decay: float = float(p.pitchDecay)
	var p_arp_rate: float = float(p.arpRate)
	var p_mod_rate: float = float(p.modRate)
	var p_pitch_mod: float = float(p.pitchMod)
	var p_mod_attack: float = float(p.modAttack)
	var p_mod_decay: float = float(p.modDecay)
	var p_mod_shape: int = int(p.modShape)
	var p_mode: int = int(p.mode)
	var p_detune: float = float(p.detune)

	var inv_sr: float = 1.0 / float(SAMPLE_RATE)
	var inv_total: float = 1.0 / float(total)

	for i in total:
		var t: float = float(i) * inv_sr
		var progress: float = float(i) * inv_total

		var base_freq: float = pitch
		if pitch_env_enabled:
			var p_env: float = envelope_value(progress, p_pitch_attack, p_pitch_decay)
			# pitchEnv is normalised [-1, 1]; the ×2.0 below makes a full ±1
			# value sweep ±2 octaves at envelope peak (pow(2, ±2)).
			base_freq = base_freq * pow(2.0, p_pitch_env * p_env * 2.0)

		if arp_enabled:
			var step_index: int = int(t * p_arp_rate) % 4
			var semitones: float = float(arp_steps[step_index])
			base_freq *= pow(2.0, semitones / 12.0)

		var mod_value: float = 0.0
		if vib_enabled and p_mod_rate > 0.0 and p_pitch_mod > 0.0:
			mod_phase = fmod(mod_phase + p_mod_rate * inv_sr, 1.0)
			var m_env: float = envelope_value(progress, p_mod_attack, p_mod_decay)
			mod_value = waveform_at(p_mod_shape, mod_phase) * p_pitch_mod * m_env

		var sample: float = 0.0
		for v in voice:
			var detune_factor: float = 1.0
			if voice > 1:
				detune_factor = 1.0 + p_detune * (float(v) / float(voice - 1) - 0.5)
			var v_freq: float = base_freq * detune_factor * (1.0 + mod_value)
			phases[v] = fmod(phases[v] + v_freq * inv_sr, 1.0)
			sample += waveform_at(p_mode, phases[v])
		sample /= float(voice)

		out[i] = sample

	if p_mode == 4:
		var lp_a: float = 0.25
		var lp_prev: float = 0.0
		for i in total:
			lp_prev = lp_a * lp_prev + (1.0 - lp_a) * out[i]
			out[i] = lp_prev
	elif p_mode == 5:
		# Pink noise: Paul Kellet approximation (−3 dB/octave).
		var b0: float = 0.0
		var b1: float = 0.0
		var b2: float = 0.0
		var b3: float = 0.0
		var b4: float = 0.0
		var b5: float = 0.0
		for i in total:
			var white: float = out[i]
			b0 = 0.99886 * b0 + white * 0.0555179
			b1 = 0.99332 * b1 + white * 0.0750759
			b2 = 0.96900 * b2 + white * 0.1538520
			b3 = 0.86650 * b3 + white * 0.3104856
			b4 = 0.55000 * b4 + white * 0.5329522
			b5 = -0.7616 * b5 - white * 0.0168980
			out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + white * 0.5362) * 0.11
	elif p_mode == 6:
		# Brown noise: integrated white noise (−6 dB/octave) with leak.
		var prev: float = 0.0
		for i in total:
			prev = prev * 0.998 + out[i] * 0.02
			out[i] = prev * 8.0

	return out


# ── Effect chain ───────────────────────────────────────────────────

static func apply_amp_env(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	var n: int = samples.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var volume: float = float(p.volume)
	var atk: float = float(p.ampAttack)
	var dec: float = float(p.ampDecay)
	var sus: float = float(p.ampSustain)
	var rel: float = float(p.ampRelease)
	var inv_n: float = 1.0 / float(n)
	for i in n:
		var progress: float = float(i) * inv_n
		var env: float = adsr_value(progress, atk, dec, sus, rel)
		out[i] = samples[i] * env * volume
	return out


static func apply_drive(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	if not bool(p.driveEnabled) or float(p.driveAmount) <= 0.0:
		return samples
	var n: int = samples.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	# Drive amount [0, 1] → input gain [1, 10]. With tanh saturation the
	# top end is heavy (~20 dB pre-gain) — `norm = tanh(drive_lin)` rescales
	# the wet signal so peak amplitude stays near unity regardless of drive.
	var drive_lin: float = 1.0 + float(p.driveAmount) * 9.0
	var norm: float = tanh(drive_lin)
	var wet: float = float(p.driveMix)
	var dry: float = 1.0 - wet
	for i in n:
		var x: float = samples[i]
		var y: float = tanh(x * drive_lin) / norm
		out[i] = y * wet + x * dry
	return out


# Chamberlin state-variable filter; LP/HP/BP from one structure. Cutoff is
# modulated per-sample by an AD envelope. Resonance ↦ damping (max usable
# Q ≈ 10 — strong "wub" without unstable self-oscillation).
static func apply_filter(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	if not bool(p.filterEnabled):
		return samples
	var n: int = samples.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	var bp: float = 0.0
	# Resonance [0, 1] → damping coefficient [2.0, 0.1]. Damping ≈ 1/Q in the
	# Chamberlin form, so filterRes=0 gives Q≈0.5 (no peak), filterRes=1 gives
	# Q≈10 (sharp resonance, just under self-oscillation). The 1.9 (vs 2.0)
	# leaves a safety margin so q1 never reaches 0 even with float rounding.
	var q1: float = 2.0 - float(p.filterRes) * 1.9
	# Chamberlin SVF is stable up to fc ≈ SR/4 (≈11 kHz @ 44.1k); beyond that
	# the trapezoidal integrator alias-folds the cutoff and the resonance
	# blows up. fc_max keeps us well clear of that boundary.
	var fc_max: float = float(SAMPLE_RATE) * 0.25
	var type_id: int = int(p.filterType)
	var base_cutoff: float = float(p.filterCutoff)
	var env_amount: float = float(p.filterEnv)
	var env_attack: float = float(p.filterAttack)
	var env_decay: float = float(p.filterDecay)
	var inv_n: float = 1.0 / float(n)

	for i in n:
		var progress: float = float(i) * inv_n
		var env: float = envelope_value(progress, env_attack, env_decay)
		# filterEnv is [-1, 1]; the ×4.0 below maps a full envelope to a
		# ±4-octave cutoff sweep at the peak — wide enough for classic
		# "wub" and snare-like tightening without runaway.
		var cutoff: float = base_cutoff * pow(2.0, env_amount * env * 4.0)
		var fc_clamped: float = clamp(cutoff, 20.0, fc_max)
		# Chamberlin SVF tuning coefficient. 2·sin(π·fc/SR) is the standard
		# trapezoidal approximation of the analog tuning frequency.
		var f: float = 2.0 * sin(PI * fc_clamped / float(SAMPLE_RATE))

		var hp: float = samples[i] - q1 * bp - lp
		bp = bp + f * hp
		lp = lp + f * bp

		match type_id:
			0:
				out[i] = lp
			1:
				out[i] = hp
			_:
				out[i] = bp
	return out


static func apply_tremolo(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	if not bool(p.tremEnabled):
		return samples
	var n: int = samples.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	var rate: float = float(p.tremRate)
	var depth: float = float(p.tremDepth)
	var atk: float = float(p.tremAttack)
	var dec: float = float(p.tremDecay)
	var shape: int = int(p.tremShape)
	var inv_sr: float = 1.0 / float(SAMPLE_RATE)
	var inv_n: float = 1.0 / float(n)
	for i in n:
		var progress: float = float(i) * inv_n
		phase = fmod(phase + rate * inv_sr, 1.0)
		var env: float = envelope_value(progress, atk, dec)
		var lfo: float = (waveform_at(shape, phase) + 1.0) * 0.5
		var amp: float = 1.0 - depth * env * lfo
		out[i] = samples[i] * amp
	return out


static func apply_delay(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	if not bool(p.delayEnabled) or float(p.delayMix) <= 0.0:
		return samples
	var feedback: float = float(p.delayFeedback)
	var mix: float = float(p.delayMix)
	var delay_samples: int = max(1, int(float(p.delayTime) / 1000.0 * float(SAMPLE_RATE)))

	# Compute how many repeats to fade out to ~−60 dB before truncating.
	var min_level: float = 0.001
	var tail_repeats: int = 0
	if feedback > 0.0:
		var level: float = 1.0
		while level > min_level and tail_repeats < 50:
			level *= feedback
			tail_repeats += 1
	else:
		tail_repeats = 1

	var total_len: int = samples.size() + delay_samples * (tail_repeats + 1)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total_len)

	var dry_gain: float = 1.0 - mix * 0.5
	for i in samples.size():
		out[i] = samples[i] * dry_gain

	# Each echo passes through a one-pole IIR lowpass before being summed in.
	# Real tape/spring delays lose a few kHz on every round trip; without this
	# the repeats stay as bright as the source and feel brittle. We apply the
	# filter cumulatively (in place) so the Nth repeat has been LP'd N times,
	# producing the natural "echo getting warmer as it dies" curve.
	# damp = 0.5 places the per-pass −3 dB point near 5 kHz at 44.1 kHz SR —
	# musical without muddying the first repeat.
	var damp: float = 0.5
	var filtered: PackedFloat32Array = samples.duplicate()

	var lvl: float = mix
	var offset: int = delay_samples
	for r in tail_repeats + 1:
		if lvl < min_level:
			break
		if r > 0:
			# Apply one more LP pass before the next repeat (first echo is dry).
			var prev: float = 0.0
			for i in filtered.size():
				prev = damp * prev + (1.0 - damp) * filtered[i]
				filtered[i] = prev
		var lim: int = samples.size()
		for i in lim:
			var dst: int = i + offset
			if dst >= total_len:
				break
			out[dst] += filtered[i] * lvl
		lvl *= feedback
		offset += delay_samples
	return out


static func apply_crush(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	if not bool(p.crushEnabled):
		return samples
	var n: int = samples.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var bits: int = int(p.crushBits)
	var levels: float = pow(2.0, bits - 1)
	var crush_rate: int = max(1, int(p.crushRate))
	var dither_amp: float = (1.0 / levels) if bits < 16 else 0.0
	var last_sample: float = 0.0
	for i in n:
		var v: float = samples[i]
		if bits < 16:
			v += (randf() - randf()) * dither_amp
			v = round(v * levels) / levels
		if crush_rate > 1:
			if i % crush_rate == 0:
				last_sample = v
			else:
				v = last_sample
		out[i] = v
	return out


static func apply_chord(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	if not bool(p.get("chordEnabled", false)) or float(p.get("chordMix", 0.0)) <= 0.0:
		return samples
	var mix: float = float(p.chordMix)
	var notes: Array[int] = [int(p.chordNote1), int(p.chordNote2), int(p.chordNote3)]
	var n: int = samples.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var dry_gain: float = 1.0 - mix * 0.5
	for i in n:
		out[i] = samples[i] * dry_gain

	for note in notes:
		if note == 0:
			continue
		var ratio: float = pow(2.0, float(note) / 12.0)
		var wet_gain: float = mix / 3.0
		for i in n:
			var src_pos: float = float(i) * ratio
			var idx: int = int(src_pos)
			if idx >= n - 1:
				break
			var frac: float = src_pos - float(idx)
			out[i] += (samples[idx] * (1.0 - frac) + samples[idx + 1] * frac) * wet_gain
	return out


static func apply_flanger(samples: PackedFloat32Array, p: Dictionary) -> PackedFloat32Array:
	if not bool(p.get("flangerEnabled", false)) or float(p.get("flangerMix", 0.0)) <= 0.0:
		return samples
	var n: int = samples.size()
	var depth: float = float(p.flangerDepth)
	var rate: float = float(p.flangerRate)
	var feedback: float = float(p.flangerFeedback)
	var mix: float = float(p.flangerMix)

	var base_delay_s: float = 0.003
	var mod_range_s: float = depth * 0.007
	var max_delay: int = int(ceil((base_delay_s + mod_range_s) * SAMPLE_RATE)) + 2
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(max_delay)
	var write_idx: int = 0

	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var dry_gain: float = 1.0 - mix * 0.5

	for i in n:
		var lfo_phase: float = float(i) / float(SAMPLE_RATE) * rate
		var lfo: float = (sin(lfo_phase * TAU) + 1.0) * 0.5
		var delay_s: float = base_delay_s + lfo * mod_range_s
		var delay_samples: float = delay_s * float(SAMPLE_RATE)

		var read_pos: float = float(write_idx) - delay_samples
		if read_pos < 0.0:
			read_pos += float(max_delay)
		var idx0: int = int(read_pos) % max_delay
		var idx1: int = (idx0 + 1) % max_delay
		var frac: float = read_pos - floor(read_pos)
		var delayed: float = buf[idx0] * (1.0 - frac) + buf[idx1] * frac

		var input_val: float = samples[i] + delayed * feedback
		buf[write_idx] = input_val
		write_idx = (write_idx + 1) % max_delay
		out[i] = samples[i] * dry_gain + delayed * mix
	return out


# ── Master bus ─────────────────────────────────────────────────────

# Schroeder reverb: 4 parallel comb filters into 2 series allpasses. The
# comb / allpass delay lengths are Schroeder's classic "Freeverb-ish" prime
# values (~25–31 ms combs, 5–13 ms allpasses) chosen so their sums and
# differences don't share strong common factors — that decorrelates the
# echoes and avoids the metallic ringing a single comb produces.
const REVERB_COMB_DELAYS: Array[int] = [1116, 1188, 1277, 1356]
const REVERB_AP_DELAYS: Array[int] = [225, 556]

static func apply_reverb(samples: PackedFloat32Array, master: Dictionary) -> PackedFloat32Array:
	var reverb_mix: float = float(master.reverbMix)
	if reverb_mix <= 0.0:
		return samples

	var size: float = float(master.reverbSize)
	# Comb feedback determines RT60. 0.7…0.98 maps "small room" → "long hall";
	# we cap at 0.98 (size=1) because ≥1.0 makes the comb self-oscillate.
	var comb_feedback: float = 0.7 + size * 0.28
	# Allpass feedback fixed at 0.5 — the canonical Schroeder value. It
	# diffuses without colouring; raising it makes the tail flutter.
	var ap_feedback: float = 0.5
	# Tail length: 0.5 s (size=0) up to 3.0 s (size=1). Matches typical
	# game-friendly reverb ranges.
	var tail_samples: int = int(float(SAMPLE_RATE) * (0.5 + size * 2.5))
	var total_len: int = samples.size() + tail_samples
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total_len)

	var comb_bufs: Array = []
	var comb_idx: Array[int] = [0, 0, 0, 0]
	for d in REVERB_COMB_DELAYS:
		var buf: PackedFloat32Array = PackedFloat32Array()
		buf.resize(d)
		comb_bufs.append(buf)
	var ap_bufs: Array = []
	var ap_idx: Array[int] = [0, 0]
	for d in REVERB_AP_DELAYS:
		var buf: PackedFloat32Array = PackedFloat32Array()
		buf.resize(d)
		ap_bufs.append(buf)

	var wet: float = reverb_mix
	# Soft dry compensation: as wet rises we duck the dry only 40% to keep
	# perceived loudness roughly constant (full ducking would feel like a
	# sidechain pump, no ducking would clip on dense material).
	var dry: float = 1.0 - wet * 0.4

	var n_in: int = samples.size()
	for i in total_len:
		var input_sample: float = samples[i] if i < n_in else 0.0

		var comb_out: float = 0.0
		for c in 4:
			var buf: PackedFloat32Array = comb_bufs[c]
			var idx: int = comb_idx[c]
			var delayed: float = buf[idx]
			buf[idx] = input_sample + delayed * comb_feedback
			comb_idx[c] = (idx + 1) % REVERB_COMB_DELAYS[c]
			comb_out += delayed
		comb_out *= 0.25

		var ap_out: float = comb_out
		for a in 2:
			var buf2: PackedFloat32Array = ap_bufs[a]
			var idx2: int = ap_idx[a]
			var delayed2: float = buf2[idx2]
			var new_val: float = ap_out + delayed2 * ap_feedback
			buf2[idx2] = new_val
			ap_idx[a] = (idx2 + 1) % REVERB_AP_DELAYS[a]
			ap_out = delayed2 - new_val * ap_feedback

		out[i] = input_sample * dry + ap_out * wet
	return out


static func apply_master_volume(samples: PackedFloat32Array, master: Dictionary) -> PackedFloat32Array:
	var v: float = float(master.masterVolume)
	if is_equal_approx(v, 1.0):
		return samples
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(samples.size())
	for i in samples.size():
		out[i] = samples[i] * v
	return out


# Always-on safety limiter. Linear below |x|=0.9, soft tanh above.
static func apply_limiter(samples: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = samples.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for i in n:
		var x: float = samples[i]
		var ax: float = abs(x)
		if ax < 0.9:
			out[i] = x
			continue
		var sgn: float = -1.0 if x < 0.0 else 1.0
		out[i] = sgn * (0.9 + 0.1 * tanh((ax - 0.9) * 10.0))
	return out


# ── Compose ────────────────────────────────────────────────────────

static func render_channel(p: Dictionary) -> PackedFloat32Array:
	var buf: PackedFloat32Array = generate_dry_samples(p)
	buf = apply_drive(buf, p)
	buf = apply_filter(buf, p)
	buf = apply_amp_env(buf, p)
	buf = apply_tremolo(buf, p)
	buf = apply_delay(buf, p)
	buf = apply_crush(buf, p)
	buf = apply_chord(buf, p)
	buf = apply_flanger(buf, p)
	return buf


# Mute/solo: if any channel is soloed, only soloed (and unmuted) channels are
# heard; otherwise all unmuted channels play.
static func render_sound(sound: Dictionary) -> PackedFloat32Array:
	var channels: Array = sound.get("channels", [])
	if channels.is_empty():
		return PackedFloat32Array()

	var any_soloed: bool = false
	for c in channels:
		if bool(c.get("soloed", false)):
			any_soloed = true
			break

	var active: Array = []
	for c in channels:
		var muted: bool = bool(c.get("muted", false))
		var soloed: bool = bool(c.get("soloed", false))
		if muted:
			continue
		if any_soloed and not soloed:
			continue
		active.append(c)

	if active.is_empty():
		return PackedFloat32Array()

	var rendered: Array = []
	var total_len: int = 0
	for c in active:
		var r: PackedFloat32Array = render_channel(c)
		rendered.append(r)
		total_len = max(total_len, r.size())

	var summed: PackedFloat32Array = PackedFloat32Array()
	summed.resize(total_len)
	for ci in rendered.size():
		var r: PackedFloat32Array = rendered[ci]
		var lvl: float = float(active[ci].get("level", 1.0))
		for i in r.size():
			summed[i] += r[i] * lvl

	var master: Dictionary = sound.get("master", SoundData.clone_master())
	var buf: PackedFloat32Array = apply_reverb(summed, master)
	buf = apply_master_volume(buf, master)
	buf = apply_limiter(buf)
	return buf
