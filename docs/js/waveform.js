// Waveform canvas with glow underlay, gridlines, peak/clip readout and a
// playhead. Port of scripts/waveform_display.gd. The peak polyline is
// cached and only rebuilt when samples or size change.

export class Waveform {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.samples = new Float32Array(0);
    this.points = null;
    this.peak = 0;
    this.playhead = -1;
    this._size = [0, 0, 0];
    new ResizeObserver(() => this.draw()).observe(canvas);
  }

  setSamples(s) {
    this.samples = s;
    this.points = null;
    this.draw();
  }

  setPlayhead(p) {
    if (p === this.playhead) return;
    this.playhead = p;
    this.draw();
  }

  _resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    const w = this.canvas.clientWidth;
    const h = this.canvas.clientHeight;
    if (w !== this._size[0] || h !== this._size[1] || dpr !== this._size[2]) {
      this.canvas.width = Math.round(w * dpr);
      this.canvas.height = Math.round(h * dpr);
      this._size = [w, h, dpr];
      this.points = null;
    }
    return this._size;
  }

  _rebuild(w, h) {
    const half = h * 0.5 - 12;
    const num = Math.max(2, Math.floor(w * 2));
    const n = this.samples.length;
    const step = Math.max(1, Math.floor(n / num));
    const pts = new Float32Array(num * 2);
    let maxPeak = 0;
    for (let i = 0; i < num; i++) {
      let start = i * step;
      let end = Math.min((i + 1) * step, n);
      if (start >= n) { start = n - 1; end = n; }
      let peak = this.samples[start];
      for (let j = start + 1; j < end; j++) {
        if (Math.abs(this.samples[j]) > Math.abs(peak)) peak = this.samples[j];
      }
      maxPeak = Math.max(maxPeak, Math.abs(peak));
      const c = Math.max(-1, Math.min(1, peak));
      pts[i * 2] = (i / num) * w;
      pts[i * 2 + 1] = Math.max(2, Math.min(h - 2, h * 0.5 - c * half));
    }
    this.points = pts;
    this.peak = maxPeak;
  }

  draw() {
    const [w, h, dpr] = this._resize();
    if (!w || !h) return;
    const ctx = this.ctx;
    const css = getComputedStyle(this.canvas);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);

    ctx.strokeStyle = css.getPropertyValue('--separator').trim() || '#222';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, Math.round(h / 2) + 0.5);
    ctx.lineTo(w, Math.round(h / 2) + 0.5);
    for (let i = 1; i < 8; i++) {
      const x = Math.round((w * i) / 8) + 0.5;
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
    }
    ctx.stroke();

    if (!this.samples.length) return;
    if (!this.points) this._rebuild(w, h);

    const pts = this.points;
    const path = new Path2D();
    path.moveTo(pts[0], pts[1]);
    for (let i = 2; i < pts.length; i += 2) path.lineTo(pts[i], pts[i + 1]);
    ctx.lineJoin = 'round';
    ctx.strokeStyle = css.getPropertyValue('--wave-glow').trim();
    ctx.lineWidth = 4;
    ctx.stroke(path);
    ctx.strokeStyle = css.getPropertyValue('--wave').trim();
    ctx.lineWidth = 1.4;
    ctx.stroke(path);

    if (this.playhead >= 0) {
      const x = Math.round(this.playhead * w) + 0.5;
      ctx.strokeStyle = css.getPropertyValue('--accent').trim();
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
      ctx.stroke();
    }

    if (this.peak > 0.9) {
      const clip = this.peak >= 1;
      ctx.font = '600 10px ui-monospace, SFMono-Regular, Menlo, monospace';
      ctx.textAlign = 'right';
      ctx.fillStyle = clip ? '#ff4d4d' : css.getPropertyValue('--text-mute').trim();
      ctx.fillText(clip ? 'CLIP' : `PEAK ${this.peak.toFixed(2)}`, w - 8, h - 6);
    }
  }
}
