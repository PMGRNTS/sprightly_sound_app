// Rendering (via worker) and playback (via Web Audio).

import { renderSound } from './synth.js';
import { SAMPLE_RATE, normalize, encodeWav } from './sound-data.js';

// ── Renderer ───────────────────────────────────────────────────────
// Coalescing: while a render is in flight, newer requests replace the
// queued one, and every caller waiting on a superseded request resolves
// with the newer result. A knob drag therefore never builds a backlog.
export class Renderer {
  constructor() {
    this.nextId = 1;
    this.inflight = null;   // { id, resolvers }
    this.queued = null;     // { sound, resolvers }
    this.batches = new Map();
    try {
      this.worker = new Worker(new URL('./render-worker.js', import.meta.url), { type: 'module' });
      this.worker.onmessage = (e) => this._onMessage(e.data);
      this.worker.onerror = () => this._fallback();
    } catch {
      this.worker = null;
    }
  }

  // Module workers are unavailable on very old browsers; render inline.
  _fallback() {
    if (!this.worker) return;
    this.worker.terminate();
    this.worker = null;
    const pending = [this.inflight, this.queued].filter(Boolean);
    this.inflight = this.queued = null;
    for (const p of pending) {
      const samples = renderSound(p.sound);
      p.resolvers.forEach((r) => r(samples));
    }
  }

  render(sound) {
    const snapshot = JSON.parse(JSON.stringify(sound));
    if (!this.worker) return Promise.resolve(renderSound(snapshot));
    return new Promise((resolve) => {
      if (this.inflight) {
        const resolvers = this.queued ? this.queued.resolvers : [];
        resolvers.push(resolve);
        this.queued = { sound: snapshot, resolvers };
      } else {
        this._start(snapshot, [resolve]);
      }
    });
  }

  _start(sound, resolvers) {
    const id = this.nextId++;
    this.inflight = { id, sound, resolvers };
    this.worker.postMessage({ type: 'render', id, sound });
  }

  _onMessage(msg) {
    const batch = this.batches.get(msg.id);
    if (batch) {
      if (msg.files) {
        this.batches.delete(msg.id);
        batch.resolve(msg.files);
      } else {
        batch.onProgress?.(msg.progress);
      }
      return;
    }
    if (!this.inflight || msg.id !== this.inflight.id) return;
    const { resolvers } = this.inflight;
    this.inflight = null;
    if (this.queued) {
      const q = this.queued;
      this.queued = null;
      // Superseded callers get the newer result instead.
      this._start(q.sound, [...resolvers, ...q.resolvers]);
      return;
    }
    resolvers.forEach((r) => r(msg.samples));
  }

  batch(sounds, sampleRate, bits, doNormalize, onProgress) {
    if (!this.worker) {
      return Promise.resolve(sounds.map((s, i) => {
        let buf = renderSound(s);
        if (doNormalize) buf = normalize(buf);
        onProgress?.(i + 1);
        return encodeWav(buf, sampleRate, bits);
      }));
    }
    const id = this.nextId++;
    return new Promise((resolve) => {
      this.batches.set(id, { resolve, onProgress });
      this.worker.postMessage({ type: 'batch', id, sounds, sampleRate, bits, doNormalize });
    });
  }
}

// ── Player ─────────────────────────────────────────────────────────
// iOS only lets an AudioContext start inside a user gesture, so unlock()
// is called from a capturing pointerdown/keydown listener; later plays
// (after an async render) then work without a fresh gesture.
export class Player {
  constructor() {
    this.ctx = null;
    this.source = null;
    this.startedAt = 0;
    this.duration = 0;
  }

  unlock() {
    // Play through the ringer switch like a music app, not like a game
    // UI chime (Safari 17+; ignored elsewhere).
    try {
      if (navigator.audioSession) navigator.audioSession.type = 'playback';
    } catch { /* not supported */ }
    if (!this.ctx) {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) return;
      this.ctx = new Ctx({ latencyHint: 'interactive' });
      // A one-sample silent buffer completes the iOS unlock.
      const b = this.ctx.createBuffer(1, 1, 22050);
      const s = this.ctx.createBufferSource();
      s.buffer = b;
      s.connect(this.ctx.destination);
      s.start(0);
    }
    if (this.ctx.state !== 'running') this.ctx.resume().catch(() => {});
  }

  play(samples) {
    if (!samples || !samples.length) return;
    this.unlock();
    if (!this.ctx) return;
    this.stop();
    const buf = this.ctx.createBuffer(1, samples.length, SAMPLE_RATE);
    buf.copyToChannel(samples, 0);
    const src = this.ctx.createBufferSource();
    src.buffer = buf;
    src.connect(this.ctx.destination);
    src.onended = () => {
      if (this.source === src) this.source = null;
    };
    src.start();
    this.source = src;
    this.startedAt = this.ctx.currentTime;
    this.duration = buf.duration;
  }

  stop() {
    if (this.source) {
      try { this.source.stop(); } catch { /* already stopped */ }
      this.source = null;
    }
  }

  // Playback position in [0, 1], or -1 when idle.
  progress() {
    if (!this.source || !this.ctx || !this.duration) return -1;
    const p = (this.ctx.currentTime - this.startedAt) / this.duration;
    return p >= 0 && p <= 1 ? p : -1;
  }
}
