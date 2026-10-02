// Rotary knob. Port of scripts/knob.gd adapted for touch.
//
//   • Drag to adjust. Touch: swipe sideways (vertical swipes scroll the
//     page, so a screen full of knobs still scrolls). Mouse: any direction.
//   • Tap toggles the lock; double-tap resets to default (the lock ends up
//     where it started). Right-click also resets.
//   • Wheel and arrow keys step; PageUp/PageDown step ×10; Home/End.

const SVG_NS = 'http://www.w3.org/2000/svg';
const ARC_START = 135;
const ARC_SWEEP = 270;
// Fraction of the range per CSS pixel: ~200 px of travel end to end.
const DRAG_SENSITIVITY = 0.005;
const TAP_SLOP = 4;
const DOUBLE_TAP_MS = 320;

function polar(cx, cy, r, deg) {
  const a = (deg * Math.PI) / 180;
  return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
}

function arcPath(cx, cy, r, a0, a1) {
  const [x0, y0] = polar(cx, cy, r, a0);
  const [x1, y1] = polar(cx, cy, r, a1);
  const large = a1 - a0 > 180 ? 1 : 0;
  return `M ${x0} ${y0} A ${r} ${r} 0 ${large} 1 ${x1} ${y1}`;
}

export class Knob {
  // opts: { min, max, step, value, label, onChange(v), onCommit(v),
  //         onReset(), onLockToggle(), formatAria(v) }
  constructor(opts) {
    Object.assign(this, { min: 0, max: 1, step: 0.01, value: 0, locked: false }, opts);
    const el = document.createElement('div');
    el.className = 'knob';
    el.tabIndex = 0;
    el.setAttribute('role', 'slider');
    if (opts.label) el.setAttribute('aria-label', opts.label);
    el.setAttribute('aria-valuemin', this.min);
    el.setAttribute('aria-valuemax', this.max);

    const svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('viewBox', '0 0 40 40');
    svg.setAttribute('aria-hidden', 'true');
    const mk = (cls) => {
      const p = document.createElementNS(SVG_NS, 'path');
      p.setAttribute('class', cls);
      svg.appendChild(p);
      return p;
    };
    this.track = mk('knob-track');
    this.track.setAttribute('d', arcPath(20, 20, 15, ARC_START, ARC_START + ARC_SWEEP));
    this.arc = mk('knob-arc');
    this.pointer = mk('knob-pointer');
    el.appendChild(svg);
    this.el = el;

    this._bind();
    this._draw();
  }

  setValue(v) {
    this.value = v;
    this._draw();
  }

  setLocked(locked) {
    if (locked === this.locked) return;
    this.locked = locked;
    this.el.classList.toggle('locked', locked);
    // Brief pulse so a lock change is visible even mid-scroll.
    this.el.classList.remove('pulse');
    void this.el.offsetWidth;
    this.el.classList.add('pulse');
  }

  _draw() {
    const span = this.max - this.min;
    const t = span > 0 ? Math.min(1, Math.max(0, (this.value - this.min) / span)) : 0;
    const end = ARC_START + ARC_SWEEP * t;
    this.arc.setAttribute('d', t > 0.001 ? arcPath(20, 20, 15, ARC_START, end) : '');
    const [ix, iy] = polar(20, 20, 7, end);
    const [ox, oy] = polar(20, 20, 15, end);
    this.pointer.setAttribute('d', `M ${ix} ${iy} L ${ox} ${oy}`);
    this.el.setAttribute('aria-valuenow', this.value);
    if (this.formatAria) this.el.setAttribute('aria-valuetext', this.formatAria(this.value));
  }

  _snap(v) {
    let s = v;
    if (this.step > 0) s = Math.round((v - this.min) / this.step) * this.step + this.min;
    // Trim float dust (0.30000000000000004) so values serialize cleanly.
    s = parseFloat(s.toFixed(6));
    return Math.min(this.max, Math.max(this.min, s));
  }

  _set(v) {
    const nv = this._snap(v);
    if (nv !== this.value) {
      this.value = nv;
      this._draw();
      this.onChange?.(nv);
    }
  }

  _stepBy(n) {
    const st = this.step > 0 ? this.step : (this.max - this.min) * 0.01;
    this._set(this.value + st * n);
    this.onCommit?.(this.value);
  }

  _bind() {
    const el = this.el;
    let drag = null;
    let lastTap = 0;

    el.addEventListener('pointerdown', (e) => {
      if (e.button !== 0) return;
      e.preventDefault();
      el.focus({ preventScroll: true });
      el.setPointerCapture(e.pointerId);
      drag = { x: e.clientX, y: e.clientY, v: this.value, moved: false, touch: e.pointerType !== 'mouse' };
      el.classList.add('active');
    });

    el.addEventListener('pointermove', (e) => {
      if (!drag) return;
      const dx = e.clientX - drag.x;
      const dy = e.clientY - drag.y;
      if (!drag.moved && Math.hypot(dx, dy) < TAP_SLOP) return;
      drag.moved = true;
      // Right and up both increase.
      const travel = dx - dy;
      this._set(drag.v + travel * DRAG_SENSITIVITY * (this.max - this.min));
    });

    const end = (e, cancelled) => {
      if (!drag) return;
      const d = drag;
      drag = null;
      el.classList.remove('active');
      if (el.hasPointerCapture?.(e.pointerId)) el.releasePointerCapture(e.pointerId);
      if (d.moved) {
        this.onCommit?.(this.value);
        return;
      }
      if (cancelled) return;
      const now = performance.now();
      if (now - lastTap < DOUBLE_TAP_MS) {
        lastTap = 0;
        // The first tap flipped the lock; flip it back, then reset.
        this.onLockToggle?.();
        this.onReset?.();
      } else {
        lastTap = now;
        this.onLockToggle?.();
      }
    };
    el.addEventListener('pointerup', (e) => end(e, false));
    el.addEventListener('pointercancel', (e) => end(e, true));

    el.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      this.onReset?.();
    });

    let wheelAccum = 0;
    let wheelT = 0;
    el.addEventListener('wheel', (e) => {
      e.preventDefault();
      const now = performance.now();
      if (now - wheelT > 200) wheelAccum = 0;
      wheelT = now;
      wheelAccum += -Math.sign(e.deltaY) * Math.min(1, Math.abs(e.deltaY) / 50 + 0.3);
      while (wheelAccum >= 1) { wheelAccum -= 1; this._stepBy(1); }
      while (wheelAccum <= -1) { wheelAccum += 1; this._stepBy(-1); }
    }, { passive: false });

    el.addEventListener('keydown', (e) => {
      const map = { ArrowUp: 1, ArrowRight: 1, ArrowDown: -1, ArrowLeft: -1, PageUp: 10, PageDown: -10 };
      if (e.key in map) {
        this._stepBy(map[e.key]);
      } else if (e.key === 'Home') {
        this._set(this.min);
        this.onCommit?.(this.value);
      } else if (e.key === 'End') {
        this._set(this.max);
        this.onCommit?.(this.value);
      } else if (e.key === 'Enter') {
        this.onLockToggle?.();
      } else {
        return;
      }
      e.preventDefault();
      e.stopPropagation();
    });
  }
}
