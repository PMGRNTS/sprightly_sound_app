// localStorage-backed persistence — the web stand-in for
// scripts/app/persistence.gd. Failures are non-fatal: a read failure
// returns the fallback, a write failure returns false so the caller can
// flash "SAVE FAILED" instead of a success it didn't get.

const PREFIX = 'hone.';

function read(key, fallback) {
  try {
    const raw = localStorage.getItem(PREFIX + key);
    if (raw == null) return fallback;
    const v = JSON.parse(raw);
    // A value of the wrong shape (hand-edited, older build) costs the user
    // that one setting, not a crash on boot.
    if (Array.isArray(fallback) !== Array.isArray(v) || typeof v !== typeof fallback) return fallback;
    return v;
  } catch {
    return fallback;
  }
}

function write(key, value) {
  try {
    localStorage.setItem(PREFIX + key, JSON.stringify(value));
    return true;
  } catch {
    return false;
  }
}

export const Storage = {
  loadBin: () => read('bin', []),
  saveBin: (bin) => write('bin', bin),

  loadTheme: () => read('theme', ''),
  saveTheme: (name) => write('theme', name),

  loadUserPresets: () => read('userPresets', []),
  saveUserPresets: (all) => write('userPresets', all),
  addUserPreset(name, soundString) {
    const all = this.loadUserPresets();
    all.push({ name, string: soundString });
    return this.saveUserPresets(all);
  },

  loadExport: () => read('export', { sampleRate: 44100, bits: 16, normalize: false }),
  saveExport: (opts) => write('export', opts),

  loadUi: () => read('ui', {}),
  saveUi: (ui) => write('ui', ui),
};
