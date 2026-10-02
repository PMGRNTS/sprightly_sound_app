// Pure synthesis. Port of scripts/synth.gd — each effect is a
// (samples, params) → samples function.
// Chain: source → drive → filter → amp env → tremolo → delay → crush →
// chord → flanger. Drive and filter run before the amp envelope so they
// see a constant-amplitude signal (predictable saturation, stable
// resonance).

import { SAMPLE_RATE, cloneMaster, roundHalfAway, clamp } from './sound-data.js';

const TAU = Math.PI * 2;

// ── Primitives ─────────────────────────────────────────────────────

// One cycle of a unit-amplitude waveform at phase ∈ [0, 1). Mode IDs match
// MODES: SQR, SAW, TRI, SIN, then three noise colours (white source here;
// pink/brown shaping happens after the voice loop).
export function waveformAt(mode, phase) {
  switch (mode) {
    case 0: return phase < 0.5 ? 1 : -1;
    case 1: return 2 * phase - 1;
    case 2: return phase < 0.5 ? 4 * phase - 1 : 3 - 4 * phase;
    case 3: return Math.sin(phase * TAU);
    case 4: case 5: case 6: return Math.random() * 2 - 1;
  }
  return 0;
}

// AD envelope (rise then fall). Both values are fractions of total length.
export function envelopeValue(progress, attack, decay) {
  if (attack <= 0 && decay <= 0) return 0;
  if (progress < attack) return attack > 0 ? progress / attack : 1;
  if (decay <= 0) return 0;
  const phase = progress - attack;
  if (phase >= decay) return 0;
  return 1 - phase / decay;
}

// ADSR amp envelope. Decay/release use a mild ^1.5 curve so percussive
// sounds feel natural. If A+D+R > 1 the segments scale down to fit.
export function adsrValue(progress, attack, decay, sustain, release) {
  const total = attack + decay + release;
  const scale = total > 1 ? 1 / total : 1;
  const a = attack * scale;
  const d = decay * scale;
  const r = release * scale;
  const sustainStart = a + d;
  const releaseStart = 1 - r;

  if (progress < a) return progress / a;
  if (progress < sustainStart) {
    if (d <= 0) return sustain;
    const t = (progress - a) / d;
    return sustain + (1 - sustain) * Math.pow(1 - t, 1.5);
  }
  if (progress < releaseStart) return sustain;
  if (r > 0) {
    const t = (progress - releaseStart) / r;
    return sustain * Math.pow(1 - t, 1.5);
  }
  return 0;
}

// ── Source: pitch env, vibrato, arpeggio, voices, detune ──────────

export function generateDrySamples(p) {
  const total = Math.max(1, Math.floor(p.length * SAMPLE_RATE));
  const out = new Float32Array(total);

  const voice = Math.trunc(p.voice);
  const phases = new Float64Array(voice);
  let modPhase = 0;
  const arpSteps = [0, Math.trunc(p.arpStep1), Math.trunc(p.arpStep2), Math.trunc(p.arpStep3)];

  const pitchEnvEnabled = !!p.pitchEnvEnabled;
  const arpEnabled = !!p.arpEnabled;
  const vibEnabled = !!p.vibEnabled;
  const mode = Math.trunc(p.mode);
  const modShape = Math.trunc(p.modShape);
  const invSr = 1 / SAMPLE_RATE;
  const invTotal = 1 / total;

  for (let i = 0; i < total; i++) {
    const t = i * invSr;
    const progress = i * invTotal;

    let baseFreq = p.pitch;
    if (pitchEnvEnabled) {
      const env = envelopeValue(progress, p.pitchAttack, p.pitchDecay);
      // pitchEnv ∈ [-1, 1]; ×2 makes a full value sweep ±2 octaves at peak.
      baseFreq *= Math.pow(2, p.pitchEnv * env * 2);
    }

    if (arpEnabled) {
      const stepIndex = Math.trunc(t * p.arpRate) % 4;
      baseFreq *= Math.pow(2, arpSteps[stepIndex] / 12);
    }

    let modValue = 0;
    if (vibEnabled && p.modRate > 0 && p.pitchMod > 0) {
      modPhase = (modPhase + p.modRate * invSr) % 1;
      const env = envelopeValue(progress, p.modAttack, p.modDecay);
      modValue = waveformAt(modShape, modPhase) * p.pitchMod * env;
    }

    let sample = 0;
    for (let v = 0; v < voice; v++) {
      const detuneFactor = voice > 1 ? 1 + p.detune * (v / (voice - 1) - 0.5) : 1;
      const vFreq = baseFreq * detuneFactor * (1 + modValue);
      phases[v] = (phases[v] + vFreq * invSr) % 1;
      sample += waveformAt(mode, phases[v]);
    }
    out[i] = sample / voice;
  }

  if (mode === 4) {
    // White noise: gentle one-pole lowpass takes the fizz off.
    let prev = 0;
    for (let i = 0; i < total; i++) {
      prev = 0.25 * prev + 0.75 * out[i];
      out[i] = prev;
    }
  } else if (mode === 5) {
    // Pink noise: Paul Kellet approximation (−3 dB/octave).
    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0;
    for (let i = 0; i < total; i++) {
      const w = out[i];
      b0 = 0.99886 * b0 + w * 0.0555179;
      b1 = 0.99332 * b1 + w * 0.0750759;
      b2 = 0.96900 * b2 + w * 0.1538520;
      b3 = 0.86650 * b3 + w * 0.3104856;
      b4 = 0.55000 * b4 + w * 0.5329522;
      b5 = -0.7616 * b5 - w * 0.0168980;
      out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + w * 0.5362) * 0.11;
    }
  } else if (mode === 6) {
    // Brown noise: leaky integrated white noise (−6 dB/octave).
    let prev = 0;
    for (let i = 0; i < total; i++) {
      prev = prev * 0.998 + out[i] * 0.02;
      out[i] = prev * 8;
    }
  }
  return out;
}

// ── Effect chain ───────────────────────────────────────────────────

export function applyAmpEnv(samples, p) {
  const n = samples.length;
  const out = new Float32Array(n);
  const invN = 1 / n;
  for (let i = 0; i < n; i++) {
    const env = adsrValue(i * invN, p.ampAttack, p.ampDecay, p.ampSustain, p.ampRelease);
    out[i] = samples[i] * env * p.volume;
  }
  return out;
}

export function applyDrive(samples, p) {
  if (!p.driveEnabled || p.driveAmount <= 0) return samples;
  const n = samples.length;
  const out = new Float32Array(n);
  // Amount [0, 1] → input gain [1, 10]; dividing by tanh(gain) keeps the
  // wet peak near unity regardless of drive.
  const driveLin = 1 + p.driveAmount * 9;
  const norm = Math.tanh(driveLin);
  const wet = p.driveMix;
  const dry = 1 - wet;
  for (let i = 0; i < n; i++) {
    const x = samples[i];
    out[i] = (Math.tanh(x * driveLin) / norm) * wet + x * dry;
  }
  return out;
}

// Chamberlin state-variable filter; LP/HP/BP from one structure. Cutoff is
// modulated per-sample by an AD envelope.
export function applyFilter(samples, p) {
  if (!p.filterEnabled) return samples;
  const n = samples.length;
  const out = new Float32Array(n);
  let lp = 0;
  let bp = 0;
  // Resonance [0, 1] → damping [2.0, 0.1] (Q ≈ 0.5 … 10).
  const q1 = 2 - p.filterRes * 1.9;
  const fcMax = SAMPLE_RATE * 0.25;
  // The Chamberlin SVF is only stable while f < √(q1² + 4) − q1. At low
  // resonance that bound sits near 6 kHz — well under the SR/4 cap — so
  // bright, unresonant filter settings blew up to NaN (synth.gd has the
  // same issue). Capping f at 85% of the bound leaves the stable range
  // untouched and keeps ringing near the edge in check.
  const fMax = 0.85 * (Math.sqrt(q1 * q1 + 4) - q1);
  const typeId = Math.trunc(p.filterType);
  const invN = 1 / n;
  for (let i = 0; i < n; i++) {
    const env = envelopeValue(i * invN, p.filterAttack, p.filterDecay);
    // filterEnv ∈ [-1, 1] → ±4 octaves of cutoff sweep at the peak.
    const cutoff = clamp(p.filterCutoff * Math.pow(2, p.filterEnv * env * 4), 20, fcMax);
    const f = Math.min(2 * Math.sin(Math.PI * cutoff / SAMPLE_RATE), fMax);
    const hp = samples[i] - q1 * bp - lp;
    bp += f * hp;
    lp += f * bp;
    out[i] = typeId === 0 ? lp : typeId === 1 ? hp : bp;
  }
  return out;
}

export function applyTremolo(samples, p) {
  if (!p.tremEnabled) return samples;
  const n = samples.length;
  const out = new Float32Array(n);
  let phase = 0;
  const shape = Math.trunc(p.tremShape);
  const invSr = 1 / SAMPLE_RATE;
  const invN = 1 / n;
  for (let i = 0; i < n; i++) {
    phase = (phase + p.tremRate * invSr) % 1;
    const env = envelopeValue(i * invN, p.tremAttack, p.tremDecay);
    const lfo = (waveformAt(shape, phase) + 1) * 0.5;
    out[i] = samples[i] * (1 - p.tremDepth * env * lfo);
  }
  return out;
}

export function applyDelay(samples, p) {
  if (!p.delayEnabled || p.delayMix <= 0) return samples;
  const feedback = p.delayFeedback;
  const mix = p.delayMix;
  const delaySamples = Math.max(1, Math.trunc(p.delayTime / 1000 * SAMPLE_RATE));

  // Number of repeats until the tail falls below ~−60 dB.
  const minLevel = 0.001;
  let tailRepeats = 0;
  if (feedback > 0) {
    let level = 1;
    while (level > minLevel && tailRepeats < 50) {
      level *= feedback;
      tailRepeats++;
    }
  } else {
    tailRepeats = 1;
  }

  const totalLen = samples.length + delaySamples * (tailRepeats + 1);
  const out = new Float32Array(totalLen);
  const dryGain = 1 - mix * 0.5;
  for (let i = 0; i < samples.length; i++) out[i] = samples[i] * dryGain;

  // Each echo is lowpassed once more than the last (cumulative one-pole,
  // ~5 kHz per pass) so repeats darken as they die, like tape.
  const damp = 0.5;
  const filtered = Float32Array.from(samples);
  let lvl = mix;
  let offset = delaySamples;
  for (let r = 0; r < tailRepeats + 1; r++) {
    if (lvl < minLevel) break;
    if (r > 0) {
      let prev = 0;
      for (let i = 0; i < filtered.length; i++) {
        prev = damp * prev + (1 - damp) * filtered[i];
        filtered[i] = prev;
      }
    }
    for (let i = 0; i < samples.length; i++) {
      const dst = i + offset;
      if (dst >= totalLen) break;
      out[dst] += filtered[i] * lvl;
    }
    lvl *= feedback;
    offset += delaySamples;
  }
  return out;
}

export function applyCrush(samples, p) {
  if (!p.crushEnabled) return samples;
  const n = samples.length;
  const out = new Float32Array(n);
  const bits = Math.trunc(p.crushBits);
  const levels = Math.pow(2, bits - 1);
  const crushRate = Math.max(1, Math.trunc(p.crushRate));
  const ditherAmp = bits < 16 ? 1 / levels : 0;
  let last = 0;
  for (let i = 0; i < n; i++) {
    let v = samples[i];
    if (bits < 16) {
      v += (Math.random() - Math.random()) * ditherAmp;
      v = roundHalfAway(v * levels) / levels;
    }
    if (crushRate > 1) {
      if (i % crushRate === 0) last = v;
      else v = last;
    }
    out[i] = v;
  }
  return out;
}

export function applyChord(samples, p) {
  if (!p.chordEnabled || !(p.chordMix > 0)) return samples;
  const mix = p.chordMix;
  const n = samples.length;
  const out = new Float32Array(n);
  const dryGain = 1 - mix * 0.5;
  for (let i = 0; i < n; i++) out[i] = samples[i] * dryGain;
  const wetGain = mix / 3;
  for (const note of [p.chordNote1, p.chordNote2, p.chordNote3].map(Math.trunc)) {
    if (note === 0) continue;
    const ratio = Math.pow(2, note / 12);
    for (let i = 0; i < n; i++) {
      const src = i * ratio;
      const idx = Math.floor(src);
      if (idx >= n - 1) break;
      const frac = src - idx;
      out[i] += (samples[idx] * (1 - frac) + samples[idx + 1] * frac) * wetGain;
    }
  }
  return out;
}

export function applyFlanger(samples, p) {
  if (!p.flangerEnabled || !(p.flangerMix > 0)) return samples;
  const n = samples.length;
  const { flangerDepth: depth, flangerRate: rate, flangerFeedback: feedback, flangerMix: mix } = p;
  const baseDelayS = 0.003;
  const modRangeS = depth * 0.007;
  const maxDelay = Math.ceil((baseDelayS + modRangeS) * SAMPLE_RATE) + 2;
  const buf = new Float32Array(maxDelay);
  let writeIdx = 0;
  const out = new Float32Array(n);
  const dryGain = 1 - mix * 0.5;
  for (let i = 0; i < n; i++) {
    const lfo = (Math.sin(i / SAMPLE_RATE * rate * TAU) + 1) * 0.5;
    const delaySamples = (baseDelayS + lfo * modRangeS) * SAMPLE_RATE;
    let readPos = writeIdx - delaySamples;
    if (readPos < 0) readPos += maxDelay;
    const idx0 = Math.trunc(readPos) % maxDelay;
    const idx1 = (idx0 + 1) % maxDelay;
    const frac = readPos - Math.floor(readPos);
    const delayed = buf[idx0] * (1 - frac) + buf[idx1] * frac;
    buf[writeIdx] = samples[i] + delayed * feedback;
    writeIdx = (writeIdx + 1) % maxDelay;
    out[i] = samples[i] * dryGain + delayed * mix;
  }
  return out;
}

// ── Master bus ─────────────────────────────────────────────────────

// Schroeder reverb: 4 parallel combs into 2 series allpasses, using the
// classic mutually-prime delay lengths.
const REVERB_COMB_DELAYS = [1116, 1188, 1277, 1356];
const REVERB_AP_DELAYS = [225, 556];

export function applyReverb(samples, master) {
  const wet = master.reverbMix;
  if (!(wet > 0)) return samples;
  const size = master.reverbSize;
  const combFeedback = 0.7 + size * 0.28;  // small room … long hall
  const apFeedback = 0.5;
  const tail = Math.trunc(SAMPLE_RATE * (0.5 + size * 2.5));
  const totalLen = samples.length + tail;
  const out = new Float32Array(totalLen);

  const combBufs = REVERB_COMB_DELAYS.map((d) => new Float32Array(d));
  const combIdx = [0, 0, 0, 0];
  const apBufs = REVERB_AP_DELAYS.map((d) => new Float32Array(d));
  const apIdx = [0, 0];
  // Duck the dry only 40% as wet rises to keep loudness roughly constant.
  const dry = 1 - wet * 0.4;
  const nIn = samples.length;

  for (let i = 0; i < totalLen; i++) {
    const input = i < nIn ? samples[i] : 0;
    let comb = 0;
    for (let c = 0; c < 4; c++) {
      const b = combBufs[c];
      const idx = combIdx[c];
      const delayed = b[idx];
      b[idx] = input + delayed * combFeedback;
      combIdx[c] = (idx + 1) % REVERB_COMB_DELAYS[c];
      comb += delayed;
    }
    let ap = comb * 0.25;
    for (let a = 0; a < 2; a++) {
      const b = apBufs[a];
      const idx = apIdx[a];
      const delayed = b[idx];
      const nv = ap + delayed * apFeedback;
      b[idx] = nv;
      apIdx[a] = (idx + 1) % REVERB_AP_DELAYS[a];
      ap = delayed - nv * apFeedback;
    }
    out[i] = input * dry + ap * wet;
  }
  return out;
}

export function applyMasterVolume(samples, master) {
  const v = master.masterVolume;
  if (Math.abs(v - 1) < 1e-6) return samples;
  const out = new Float32Array(samples.length);
  for (let i = 0; i < samples.length; i++) out[i] = samples[i] * v;
  return out;
}

// Always-on safety limiter: linear below |x| = 0.9, soft tanh above.
export function applyLimiter(samples) {
  const out = new Float32Array(samples.length);
  for (let i = 0; i < samples.length; i++) {
    const x = samples[i];
    const ax = Math.abs(x);
    out[i] = ax < 0.9 ? x : Math.sign(x) * (0.9 + 0.1 * Math.tanh((ax - 0.9) * 10));
  }
  return out;
}

// ── Compose ────────────────────────────────────────────────────────

export function renderChannel(p) {
  let buf = generateDrySamples(p);
  buf = applyDrive(buf, p);
  buf = applyFilter(buf, p);
  buf = applyAmpEnv(buf, p);
  buf = applyTremolo(buf, p);
  buf = applyDelay(buf, p);
  buf = applyCrush(buf, p);
  buf = applyChord(buf, p);
  buf = applyFlanger(buf, p);
  return buf;
}

// Mute/solo: if any channel is soloed, only soloed (unmuted) channels are
// heard; otherwise every unmuted channel plays.
export function renderSound(sound) {
  const channels = sound.channels || [];
  if (!channels.length) return new Float32Array(0);
  const anySoloed = channels.some((c) => c.soloed);
  const active = channels.filter((c) => !c.muted && (!anySoloed || c.soloed));
  if (!active.length) return new Float32Array(0);

  const rendered = active.map(renderChannel);
  const totalLen = Math.max(...rendered.map((r) => r.length));
  const summed = new Float32Array(totalLen);
  rendered.forEach((r, ci) => {
    const lvl = active[ci].level ?? 1;
    for (let i = 0; i < r.length; i++) summed[i] += r[i] * lvl;
  });

  const master = sound.master || cloneMaster();
  let buf = applyReverb(summed, master);
  buf = applyMasterVolume(buf, master);
  return applyLimiter(buf);
}
