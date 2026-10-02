// Constants, parameter metadata, default state, serialization, and WAV
// encoding. Port of scripts/sound_data.gd. No synthesis (see synth.js),
// no UI (see app.js).

export const SAMPLE_RATE = 44100;
export const MAX_CHANNELS = 4;
export const MODES = ['SQR', 'SAW', 'TRI', 'SIN', 'NSE', 'PNK', 'BRN'];

export const FMT = {
  DEC2: 0, DEC3: 1, INT: 2, HZ: 3, HZ1: 4, MS: 5, SEC: 6,
  MODE: 7, FILTER: 8, BITS: 9, CRUSH: 10, STEP: 11,
};

const d = (label, min, max, step, fmt) => ({ label, min, max, step, fmt });

export const PARAM_DEFS = {
  volume:          d('VOLUME', 0, 1, 0.01, FMT.DEC2),
  mode:            d('MODE', 0, 6, 1, FMT.MODE),
  pitch:           d('PITCH', 50, 4000, 1, FMT.HZ),
  voice:           d('VOICES', 1, 4, 1, FMT.INT),
  detune:          d('DETUNE', 0, 0.2, 0.005, FMT.DEC3),

  length:          d('LENGTH', 0.05, 4, 0.01, FMT.SEC),
  ampAttack:       d('ATTACK', 0, 1, 0.01, FMT.DEC2),
  ampDecay:        d('DECAY', 0, 1, 0.01, FMT.DEC2),
  ampSustain:      d('SUSTAIN', 0, 1, 0.01, FMT.DEC2),
  ampRelease:      d('RELEASE', 0, 1, 0.01, FMT.DEC2),

  pitchEnv:        d('AMOUNT', -1, 1, 0.01, FMT.DEC2),
  pitchAttack:     d('ATTACK', 0, 1, 0.01, FMT.DEC2),
  pitchDecay:      d('DECAY', 0, 1, 0.01, FMT.DEC2),

  pitchMod:        d('DEPTH', 0, 1, 0.01, FMT.DEC2),
  modShape:        d('SHAPE', 0, 4, 1, FMT.MODE),
  modRate:         d('RATE', 0, 30, 0.1, FMT.HZ1),
  modAttack:       d('ATTACK', 0, 1, 0.01, FMT.DEC2),
  modDecay:        d('DECAY', 0, 1, 0.01, FMT.DEC2),

  tremDepth:       d('DEPTH', 0, 1, 0.01, FMT.DEC2),
  tremShape:       d('SHAPE', 0, 4, 1, FMT.MODE),
  tremRate:        d('RATE', 0.1, 30, 0.1, FMT.HZ1),
  tremAttack:      d('ATTACK', 0, 1, 0.01, FMT.DEC2),
  tremDecay:       d('DECAY', 0, 1, 0.01, FMT.DEC2),

  arpRate:         d('RATE', 1, 50, 0.5, FMT.HZ1),
  arpStep1:        d('STEP 2', -24, 24, 1, FMT.STEP),
  arpStep2:        d('STEP 3', -24, 24, 1, FMT.STEP),
  arpStep3:        d('STEP 4', -24, 24, 1, FMT.STEP),

  delayTime:       d('TIME', 10, 500, 1, FMT.MS),
  delayFeedback:   d('FEEDBACK', 0, 0.9, 0.01, FMT.DEC2),
  delayMix:        d('MIX', 0, 1, 0.01, FMT.DEC2),

  crushBits:       d('BIT DEPTH', 1, 16, 1, FMT.BITS),
  crushRate:       d('SAMPLE RATE', 1, 64, 1, FMT.CRUSH),

  driveAmount:     d('AMOUNT', 0, 1, 0.01, FMT.DEC2),
  driveMix:        d('MIX', 0, 1, 0.01, FMT.DEC2),

  filterType:      d('TYPE', 0, 2, 1, FMT.FILTER),
  filterCutoff:    d('CUTOFF', 50, 15000, 1, FMT.HZ),
  filterRes:       d('RESONANCE', 0, 1, 0.01, FMT.DEC2),
  filterEnv:       d('ENV', -1, 1, 0.01, FMT.DEC2),
  filterAttack:    d('ATTACK', 0, 1, 0.01, FMT.DEC2),
  filterDecay:     d('DECAY', 0, 1, 0.01, FMT.DEC2),

  flangerDepth:    d('DEPTH', 0, 1, 0.01, FMT.DEC2),
  flangerRate:     d('RATE', 0.1, 10, 0.1, FMT.HZ1),
  flangerFeedback: d('FEEDBACK', -0.9, 0.9, 0.01, FMT.DEC2),
  flangerMix:      d('MIX', 0, 1, 0.01, FMT.DEC2),

  chordNote1:      d('NOTE 2', -24, 24, 1, FMT.STEP),
  chordNote2:      d('NOTE 3', -24, 24, 1, FMT.STEP),
  chordNote3:      d('NOTE 4', -24, 24, 1, FMT.STEP),
  chordMix:        d('MIX', 0, 1, 0.01, FMT.DEC2),
};

// Module rendering order. enable_key '' ⇒ always-on module.
export const MODULES = [
  { key: 'source',   title: 'SOURCE',         enable_key: '',                params: ['volume', 'mode', 'pitch', 'voice', 'detune'] },
  { key: 'amp',      title: 'AMP ENVELOPE',   enable_key: '',                params: ['length', 'ampAttack', 'ampDecay', 'ampSustain', 'ampRelease'] },
  { key: 'drive',    title: 'DRIVE',          enable_key: 'driveEnabled',    params: ['driveAmount', 'driveMix'] },
  { key: 'filter',   title: 'FILTER',         enable_key: 'filterEnabled',   params: ['filterType', 'filterCutoff', 'filterRes', 'filterEnv', 'filterAttack', 'filterDecay'] },
  { key: 'pitchEnv', title: 'PITCH ENVELOPE', enable_key: 'pitchEnvEnabled', params: ['pitchEnv', 'pitchAttack', 'pitchDecay'] },
  { key: 'vibrato',  title: 'VIBRATO',        enable_key: 'vibEnabled',      params: ['pitchMod', 'modShape', 'modRate', 'modAttack', 'modDecay'] },
  { key: 'tremolo',  title: 'TREMOLO',        enable_key: 'tremEnabled',     params: ['tremDepth', 'tremShape', 'tremRate', 'tremAttack', 'tremDecay'] },
  { key: 'arpeggio', title: 'ARPEGGIO',       enable_key: 'arpEnabled',      params: ['arpRate', 'arpStep1', 'arpStep2', 'arpStep3'] },
  { key: 'delay',    title: 'DELAY',          enable_key: 'delayEnabled',    params: ['delayTime', 'delayFeedback', 'delayMix'] },
  { key: 'crush',    title: 'CRUSH',          enable_key: 'crushEnabled',    params: ['crushBits', 'crushRate'] },
  { key: 'flanger',  title: 'FLANGER',        enable_key: 'flangerEnabled',  params: ['flangerDepth', 'flangerRate', 'flangerFeedback', 'flangerMix'] },
  { key: 'chord',    title: 'CHORD',          enable_key: 'chordEnabled',    params: ['chordNote1', 'chordNote2', 'chordNote3', 'chordMix'] },
];

export const DEFAULT_PARAMS = {
  volume: 0.5, mode: 0, pitch: 440.0, voice: 1, detune: 0.0,
  length: 0.4, ampAttack: 0.0, ampDecay: 1.0, ampSustain: 0.0, ampRelease: 0.0,
  pitchEnvEnabled: false,
  pitchEnv: 0.3, pitchAttack: 0.0, pitchDecay: 0.5,
  vibEnabled: false,
  pitchMod: 0.1, modShape: 3, modRate: 6.0, modAttack: 0.0, modDecay: 1.0,
  tremEnabled: false,
  tremDepth: 0.5, tremShape: 3, tremRate: 8.0, tremAttack: 0.0, tremDecay: 1.0,
  arpEnabled: false,
  arpRate: 12.0, arpStep1: 4, arpStep2: 7, arpStep3: 12,
  delayEnabled: false,
  delayTime: 150.0, delayFeedback: 0.4, delayMix: 0.4,
  crushEnabled: false,
  crushBits: 8, crushRate: 4,
  driveEnabled: false,
  driveAmount: 0.4, driveMix: 1.0,
  filterEnabled: false,
  filterType: 0, filterCutoff: 5000.0, filterRes: 0.0,
  filterEnv: 0.0, filterAttack: 0.0, filterDecay: 0.5,
  flangerEnabled: false,
  flangerDepth: 0.5, flangerRate: 0.5, flangerFeedback: 0.3, flangerMix: 0.5,
  chordEnabled: false,
  chordNote1: 4, chordNote2: 7, chordNote3: 12, chordMix: 0.5,
  level: 1.0, muted: false, soloed: false,
};

// Keys whose GDScript default is an int literal. JS has one number type,
// so the codec needs this list to truncate on decode like Godot does.
const INT_KEYS = new Set([
  'mode', 'voice', 'modShape', 'tremShape', 'arpStep1', 'arpStep2', 'arpStep3',
  'crushBits', 'crushRate', 'filterType', 'chordNote1', 'chordNote2', 'chordNote3',
]);

export const DEFAULT_MASTER = { masterVolume: 1.0, reverbMix: 0.0, reverbSize: 0.5 };

// v7 field order — must match the Godot/JS schema so sound strings move
// freely between the desktop app and this web build.
export const V7_CHANNEL_KEYS = [
  'volume', 'mode', 'pitch', 'voice', 'detune',
  'length', 'ampAttack', 'ampDecay', 'ampSustain', 'ampRelease',
  'pitchEnvEnabled', 'pitchEnv', 'pitchAttack', 'pitchDecay',
  'vibEnabled', 'pitchMod', 'modShape', 'modRate', 'modAttack', 'modDecay',
  'tremEnabled', 'tremDepth', 'tremShape', 'tremRate', 'tremAttack', 'tremDecay',
  'arpEnabled', 'arpRate', 'arpStep1', 'arpStep2', 'arpStep3',
  'delayEnabled', 'delayTime', 'delayFeedback', 'delayMix',
  'crushEnabled', 'crushBits', 'crushRate',
  'driveEnabled', 'driveAmount', 'driveMix',
  'filterEnabled', 'filterType', 'filterCutoff', 'filterRes',
  'filterEnv', 'filterAttack', 'filterDecay',
  'flangerEnabled', 'flangerDepth', 'flangerRate', 'flangerFeedback', 'flangerMix',
  'chordEnabled', 'chordNote1', 'chordNote2', 'chordNote3', 'chordMix',
  'level', 'muted', 'soloed',
];
export const V7_MASTER_KEYS = ['masterVolume', 'reverbMix', 'reverbSize'];

export const deepClone = (o) => JSON.parse(JSON.stringify(o));
export const cloneParams = () => ({ ...DEFAULT_PARAMS });
export const cloneMaster = () => ({ ...DEFAULT_MASTER });
export const defaultSound = () => ({ channels: [cloneParams()], master: cloneMaster() });

// GDScript round(): half away from zero (Math.round rounds -2.5 to -2).
export const roundHalfAway = (v) => Math.sign(v) * Math.round(Math.abs(v));
export const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

// ── Value formatting ─────────────────────────────────────────────

export function formatValue(key, value) {
  const def = PARAM_DEFS[key];
  const fmt = def ? def.fmt : FMT.DEC2;
  const r = roundHalfAway(value);
  switch (fmt) {
    case FMT.DEC2: return value.toFixed(2);
    case FMT.DEC3: return value.toFixed(3);
    case FMT.INT: return String(r);
    case FMT.HZ: return value >= 1000 ? `${(value / 1000).toFixed(1)}kHz` : `${r}Hz`;
    case FMT.HZ1: return `${value.toFixed(1)}Hz`;
    case FMT.MS: return `${r}ms`;
    case FMT.SEC: return `${value.toFixed(2)}s`;
    case FMT.MODE: return MODES[clamp(r, 0, MODES.length - 1)];
    case FMT.FILTER: return ['LP', 'HP', 'BP'][clamp(r, 0, 2)];
    case FMT.BITS: return `${r}BIT`;
    case FMT.CRUSH: return r <= 1 ? '44.1kHz' : `${(44100 / r / 1000).toFixed(1)}kHz`;
    case FMT.STEP: return r >= 0 ? `+${r}st` : `${r}st`;
  }
  return value.toFixed(2);
}

// ── Sound string serialization ─────────────────────────────────────

function fmtField(key, value) {
  if (typeof value === 'boolean') return value ? '1' : '0';
  const def = PARAM_DEFS[key];
  if (def && def.step >= 1) return String(roundHalfAway(Number(value)));
  return Number(value).toFixed(3);
}

export function soundToString(sound) {
  const parts = ['sfx7', String(sound.channels.length)];
  for (const k of V7_MASTER_KEYS) parts.push(fmtField(k, sound.master[k]));
  for (const ch of sound.channels) {
    for (const k of V7_CHANNEL_KEYS) parts.push(fmtField(k, ch[k]));
  }
  return parts.join(':');
}

const FLOAT_RE = /^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/;

function decodeKeys(parts, offset, keys, typeRef) {
  const out = {};
  for (let i = 0; i < keys.length; i++) {
    const k = keys[i];
    const idx = offset + i;
    if (idx >= parts.length) return null;
    const raw = parts[idx].trim();
    if (typeof typeRef[k] === 'boolean') {
      out[k] = raw === '1';
      continue;
    }
    if (!FLOAT_RE.test(raw)) return null;
    const v = parseFloat(raw);
    out[k] = INT_KEYS.has(k) ? Math.trunc(v) : v;
  }
  return out;
}

export function soundFromString(s) {
  const parts = String(s || '').trim().split(':');
  if (parts[0] !== 'sfx7' || parts.length < 2) return null;
  const numCh = parseInt(parts[1], 10);
  if (!(numCh >= 1 && numCh <= MAX_CHANNELS)) return null;
  const header = 2 + V7_MASTER_KEYS.length;
  if (parts.length < header) return null;
  // Tolerates strings from older builds with fewer channel fields — new
  // params fall back to their defaults.
  const fieldsPerCh = Math.floor((parts.length - header) / numCh);

  const master = decodeKeys(parts, 2, V7_MASTER_KEYS, DEFAULT_MASTER);
  if (!master) return null;

  const channels = [];
  let off = header;
  const keysToRead = V7_CHANNEL_KEYS.slice(0, Math.min(fieldsPerCh, V7_CHANNEL_KEYS.length));
  for (let i = 0; i < numCh; i++) {
    const ch = decodeKeys(parts, off, keysToRead, DEFAULT_PARAMS);
    if (!ch) return null;
    channels.push({ ...cloneParams(), ...ch });
    off += fieldsPerCh;
  }
  return { channels, master: { ...cloneMaster(), ...master } };
}

// ── WAV encoding ───────────────────────────────────────────────────

export function resample(samples, targetRate) {
  if (targetRate === SAMPLE_RATE) return samples;
  const ratio = SAMPLE_RATE / targetRate;
  const newLen = Math.floor(samples.length / ratio);
  const out = new Float32Array(newLen);
  const last = samples.length - 1;
  for (let i = 0; i < newLen; i++) {
    const src = i * ratio;
    const idx = Math.floor(src);
    const frac = src - idx;
    const s0 = samples[Math.min(idx, last)];
    const s1 = samples[Math.min(idx + 1, last)];
    out[i] = s0 + (s1 - s0) * frac;
  }
  return out;
}

export function encodeWav(samples, sampleRate = SAMPLE_RATE, bits = 16) {
  const src = resample(samples, sampleRate);
  const bps = bits === 8 ? 1 : 2;
  const dataSize = src.length * bps;
  const buf = new ArrayBuffer(44 + dataSize);
  const v = new DataView(buf);
  const ascii = (off, str) => { for (let i = 0; i < 4; i++) v.setUint8(off + i, str.charCodeAt(i)); };
  ascii(0, 'RIFF');
  v.setUint32(4, 36 + dataSize, true);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  v.setUint32(16, 16, true);
  v.setUint16(20, 1, true);
  v.setUint16(22, 1, true);
  v.setUint32(24, sampleRate, true);
  v.setUint32(28, sampleRate * bps, true);
  v.setUint16(32, bps, true);
  v.setUint16(34, bits, true);
  ascii(36, 'data');
  v.setUint32(40, dataSize, true);
  if (bits === 8) {
    for (let i = 0; i < src.length; i++) {
      v.setUint8(44 + i, Math.trunc((clamp(src[i], -1, 1) + 1) * 0.5 * 255));
    }
  } else {
    for (let i = 0; i < src.length; i++) {
      v.setInt16(44 + i * 2, Math.trunc(clamp(src[i], -1, 1) * 32767), true);
    }
  }
  return new Uint8Array(buf);
}

export function normalize(samples) {
  let peak = 0;
  for (let i = 0; i < samples.length; i++) peak = Math.max(peak, Math.abs(samples[i]));
  if (peak <= 0 || peak >= 1) return samples;
  const g = 1 / peak;
  const out = new Float32Array(samples.length);
  for (let i = 0; i < samples.length; i++) out[i] = samples[i] * g;
  return out;
}
