// The nine themes from scripts/palette.gd, applied as CSS custom
// properties. Order is the picker order (Charcoal first = default).

export const THEMES = {
  Charcoal: { BG: '#1a1814', PANEL: '#23201a', INSET: '#14120d', BORDER: '#3a342a', BORDER_HI: '#5c5345', TEXT: '#d8ccb4', TEXT_MUTE: '#847d70', TEXT_DIM: '#4d473d', ACCENT: '#c9882d', INDICATOR_OFF: '#2a241a', SEPARATOR: '#1f1c16' },
  Onyx:     { BG: '#14171a', PANEL: '#1c2024', INSET: '#0d1014', BORDER: '#2c3239', BORDER_HI: '#4a525c', TEXT: '#c8cdd3', TEXT_MUTE: '#76808a', TEXT_DIM: '#424952', ACCENT: '#6b9bb5', INDICATOR_OFF: '#1a1f24', SEPARATOR: '#181c20' },
  Slate:    { BG: '#181818', PANEL: '#222222', INSET: '#101010', BORDER: '#303030', BORDER_HI: '#4f4f4f', TEXT: '#d0d0d0', TEXT_MUTE: '#808080', TEXT_DIM: '#4a4a4a', ACCENT: '#b09a7a', INDICATOR_OFF: '#252525', SEPARATOR: '#1c1c1c' },
  Moss:     { BG: '#161a14', PANEL: '#1d221a', INSET: '#0e110c', BORDER: '#2e3329', BORDER_HI: '#4d5544', TEXT: '#c8d0bc', TEXT_MUTE: '#7a8472', TEXT_DIM: '#444a3d', ACCENT: '#8aa674', INDICATOR_OFF: '#1f241b', SEPARATOR: '#191d16' },
  Plum:     { BG: '#1a1418', PANEL: '#221b20', INSET: '#120d10', BORDER: '#38303a', BORDER_HI: '#5a4d5c', TEXT: '#d4c4cc', TEXT_MUTE: '#847680', TEXT_DIM: '#4a3f48', ACCENT: '#b58aaa', INDICATOR_OFF: '#251c25', SEPARATOR: '#1c161a' },
  Sepia:    { BG: '#e8dec9', PANEL: '#f0e7d3', INSET: '#d6cbb3', BORDER: '#b8a988', BORDER_HI: '#8e7e5a', TEXT: '#2a2418', TEXT_MUTE: '#685c44', TEXT_DIM: '#9a8d72', ACCENT: '#a85a2a', INDICATOR_OFF: '#cabf9f', SEPARATOR: '#d4c8a8' },
  Paper:    { BG: '#efeee8', PANEL: '#f6f5f0', INSET: '#ddddd6', BORDER: '#c4c3bc', BORDER_HI: '#8a8a82', TEXT: '#1a1a18', TEXT_MUTE: '#66665e', TEXT_DIM: '#aaaaa3', ACCENT: '#2c5a55', INDICATOR_OFF: '#d0d0c8', SEPARATOR: '#e0dfd9' },
  // Pure black, near-white text, bright yellow accent — doesn't rely on hue.
  'High Contrast': { BG: '#000000', PANEL: '#111111', INSET: '#000000', BORDER: '#555555', BORDER_HI: '#ffffff', TEXT: '#ffffff', TEXT_MUTE: '#b0b0b0', TEXT_DIM: '#707070', ACCENT: '#ffd700', INDICATOR_OFF: '#1a1a1a', SEPARATOR: '#333333' },
  // Desktop Glass shows the OS wallpaper through a transparent window; the
  // web version paints its own wallpaper and frosts the panels over it.
  Glass:    { BG: 'transparent', PANEL: 'rgba(26,28,33,0.62)', INSET: 'rgba(13,15,20,0.66)', BORDER: 'rgba(255,255,255,0.16)', BORDER_HI: 'rgba(255,255,255,0.42)', TEXT: '#f5f5fa', TEXT_MUTE: 'rgba(184,189,199,0.98)', TEXT_DIM: 'rgba(122,128,140,0.92)', ACCENT: '#a8c7eb', INDICATOR_OFF: 'rgba(51,56,64,0.7)', SEPARATOR: 'rgba(255,255,255,0.07)' },
};

export const DEFAULT_THEME = 'Charcoal';

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function rgbToHsv([r, g, b]) {
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const d = max - min;
  let h = 0;
  if (d) {
    if (max === r) h = ((g - b) / d) % 6;
    else if (max === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    h /= 6;
    if (h < 0) h += 1;
  }
  return [h, max ? d / max : 0, max];
}

function hsvToRgb(h, s, v) {
  const i = Math.floor(h * 6);
  const f = h * 6 - i;
  const p = v * (1 - s);
  const q = v * (1 - f * s);
  const t = v * (1 - (1 - f) * s);
  const [r, g, b] = [[v, t, p], [q, v, p], [p, v, t], [p, q, v], [t, p, v], [v, p, q]][i % 6];
  return [r, g, b].map((x) => Math.round(x * 255));
}

// Waveform colour: the accent's complement (180° hue) with saturation
// knocked back, so the signal reads as "the signal", not "more accent".
function waveformLine(accent) {
  const [h, s, v] = rgbToHsv(hexToRgb(accent));
  return hsvToRgb((h + 0.5) % 1, s * 0.85, v);
}

export function applyTheme(name) {
  const t = THEMES[name] || THEMES[DEFAULT_THEME];
  const root = document.documentElement;
  for (const [k, v] of Object.entries(t)) {
    root.style.setProperty(`--${k.toLowerCase().replace(/_/g, '-')}`, v);
  }
  const [r, g, b] = hexToRgb(t.ACCENT);
  const [wr, wg, wb] = waveformLine(t.ACCENT);
  root.style.setProperty('--accent-rgb', `${r}, ${g}, ${b}`);
  root.style.setProperty('--wave', `rgb(${wr}, ${wg}, ${wb})`);
  root.style.setProperty('--wave-glow', `rgba(${wr}, ${wg}, ${wb}, 0.25)`);
  root.dataset.theme = name;
  const light = name === 'Sepia' || name === 'Paper';
  root.style.colorScheme = light ? 'light' : 'dark';
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.content = name === 'Glass' ? '#101624' : t.BG;
}
