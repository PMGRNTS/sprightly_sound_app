// Shared preset toolkit + GEN / MUTATE. Port of
// scripts/presets/presets_helpers.gd. The per-group presets in
// presets-generated.js are converted from GDScript and import these.

import { randf } from './rng.js';
import { PARAM_DEFS, MODULES, cloneParams, deepClone, clamp, roundHalfAway } from './sound-data.js';

// ── RNG / picking ──────────────────────────────────────────────────

export const _rand = (a, b) => randf() * (b - a) + a;
export const _rand_int = (a, b) => Math.floor(randf() * (b - a + 1)) + a;
export const _pick = (arr) => arr[_rand_int(0, arr.length - 1)];

// ── Patch application ──────────────────────────────────────────────

// Apply a target dict on top of `params`, skipping any locked key.
export function _apply_target(params, locked, target) {
  const out = deepClone(params);
  for (const k of Object.keys(target)) {
    if (!locked[k]) out[k] = target[k];
  }
  return out;
}

// Implicitly lock a module's enable flag if any of its params are locked —
// otherwise GEN could switch off a module the user clearly wants kept.
export function effectiveLocks(locked) {
  const out = { ...locked };
  for (const mod of MODULES) {
    const ek = mod.enable_key;
    if (!ek || out[ek]) continue;
    if (mod.params.some((p) => out[p])) out[ek] = true;
  }
  return out;
}

// Base of every preset so leftover modules from the previous patch
// don't surprise the user.
export const ALL_OFF = {
  pitchEnvEnabled: false,
  vibEnabled: false,
  tremEnabled: false,
  arpEnabled: false,
  delayEnabled: false,
  crushEnabled: false,
  driveEnabled: false,
  filterEnabled: false,
  flangerEnabled: false,
  chordEnabled: false,
};

export const _off_with = (extra) => ({ ...ALL_OFF, ...extra });

// ── Sound-building toolkit ─────────────────────────────────────────

// Readable names for the `mode` and `filterType` ints.
export const SQR = 0, SAW = 1, TRI = 2, SIN = 3, NSE = 4, PNK = 5, BRN = 6;
export const LP = 0, HP = 1, BP = 2;

// Defaults, then ALL_OFF, then `base`, then each module dict in order.
// The default amp envelope is instant attack + full-length decay.
export const _layer = (base, mods = []) => Object.assign(cloneParams(), ALL_OFF, base, ...mods);

// Wrap channels into a full Sound with a master reverb setting.
export const _sound = (channels, reverbMix, reverbSize, masterVolume = 1.0) => ({
  channels, master: { masterVolume, reverbMix, reverbSize },
});

// ── Module dicts (pass in `_layer`'s mods array) ───────────────────

// Amp ADSR; times are fractions of the channel length.
export const _env = (attack, decay, sustain, release) => ({
  ampAttack: attack, ampDecay: decay, ampSustain: sustain, ampRelease: release,
});

// Filter with an AD cutoff envelope (env ±1 ≈ ±4 octaves at its peak).
export const _filt = (ftype, cutoff, res, env = 0.0, attack = 0.0, decay = 0.5) => ({
  filterEnabled: true, filterType: ftype, filterCutoff: cutoff, filterRes: res,
  filterEnv: env, filterAttack: attack, filterDecay: decay,
});

export const _drive = (amount, mix = 1.0) => ({ driveEnabled: true, driveAmount: amount, driveMix: mix });

// Pitch envelope (amount ±1 ≈ ±2 octaves at its peak). Drops to zero once
// attack + decay has elapsed — a rise that holds uses attack 1, decay 0.
export const _bend = (amount, attack, decay) => ({
  pitchEnvEnabled: true, pitchEnv: amount, pitchAttack: attack, pitchDecay: decay,
});

// Vibrato: depth is a ± frequency ratio. SAW = repeating upward sweeps,
// NSE = rough, gravelly voice.
export const _vib = (depth, rate, shape = SIN, attack = 0.0, decay = 1.0) => ({
  vibEnabled: true, pitchMod: depth, modShape: shape, modRate: rate, modAttack: attack, modDecay: decay,
});

export const _trem = (depth, rate, shape = SIN, attack = 0.0, decay = 1.0) => ({
  tremEnabled: true, tremDepth: depth, tremShape: shape, tremRate: rate, tremAttack: attack, tremDecay: decay,
});

// Pulse train: a SAW tremolo restarts the amplitude every cycle, so one
// channel becomes `rate` separate hits per second. The gating fades as
// the tremolo envelope decays — keep the hits early in the channel.
export const _pulses = (rate, depth = 1.0) => _trem(depth, rate, SAW);

// Late onset: silent until `at` s, then a hard hit ringing `ring` s. A
// square tremolo gates the first half-cycle shut and opens `at` → 2·`at`;
// the amp attack peaks as it opens. `length` is the channel's length
// (≥ ~4× `at` — the gate leaks as the tremolo envelope fades).
export const _at = (at, length, ring) => ({ ..._trem(1.0, 0.5 / at, SQR), ..._env(at / length, ring / length, 0.0, 0.0) });

// Note sequence: base, +s1, +s2, +s3 semitones, cycling at `rate` Hz.
export const _arp = (rate, s1, s2, s3) => ({ arpEnabled: true, arpRate: rate, arpStep1: s1, arpStep2: s2, arpStep3: s3 });

// Delay. mix 1.0 + no feedback = full-level echo over a half-level dry
// hit: places a second event `ms` later (heel-toe, knock-knock).
export const _echo = (ms, mix, feedback = 0.0) => ({ delayEnabled: true, delayTime: ms, delayFeedback: feedback, delayMix: mix });

export const _crush = (bits, rate) => ({ crushEnabled: true, crushBits: bits, crushRate: rate });

export const _flange = (depth, rate, feedback, mix) => ({
  flangerEnabled: true, flangerDepth: depth, flangerRate: rate, flangerFeedback: feedback, flangerMix: mix,
});

// Chord: pitch-shifted (and time-compressed) copies — upper partials die
// sooner, as they do on bells and struck metal.
export const _chord = (n1, n2, n3, mix) => ({ chordEnabled: true, chordNote1: n1, chordNote2: n2, chordNote3: n3, chordMix: mix });

// ── MUTATE ─────────────────────────────────────────────────────────

// Nudge every unlocked param by up to ±10% of its range, in place.
const MUTATE_AMOUNT = 0.1;

// Godot's snappedf: floor(v / step + 0.5) * step.
const snapped = (v, step) => Math.floor(v / step + 0.5) * step;

export function mutateChannel(ch, locked) {
  for (const [key, def] of Object.entries(PARAM_DEFS)) {
    if (locked[key]) continue;
    const span = def.max - def.min;
    const nudge = (randf() * 2 - 1) * span * MUTATE_AMOUNT;
    const old = Number(ch[key] ?? def.min);
    const nv = clamp(old + nudge, def.min, def.max);
    ch[key] = def.step >= 1 ? roundHalfAway(nv) : snapped(nv, def.step);
  }
}

// ── GEN ────────────────────────────────────────────────────────────

export function randomizeAll(params, locked) {
  // Bias the ADSR toward percussive shapes — most SFX are hits.
  const sustained = randf() < 0.2;
  const ampShape = sustained
    ? { ampAttack: _rand(0.0, 0.2), ampDecay: _rand(0.0, 0.3), ampSustain: _rand(0.4, 0.9), ampRelease: _rand(0.2, 0.6) }
    : { ampAttack: _rand(0.0, 0.05), ampDecay: _rand(0.5, 1.0), ampSustain: _rand(0.0, 0.2), ampRelease: _rand(0.0, 0.3) };

  const target = {
    volume: _rand(0.3, 0.8),
    mode: _rand_int(0, 6),
    pitch: _rand(80.0, 2000.0),
    length: _rand(0.1, 1.0),
    voice: _rand_int(1, 4),
    detune: _rand(0.0, 0.1),
    pitchEnvEnabled: randf() < 0.6,
    pitchEnv: _rand(-0.5, 0.5),
    pitchAttack: _rand(0.0, 0.4),
    pitchDecay: _rand(0.2, 1.0),
    vibEnabled: randf() < 0.4,
    pitchMod: _rand(0.05, 0.5),
    modShape: _rand_int(0, 4),
    modRate: _rand(2.0, 25.0),
    modAttack: _rand(0.0, 0.3),
    modDecay: _rand(0.2, 1.0),
    tremEnabled: randf() < 0.25,
    tremDepth: _rand(0.3, 0.8),
    tremShape: _rand_int(0, 4),
    tremRate: _rand(4.0, 20.0),
    tremAttack: _rand(0.0, 0.2),
    tremDecay: _rand(0.5, 1.0),
    arpEnabled: randf() < 0.2,
    arpRate: _rand(8.0, 30.0),
    arpStep1: _pick([3, 4, 5, 7, -5, -7, 12]),
    arpStep2: _pick([7, 12, -12, 5]),
    arpStep3: _pick([12, 0, -12, 7]),
    delayEnabled: randf() < 0.3,
    delayTime: _rand(50.0, 300.0),
    delayFeedback: _rand(0.2, 0.6),
    delayMix: _rand(0.3, 0.6),
    crushEnabled: randf() < 0.3,
    crushBits: _rand_int(2, 8),
    crushRate: _rand_int(1, 16),
    driveEnabled: randf() < 0.25,
    driveAmount: _rand(0.2, 0.7),
    driveMix: _rand(0.7, 1.0),
    filterEnabled: randf() < 0.4,
    filterType: _rand_int(0, 2),
    filterCutoff: _rand(300.0, 8000.0),
    filterRes: _rand(0.0, 0.7),
    filterEnv: _rand(-0.7, 0.7),
    filterAttack: _rand(0.0, 0.4),
    filterDecay: _rand(0.3, 1.0),
    flangerEnabled: randf() < 0.2,
    flangerDepth: _rand(0.2, 0.8),
    flangerRate: _rand(0.2, 5.0),
    flangerFeedback: _rand(-0.5, 0.5),
    flangerMix: _rand(0.3, 0.7),
    chordEnabled: randf() < 0.15,
    chordNote1: _pick([3, 4, 5, 7, 12]),
    chordNote2: _pick([7, 12, -12, 0]),
    chordNote3: _pick([12, 0, -5, -12]),
    chordMix: _rand(0.3, 0.7),
    ...ampShape,
  };
  return _apply_target(params, locked, target);
}
