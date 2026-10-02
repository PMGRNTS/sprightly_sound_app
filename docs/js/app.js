// Top-level controller — the web counterpart of scripts/main.gd and
// scripts/app/ui_builder.gd. Builds the DOM, wires events to state
// mutations, and refreshes the views that depend on what changed.

import {
  MAX_CHANNELS, MODES, PARAM_DEFS, MODULES, DEFAULT_PARAMS, DEFAULT_MASTER, FMT, SAMPLE_RATE,
  formatValue, soundToString, soundFromString, encodeWav, normalize, deepClone,
} from './sound-data.js';
import {
  REGISTRY, PRESET_DISPLAY_GROUPS, runPreset, effectiveLocks, randomizeAll, mutateChannel,
} from './presets.js';
import { SoundState } from './state.js';
import { Storage } from './storage.js';
import { Renderer, Player } from './audio.js';
import { Knob } from './knob.js';
import { Waveform } from './waveform.js';
import { THEMES, DEFAULT_THEME, applyTheme } from './themes.js';
import { makeZip } from './zip.js';

const APP_VERSION = '1.0';
const RENDER_DEBOUNCE_MS = 30;
const STATUS_HOLD_MS = 1400;

// Display order of the module panels.
const MODULE_ORDER = [
  'source', 'amp', 'filter',
  'pitchEnv', 'vibrato', 'tremolo',
  'arpeggio', 'delay', 'drive',
  'crush', 'flanger', 'chord',
];

// A few PARAM_DEFS labels are too long for a knob box.
const KNOB_LABEL_OVERRIDES = {
  crushBits: 'BITS',
  crushRate: 'S.RATE',
  delayFeedback: 'FB',
  filterRes: 'RES',
  filterCutoff: 'CUTOFF',
};

// Enumerated params: tapping the value cycles options instead of typing.
const CYCLE_FMTS = new Set([FMT.MODE, FMT.FILTER]);

const ICON_LOCK = '<svg viewBox="0 0 16 16" aria-hidden="true"><rect x="3" y="7" width="10" height="7" rx="1.5"/><path d="M5 7V5a3 3 0 0 1 6 0v2" fill="none"/></svg>';
const ICON_UNLOCK = '<svg viewBox="0 0 16 16" aria-hidden="true"><rect x="3" y="7" width="10" height="7" rx="1.5"/><path d="M5 7V5a3 3 0 0 1 5.8-1" fill="none"/></svg>';

const IS_TOUCH = window.matchMedia('(pointer: coarse)').matches;

// ── Collaborators ──────────────────────────────────────────────────
const state = new SoundState();
const renderer = new Renderer();
const player = new Player();
let exportOpts = Storage.loadExport();
let uiPrefs = Storage.loadUi();
let waveform;

// Cached DOM references.
const ui = {
  knobs: {},          // param → Knob
  valueBtns: {},      // param → value button
  boxes: {},          // param → knob box element
  modulePanels: {},   // module key → element
  moduleToggles: {},  // enable_key → toggle button
  moduleLocks: {},    // enable_key → lock button
  channelTabs: [],
  mixRows: [],
  master: {},         // key → { knob, value }
  presetGroup: '',
};

// ── Small DOM helpers ──────────────────────────────────────────────

const $ = (sel, root = document) => root.querySelector(sel);

function h(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'html') el.innerHTML = v;
    else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const c of children.flat()) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}

const btn = (label, onclick, cls = 'btn', attrs = {}) =>
  h('button', { type: 'button', class: cls, onclick, ...attrs }, label);

function timestamp() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

function saveUiPrefs() {
  Storage.saveUi(uiPrefs);
}

// ── Status pill ────────────────────────────────────────────────────

let statusTimer = 0;
function flash(msg) {
  const el = $('#status');
  el.textContent = msg;
  el.classList.add('flash');
  clearTimeout(statusTimer);
  statusTimer = setTimeout(() => {
    el.textContent = 'READY';
    el.classList.remove('flash');
  }, STATUS_HOLD_MS);
}

// ── Render orchestration ───────────────────────────────────────────

let renderTimer = 0;
let renderSeq = 0;

// Render now. Any pending debounced render is cancelled — otherwise an
// edit followed by an action button would render twice.
async function reRender() {
  clearTimeout(renderTimer);
  renderTimer = 0;
  const seq = ++renderSeq;
  state.soundString = soundToString(state.sound);
  const ss = $('#sound-string');
  if (ss && document.activeElement !== ss) ss.value = state.soundString;
  const samples = await renderer.render(state.sound);
  // A newer render may have finished first; keep the newest.
  if (seq === renderSeq) {
    state.samples = samples;
    waveform.setSamples(samples);
    refreshWaveInfo();
  }
  return state.samples;
}

// Knob drags → one render after motion settles.
function requestReRender() {
  clearTimeout(renderTimer);
  renderTimer = setTimeout(reRender, RENDER_DEBOUNCE_MS);
}

async function applyAndPlay(label) {
  const samples = await reRender();
  if (label) flash(label);
  play(samples);
}

function play(samples = state.samples) {
  player.play(samples);
  animatePlayhead();
}

let playheadRaf = 0;
function animatePlayhead() {
  cancelAnimationFrame(playheadRaf);
  const tick = () => {
    const p = player.progress();
    waveform.setPlayhead(p);
    if (p >= 0) playheadRaf = requestAnimationFrame(tick);
  };
  playheadRaf = requestAnimationFrame(tick);
}

// Play the current sound, flushing any pending render first so PLAY never
// plays a stale buffer mid-drag.
async function playCurrent() {
  if (renderTimer) await reRender();
  play();
}

// ── Header + waveform ──────────────────────────────────────────────

function buildHeader() {
  $('#undo').addEventListener('click', undo);
  $('#redo').addEventListener('click', redo);
  $('#theme-btn').addEventListener('click', openThemeSheet);
  $('#help-btn').addEventListener('click', openHelpSheet);
  $('#version').textContent = `// PMGRNTS · v${APP_VERSION}`;

  waveform = new Waveform($('#wave canvas'));
  $('#wave').addEventListener('click', playCurrent);
}

function refreshWaveInfo() {
  const n = state.samples.length;
  const ms = Math.round((n / SAMPLE_RATE) * 1000);
  $('#wave-left').textContent = `${n} SMP · ${ms}ms · ${state.sound.channels.length}CH`;
  const ch = state.activeParams();
  const mode = MODES[Math.min(Math.max(0, Math.trunc(ch.mode)), MODES.length - 1)];
  $('#wave-right').textContent = `CH${state.activeChannel + 1} · ${mode} @ ${Math.round(ch.pitch)}Hz`;
}

function refreshUndoButtons() {
  $('#undo').disabled = !state.undoStack.length;
  $('#redo').disabled = !state.redoStack.length;
}

// ── Synth pane: channel tabs + modules ─────────────────────────────

function buildChannelTabs() {
  const wrap = $('#channel-tabs');
  for (let i = 0; i < MAX_CHANNELS; i++) {
    const b = btn(`CH ${i + 1}`, () => selectChannel(i), 'chan-tab');
    wrap.append(b);
    ui.channelTabs.push(b);
  }
  ui.addChannel = btn('+', addChannel, 'chan-tab chan-add', { 'aria-label': 'Add channel' });
  wrap.append(ui.addChannel);
}

function refreshChannelTabs() {
  const num = state.sound.channels.length;
  ui.channelTabs.forEach((b, i) => {
    const exists = i < num;
    const ch = state.sound.channels[i];
    b.disabled = !exists;
    b.classList.toggle('active', exists && i === state.activeChannel);
    b.classList.toggle('soloed', exists && !!ch.soloed);
    b.classList.toggle('muted', exists && !!ch.muted);
    b.textContent = exists ? `CH ${i + 1}` : '—';
  });
  ui.addChannel.disabled = num >= MAX_CHANNELS;
}

function buildModules() {
  const wrap = $('#modules');
  const byKey = Object.fromEntries(MODULES.map((m) => [m.key, m]));
  for (const key of MODULE_ORDER) wrap.append(buildModulePanel(byKey[key]));
}

function buildModulePanel(mod) {
  const ek = mod.enable_key;
  const head = h('header', { class: 'mod-head' });
  if (ek) {
    const toggle = h('button', {
      type: 'button', class: 'mod-toggle', 'aria-pressed': 'false',
      onclick: () => toggleModule(ek),
    }, h('span', { class: 'check', 'aria-hidden': 'true' }), h('span', { class: 'mod-title' }, mod.title));
    const lock = h('button', {
      type: 'button', class: 'mod-lock', 'aria-label': `Lock ${mod.title}`, html: ICON_UNLOCK,
      onclick: () => toggleModuleLock(mod),
    });
    ui.moduleToggles[ek] = toggle;
    ui.moduleLocks[ek] = lock;
    head.append(toggle, lock);
  } else {
    head.append(h('div', { class: 'mod-toggle static' },
      h('span', { class: 'dot', 'aria-hidden': 'true' }), h('span', { class: 'mod-title' }, mod.title)));
  }

  const grid = h('div', { class: 'kgrid' });
  for (const pk of mod.params) grid.append(buildParamBox(pk));

  const panel = h('section', { class: 'module', 'data-module': mod.key }, head, grid);
  ui.modulePanels[mod.key] = panel;
  return panel;
}

function buildParamBox(key) {
  const def = PARAM_DEFS[key];
  const label = KNOB_LABEL_OVERRIDES[key] || def.label;
  const knob = new Knob({
    min: def.min, max: def.max, step: def.step, value: DEFAULT_PARAMS[key], label: def.label,
    formatAria: (v) => formatValue(key, v),
    onChange: (v) => onParamChanged(key, v),
    onCommit: () => { if (uiPrefs.autoplay) playCurrent(); },
    onReset: () => onParamReset(key),
    onLockToggle: () => toggleParamLock(key),
  });
  const labelBtn = btn(label, () => toggleParamLock(key), 'klabel', { title: `${def.label} · tap to lock` });
  const valueBtn = btn('—', () => editParamValue(key), 'kvalue', { 'aria-label': `${def.label} value` });
  const box = h('div', { class: 'kbox' }, labelBtn, knob.el, valueBtn);
  ui.knobs[key] = knob;
  ui.valueBtns[key] = valueBtn;
  ui.boxes[key] = box;
  return box;
}

function refreshModules() {
  const ch = state.activeParams();
  const locks = state.activeLocks();
  for (const [key, knob] of Object.entries(ui.knobs)) {
    const v = Number(ch[key] ?? 0);
    knob.setValue(v);
    ui.valueBtns[key].textContent = formatValue(key, v);
    setParamLockedView(key, !!locks[key]);
  }
  for (const mod of MODULES) {
    const ek = mod.enable_key;
    if (!ek) continue;
    const on = !!ch[ek];
    ui.moduleToggles[ek].setAttribute('aria-pressed', String(on));
    setModuleLockView(ek, !!locks[ek]);
    ui.modulePanels[mod.key].classList.toggle('off', !on);
  }
}

function setParamLockedView(key, locked) {
  ui.knobs[key].setLocked(locked);
  ui.boxes[key].classList.toggle('locked', locked);
}

function setModuleLockView(ek, locked) {
  const b = ui.moduleLocks[ek];
  b.classList.toggle('on', locked);
  b.innerHTML = locked ? ICON_LOCK : ICON_UNLOCK;
  b.setAttribute('aria-pressed', String(locked));
}

// ── Param handlers ─────────────────────────────────────────────────

function onParamChanged(key, value) {
  const def = PARAM_DEFS[key];
  state.activeParams()[key] = def.step >= 1 ? Math.round(value) : value;
  ui.valueBtns[key].textContent = formatValue(key, value);
  requestReRender();
  refreshWaveInfo();
}

function onParamReset(key) {
  const v = DEFAULT_PARAMS[key];
  state.activeParams()[key] = v;
  ui.knobs[key].setValue(v);
  ui.valueBtns[key].textContent = formatValue(key, v);
  flash('RESET');
  reRender().then(() => { if (uiPrefs.autoplay) play(); });
}

function toggleParamLock(key) {
  const locks = state.activeLocks();
  locks[key] = !locks[key];
  setParamLockedView(key, locks[key]);
}

// Tap the value readout: enumerations cycle, numbers get typed in —
// far more precise than a thumb on a 4 kHz-wide pitch knob.
function editParamValue(key) {
  const def = PARAM_DEFS[key];
  const ch = state.activeParams();
  let v;
  if (CYCLE_FMTS.has(def.fmt)) {
    v = ch[key] + 1 > def.max ? def.min : ch[key] + 1;
  } else {
    const raw = window.prompt(`${def.label}  (${def.min} – ${def.max})`, String(ch[key]));
    if (raw == null) return;
    v = parseFloat(raw.replace(/[^\d.eE+-]/g, ''));
    if (!Number.isFinite(v)) {
      flash('INVALID');
      return;
    }
    v = Math.min(def.max, Math.max(def.min, v));
  }
  if (def.step >= 1) v = Math.round(v);
  ch[key] = v;
  ui.knobs[key].setValue(v);
  ui.valueBtns[key].textContent = formatValue(key, v);
  reRender().then(() => { if (uiPrefs.autoplay) play(); });
}

function toggleModule(ek) {
  const ch = state.activeParams();
  ch[ek] = !ch[ek];
  refreshModules();
  reRender().then(() => { if (uiPrefs.autoplay) play(); });
}

// Module lock: the enable flag plus every param in the module.
function toggleModuleLock(mod) {
  const locks = state.activeLocks();
  const will = !locks[mod.enable_key];
  locks[mod.enable_key] = will;
  for (const p of mod.params) {
    locks[p] = will;
    setParamLockedView(p, will);
  }
  setModuleLockView(mod.enable_key, will);
  flash(will ? 'LOCKED' : 'UNLOCKED');
}

// ── Channel handlers ───────────────────────────────────────────────

function selectChannel(idx) {
  if (idx >= state.sound.channels.length) return;
  state.activeChannel = idx;
  refreshChannelTabs();
  refreshMix();
  refreshModules();
  refreshWaveInfo();
}

function addChannel() {
  if (!state.addChannel()) return;
  flash(`+ CH ${state.activeChannel + 1}`);
  refreshChannelTabs();
  refreshMix();
  refreshModules();
  reRender();
}

function deleteChannel(idx) {
  if (!state.removeChannel(idx)) return;
  refreshChannelTabs();
  refreshMix();
  refreshModules();
  reRender();
}

// ── Mix pane ───────────────────────────────────────────────────────

function buildMaster() {
  const rows = $('#mix-rows');
  for (let i = 0; i < MAX_CHANNELS; i++) {
    const label = btn(`CH${i + 1}`, () => selectChannel(i), 'mix-label');
    const slider = h('input', {
      type: 'range', min: '0', max: '1', step: '0.01', value: '0', class: 'mix-slider',
      'aria-label': `Channel ${i + 1} level`,
    });
    slider.addEventListener('input', () => {
      if (i >= state.sound.channels.length) return;
      state.sound.channels[i].level = parseFloat(slider.value);
      value.textContent = parseFloat(slider.value).toFixed(2);
      requestReRender();
    });
    slider.addEventListener('change', () => { if (uiPrefs.autoplay) playCurrent(); });
    const value = h('span', { class: 'mix-value' }, '—');
    const mute = btn('M', () => toggleChannelFlag(i, 'muted'), 'mini', { 'aria-label': `Mute channel ${i + 1}` });
    const solo = btn('S', () => toggleChannelFlag(i, 'soloed'), 'mini', { 'aria-label': `Solo channel ${i + 1}` });
    const del = btn('×', () => deleteChannel(i), 'mini del', { 'aria-label': `Remove channel ${i + 1}` });
    const row = h('div', { class: 'mix-row' }, label, slider, value, mute, solo, del);
    rows.append(row);
    ui.mixRows.push({ row, label, slider, value, mute, solo, del });
  }

  const out = $('#master-knobs');
  for (const [key, label] of [['masterVolume', 'VOLUME'], ['reverbMix', 'VERB MIX'], ['reverbSize', 'VERB SIZE']]) {
    const knob = new Knob({
      min: 0, max: 1, step: 0.01, value: DEFAULT_MASTER[key], label,
      formatAria: (v) => v.toFixed(2),
      onChange: (v) => {
        state.sound.master[key] = v;
        ui.master[key].value.textContent = v.toFixed(2);
        requestReRender();
      },
      onCommit: () => { if (uiPrefs.autoplay) playCurrent(); },
      onReset: () => resetMaster(key),
    });
    const value = h('span', { class: 'kvalue static' }, '—');
    out.append(h('div', { class: 'kbox' },
      btn(label, () => resetMaster(key), 'klabel', { title: 'Tap to reset' }), knob.el, value));
    ui.master[key] = { knob, value };
  }
}

function toggleChannelFlag(i, flag) {
  if (i >= state.sound.channels.length) return;
  const ch = state.sound.channels[i];
  ch[flag] = !ch[flag];
  if (flag === 'soloed') state.activeChannel = i;
  refreshMix();
  refreshChannelTabs();
  refreshModules();
  reRender();
}

function resetMaster(key) {
  const v = DEFAULT_MASTER[key];
  state.sound.master[key] = v;
  refreshMaster();
  flash('RESET');
  reRender();
}

function refreshMix() {
  const num = state.sound.channels.length;
  ui.mixRows.forEach((r, i) => {
    const exists = i < num;
    const ch = state.sound.channels[i];
    r.row.classList.toggle('empty', !exists);
    r.label.classList.toggle('active', exists && i === state.activeChannel);
    r.label.disabled = !exists;
    r.slider.disabled = !exists;
    r.slider.value = exists ? ch.level : 0;
    r.value.textContent = exists ? Number(ch.level).toFixed(2) : '—';
    r.mute.disabled = r.solo.disabled = !exists;
    r.mute.classList.toggle('on', exists && !!ch.muted);
    r.solo.classList.toggle('on', exists && !!ch.soloed);
    r.mute.setAttribute('aria-pressed', String(exists && !!ch.muted));
    r.solo.setAttribute('aria-pressed', String(exists && !!ch.soloed));
    r.del.disabled = !exists || num <= 1;
    r.del.style.visibility = exists && num > 1 ? 'visible' : 'hidden';
  });
}

function refreshMaster() {
  for (const [key, { knob, value }] of Object.entries(ui.master)) {
    const v = Number(state.sound.master[key]);
    knob.setValue(v);
    value.textContent = v.toFixed(2);
  }
}

// ── Presets pane ───────────────────────────────────────────────────

function buildPresets() {
  const seedInput = $('#seed');
  seedInput.addEventListener('change', () => {
    const v = Math.min(9999, Math.max(0, Math.trunc(Number(seedInput.value) || 0)));
    state.variationSeed = v;
    seedInput.value = v;
  });
  $('#reroll').addEventListener('click', () => {
    state.randomizeVariationSeed();
    seedInput.value = state.variationSeed;
    flash(`VAR ${state.variationSeed}`);
  });
  $('#save-preset').addEventListener('click', savePreset);
  ui.presetGroup = uiPrefs.presetGroup || '';
  refreshPresets();
}

function userPresetEntries() {
  return Storage.loadUserPresets().map((p, i) => ({
    name: `★${p.name ?? 'untitled'}`, kind: 'user', group: 'USER', string: String(p.string ?? ''), userIndex: i,
  }));
}

function refreshPresets() {
  const groups = [];
  for (const e of REGISTRY) {
    const g = PRESET_DISPLAY_GROUPS[e.group] || e.group;
    if (!groups.includes(g)) groups.push(g);
  }
  const user = userPresetEntries();
  if (user.length) groups.push('USER');
  if (!groups.includes(ui.presetGroup)) ui.presetGroup = groups[0];

  const tabs = $('#preset-groups');
  tabs.replaceChildren(...groups.map((g) => {
    const b = btn(g, () => {
      ui.presetGroup = g;
      uiPrefs.presetGroup = g;
      saveUiPrefs();
      refreshPresets();
    }, 'chip', { role: 'tab', 'aria-selected': String(g === ui.presetGroup) });
    b.classList.toggle('active', g === ui.presetGroup);
    return b;
  }));

  const entries = ui.presetGroup === 'USER'
    ? user
    : REGISTRY.filter((e) => (PRESET_DISPLAY_GROUPS[e.group] || e.group) === ui.presetGroup);

  $('#preset-grid').replaceChildren(...entries.map((entry) => {
    const b = btn(entry.name, () => onPresetPressed(entry), 'preset');
    if (entry.kind !== 'user') return b;
    const del = h('button', {
      type: 'button', class: 'preset-del', 'aria-label': `Delete ${entry.name}`,
      onclick: (e) => {
        e.stopPropagation();
        deleteUserPreset(entry);
      },
    }, '×');
    return h('div', { class: 'preset-wrap' }, b, del);
  }));
}

function onPresetPressed(entry) {
  if (entry.kind === 'user') {
    const s = soundFromString(entry.string);
    if (!s) {
      flash('CORRUPT');
      return;
    }
    state.pushUndo();
    replaceSoundAndRefresh(s, entry.name);
    return;
  }
  state.consumeVariationSeed();
  $('#seed').value = state.variationSeed;
  if (entry.kind === 'sound') {
    const s = runPreset(entry, {}, {});
    state.pushUndo();
    replaceSoundAndRefresh(s, entry.name);
    return;
  }
  state.pushUndo();
  const patch = runPreset(entry, state.activeParams(), effectiveLocks(state.activeLocks()));
  // Patch presets collapse to a single-channel sound.
  state.applyPatchPreset(patch);
  refreshEverything();
  applyAndPlay(entry.name);
}

function savePreset() {
  const all = Storage.loadUserPresets();
  const raw = window.prompt('Save as preset — name:', `preset_${all.length + 1}`);
  if (raw == null) return;
  const name = raw.trim();
  if (!name) {
    flash('EMPTY NAME');
    return;
  }
  const ok = Storage.addUserPreset(name, soundToString(state.sound));
  ui.presetGroup = 'USER';
  refreshPresets();
  flash(ok ? 'SAVED ★' : 'SAVE FAILED');
}

function deleteUserPreset(entry) {
  if (!window.confirm(`Delete preset "${entry.name.slice(1)}"?`)) return;
  const all = Storage.loadUserPresets();
  all.splice(entry.userIndex, 1);
  Storage.saveUserPresets(all);
  refreshPresets();
  flash('DELETED');
}

// ── Actions ────────────────────────────────────────────────────────

function generate() {
  state.pushUndo();
  // Seed BEFORE randomizing — same seed, same sound.
  state.consumeVariationSeed();
  $('#seed').value = state.variationSeed;
  const locks = effectiveLocks(state.activeLocks());
  state.sound.channels[state.activeChannel] = randomizeAll(state.activeParams(), locks);
  refreshModules();
  refreshWaveInfo();
  refreshUndoButtons();
  applyAndPlay('GEN');
}

function mutate() {
  state.pushUndo();
  mutateChannel(state.activeParams(), state.activeLocks());
  refreshModules();
  refreshUndoButtons();
  applyAndPlay('MUTATE');
}

function undo() {
  if (!state.undo()) {
    flash('NO UNDO');
    return;
  }
  refreshEverything();
  applyAndPlay('UNDO');
}

function redo() {
  if (!state.redo()) {
    flash('NO REDO');
    return;
  }
  refreshEverything();
  applyAndPlay('REDO');
}

// Replace the whole sound, refresh every view, play. Used by paste, load,
// bin, user presets and sound presets.
function replaceSoundAndRefresh(sound, label) {
  state.replaceSound(sound);
  refreshEverything();
  applyAndPlay(label);
}

function refreshEverything() {
  refreshChannelTabs();
  refreshMix();
  refreshModules();
  refreshMaster();
  refreshWaveInfo();
  refreshUndoButtons();
}

// ── Files pane: export, bin, sound string ──────────────────────────

// Phones get the share sheet (Save to Files, AirDrop, Messages…);
// desktops get a plain download.
async function saveFile(file) {
  if (IS_TOUCH && navigator.canShare?.({ files: [file] })) {
    try {
      await navigator.share({ files: [file] });
      return 'shared';
    } catch (e) {
      if (e.name === 'AbortError') return 'cancelled';
      // NotAllowedError etc. → fall through to a download.
    }
  }
  const url = URL.createObjectURL(file);
  const a = h('a', { href: url, download: file.name });
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 30000);
  return 'downloaded';
}

function encodeForExport(samples) {
  return encodeWav(exportOpts.normalize ? normalize(samples) : samples, exportOpts.sampleRate, exportOpts.bits);
}

async function exportWav() {
  if (renderTimer) await reRender();
  if (!state.samples.length) {
    flash('EMPTY');
    return;
  }
  const file = new File([encodeForExport(state.samples)], `sfx_${timestamp()}.wav`, { type: 'audio/wav' });
  const result = await saveFile(file);
  if (result !== 'cancelled') flash('EXPORTED');
}

function buildExport() {
  $('#export-wav').addEventListener('click', exportWav);
  $('#export-rate').addEventListener('click', () => {
    exportOpts.sampleRate = exportOpts.sampleRate === 44100 ? 22050 : 44100;
    refreshExport();
  });
  $('#export-bits').addEventListener('click', () => {
    exportOpts.bits = exportOpts.bits === 16 ? 8 : 16;
    refreshExport();
  });
  $('#export-norm').addEventListener('click', () => {
    exportOpts.normalize = !exportOpts.normalize;
    refreshExport();
  });
  $('#batch').addEventListener('click', openBatchSheet);
}

function refreshExport() {
  Storage.saveExport(exportOpts);
  $('#export-rate').textContent = exportOpts.sampleRate === 22050 ? '22.05kHz' : '44.1kHz';
  $('#export-bits').textContent = `${exportOpts.bits}BIT`;
  const norm = $('#export-norm');
  norm.textContent = exportOpts.normalize ? 'NORM ON' : 'NORM OFF';
  norm.classList.toggle('on', exportOpts.normalize);
  norm.setAttribute('aria-pressed', String(exportOpts.normalize));
}

function buildBin() {
  $('#bin-save').addEventListener('click', saveToBin);
  $('#bin-search').addEventListener('input', refreshBin);
}

function saveToBin() {
  const id = Date.now();
  state.addToBin({
    id,
    name: `sfx_${state.sound.channels.length}ch_${String(id).slice(-5)}`,
    string: soundToString(state.sound),
  });
  const ok = Storage.saveBin(state.bin);
  refreshBin();
  flash(ok ? 'SAVED' : 'SAVE FAILED');
}

function refreshBin() {
  $('#bin-count').textContent = `[${state.bin.length}]`;
  const list = $('#bin-list');
  if (!state.bin.length) {
    list.replaceChildren(h('p', { class: 'empty-note' }, 'EMPTY · SAVE A SOUND'));
    return;
  }
  const q = $('#bin-search').value.trim().toLowerCase();
  const visible = q ? state.bin.filter((e) => String(e.name).toLowerCase().includes(q)) : state.bin;
  if (!visible.length) {
    list.replaceChildren(h('p', { class: 'empty-note' }, 'NO MATCH · CLEAR SEARCH'));
    return;
  }
  list.replaceChildren(...visible.map((e) => h('div', { class: 'bin-row' },
    h('button', { type: 'button', class: 'bin-load', onclick: () => loadBinEntry(e.id) },
      h('span', { class: 'bin-play', 'aria-hidden': 'true' }, '▶'),
      h('span', { class: 'bin-name' }, e.name)),
    btn('×', () => deleteBinEntry(e.id), 'mini del', { 'aria-label': `Delete ${e.name}` }),
  )));
}

function loadBinEntry(id) {
  const entry = state.findBinEntry(id);
  if (!entry) return;
  const s = soundFromString(entry.string);
  if (!s) {
    flash('CORRUPT');
    return;
  }
  state.pushUndo();
  replaceSoundAndRefresh(s, 'LOADED');
}

function deleteBinEntry(id) {
  state.removeFromBin(id);
  const ok = Storage.saveBin(state.bin);
  refreshBin();
  if (!ok) flash('DELETE FAILED');
}

function buildSoundString() {
  $('#copy').addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(state.soundString);
      flash('COPIED');
    } catch {
      $('#sound-string').select();
      flash('SELECT + COPY');
    }
  });
  $('#paste').addEventListener('click', async () => {
    let text = '';
    try {
      text = await navigator.clipboard.readText();
    } catch {
      flash('PASTE BLOCKED');
      return;
    }
    loadString(text, 'PASTED');
  });
  $('#load').addEventListener('click', () => loadString($('#sound-string').value, 'LOADED'));
  $('#share-link').addEventListener('click', async () => {
    const url = `${location.origin}${location.pathname}#s=${encodeURIComponent(state.soundString)}`;
    if (IS_TOUCH && navigator.share) {
      try {
        await navigator.share({ title: 'Hone sound', url });
        return;
      } catch (e) {
        if (e.name === 'AbortError') return;
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      flash('LINK COPIED');
    } catch {
      flash('COPY FAILED');
    }
  });
}

function loadString(text, label) {
  const s = soundFromString(text);
  if (!s) {
    flash('INVALID');
    return false;
  }
  state.pushUndo();
  replaceSoundAndRefresh(s, label);
  return true;
}

// ── Sheets (theme, help, batch) ────────────────────────────────────

function openSheet(title, ...content) {
  const dlg = $('#sheet');
  $('#sheet-title').textContent = title;
  $('#sheet-body').replaceChildren(...content);
  if (!dlg.open) dlg.showModal();
}

function closeSheet() {
  $('#sheet').close();
}

function openThemeSheet() {
  const current = document.documentElement.dataset.theme;
  openSheet('THEME', h('div', { class: 'theme-list' }, Object.entries(THEMES).map(([name, t]) => {
    const b = h('button', {
      type: 'button', class: 'theme-row', 'aria-pressed': String(name === current),
      onclick: () => {
        applyTheme(name);
        Storage.saveTheme(name);
        waveform.draw();
        closeSheet();
        flash(name.toUpperCase());
      },
    },
    h('span', { class: 'swatch', style: `background:${name === 'Glass' ? 'linear-gradient(135deg,#3a5f9e,#8b4f8f)' : t.BG};border-color:${t.BORDER_HI}` },
      h('span', { style: `background:${t.ACCENT}` })),
    h('span', {}, name),
    name === current ? h('span', { class: 'tick' }, '✓') : null);
    return b;
  })));
}

function openHelpSheet() {
  const rows = (pairs) => h('dl', { class: 'help-list' }, pairs.map(([k, v]) => [h('dt', {}, k), h('dd', {}, v)]));
  openSheet('HOW TO',
    h('h3', {}, 'Touch'),
    rows([
      ['Swipe sideways on a knob', 'Turn it'],
      ['Tap a knob or its label', 'Lock / unlock (held through GEN)'],
      ['Double-tap a knob', 'Reset to default'],
      ['Tap a value', 'Type an exact value (or cycle a mode)'],
      ['Tap the waveform', 'Play'],
      ['🔒 on a module', 'Lock the whole module'],
    ]),
    h('h3', {}, 'Keyboard'),
    rows([
      ['Space', 'Play'],
      ['R', 'Re-render + play'],
      ['G / M', 'Generate / mutate'],
      ['E', 'Export WAV'],
      ['1 – 4', 'Switch channel'],
      ['⌘/Ctrl Z · ⇧⌘/Ctrl Z', 'Undo · redo'],
      ['Drag · right-click knob', 'Turn · reset'],
    ]),
    h('h3', {}, 'Install on iPhone'),
    h('p', { class: 'help-note' }, 'In Safari tap Share → Add to Home Screen. Hone then opens full-screen and works offline. If you hear nothing, turn the volume up — sound plays even with the ringer switch on silent on iOS 17+.'),
    h('p', { class: 'help-note dim' }, `HONE v${APP_VERSION} · UP TO 4 CHANNELS · LOCK PARAMS TO HOLD THROUGH GEN`),
  );
}

let batchMutate = false;
let batchResult = null;

function openBatchSheet() {
  batchResult = null;
  const count = h('input', { type: 'number', min: '1', max: '100', value: '10', inputmode: 'numeric', class: 'field', id: 'batch-count' });
  const mode = btn(batchMutate ? 'MUTATE' : 'GENERATE', () => {
    batchMutate = !batchMutate;
    mode.textContent = batchMutate ? 'MUTATE' : 'GENERATE';
  }, 'btn wide');
  const progress = h('p', { class: 'help-note', id: 'batch-progress' },
    `Renders variations of channel ${state.activeChannel + 1} (locks respected) and packs them into a .zip of WAVs.`);
  const go = btn('⚄ RENDER', () => runBatch(Math.min(100, Math.max(1, Math.trunc(Number(count.value) || 1))), go, progress), 'btn primary wide');
  openSheet('BATCH EXPORT',
    h('label', { class: 'field-row' }, h('span', {}, 'COUNT'), count),
    h('div', { class: 'field-row' }, h('span', {}, 'MODE'), mode),
    progress,
    go);
}

async function runBatch(count, goBtn, progress) {
  if (batchResult) {
    // Second tap saves: share needs a fresh tap, and the render ran async.
    const result = await saveFile(batchResult);
    if (result !== 'cancelled') {
      flash(`BATCH ${count}`);
      closeSheet();
    }
    return;
  }
  goBtn.disabled = true;
  const savedSound = deepClone(state.sound);
  const savedSeed = state.variationSeed;
  const ac = state.activeChannel;
  const sounds = [];
  for (let i = 0; i < count; i++) {
    const s = deepClone(savedSound);
    if (batchMutate) {
      mutateChannel(s.channels[ac], state.activeLocks());
    } else {
      state.variationSeed = savedSeed + i;
      state.consumeVariationSeed();
      s.channels[ac] = randomizeAll(s.channels[ac], effectiveLocks(state.activeLocks()));
    }
    sounds.push(s);
  }
  state.variationSeed = savedSeed;

  flash('BATCH…');
  const files = await renderer.batch(sounds, exportOpts.sampleRate, exportOpts.bits, exportOpts.normalize,
    (n) => { progress.textContent = `Rendering ${n} / ${count}…`; });
  const ts = timestamp();
  const zip = makeZip(files.map((data, i) => ({ name: `batch_${ts}_${String(i + 1).padStart(3, '0')}.wav`, data })));
  batchResult = new File([zip], `hone_batch_${ts}.zip`, { type: 'application/zip' });
  progress.textContent = `${count} sounds ready (${(zip.size / 1024 / 1024).toFixed(1)} MB).`;
  goBtn.textContent = '↓ SAVE ZIP';
  goBtn.disabled = false;
}

// ── Tabs (phone layout) ────────────────────────────────────────────

function selectTab(name) {
  for (const b of document.querySelectorAll('.tabbar button')) {
    const on = b.dataset.tab === name;
    b.classList.toggle('active', on);
    b.setAttribute('aria-selected', String(on));
  }
  for (const p of document.querySelectorAll('.pane')) p.classList.toggle('shown', p.dataset.pane === name);
  document.getElementById('main').scrollTop = 0;
  window.scrollTo(0, 0);
  uiPrefs.tab = name;
  saveUiPrefs();
}

function buildDock() {
  $('#play').addEventListener('click', playCurrent);
  $('#gen').addEventListener('click', generate);
  $('#mutate').addEventListener('click', mutate);
  const auto = $('#autoplay');
  const syncAuto = () => {
    auto.classList.toggle('on', !!uiPrefs.autoplay);
    auto.setAttribute('aria-pressed', String(!!uiPrefs.autoplay));
  };
  auto.addEventListener('click', () => {
    uiPrefs.autoplay = !uiPrefs.autoplay;
    saveUiPrefs();
    syncAuto();
    flash(uiPrefs.autoplay ? 'AUTO-PLAY ON' : 'AUTO-PLAY OFF');
  });
  syncAuto();
  for (const b of document.querySelectorAll('.tabbar button')) {
    b.addEventListener('click', () => selectTab(b.dataset.tab));
  }
  selectTab(uiPrefs.tab || 'synth');
}

// ── Keyboard ───────────────────────────────────────────────────────

function onKey(e) {
  const t = e.target;
  if (t instanceof HTMLInputElement || t instanceof HTMLTextAreaElement || $('#sheet').open) return;
  const mod = e.metaKey || e.ctrlKey;
  if (mod && e.key.toLowerCase() === 'z') {
    e.preventDefault();
    if (e.shiftKey) redo();
    else undo();
    return;
  }
  if (mod || e.altKey) return;
  switch (e.key) {
    case ' ':
      e.preventDefault();
      playCurrent();
      break;
    case 'r': case 'R': applyAndPlay('PLAY'); break;
    case 'g': case 'G': generate(); break;
    case 'm': case 'M': mutate(); break;
    case 'e': case 'E': exportWav(); break;
    case '1': case '2': case '3': case '4': {
      const idx = Number(e.key) - 1;
      if (idx < state.sound.channels.length && idx !== state.activeChannel) selectChannel(idx);
      break;
    }
    default: return;
  }
}

// ── Boot ───────────────────────────────────────────────────────────

function boot() {
  applyTheme(Storage.loadTheme() || DEFAULT_THEME);

  buildHeader();
  buildChannelTabs();
  buildModules();
  buildMaster();
  buildPresets();
  buildExport();
  buildBin();
  buildSoundString();
  buildDock();

  $('#sheet-close').addEventListener('click', closeSheet);
  $('#sheet').addEventListener('click', (e) => { if (e.target === e.currentTarget) closeSheet(); });

  // Audio may only start inside a gesture on iOS — unlock on the first one.
  const unlock = () => player.unlock();
  window.addEventListener('pointerdown', unlock, { capture: true });
  window.addEventListener('keydown', unlock, { capture: true });
  window.addEventListener('keydown', onKey);

  state.bin = Storage.loadBin();

  // A shared link (#s=sfx7:…) opens that sound.
  const m = location.hash.match(/^#s=(.+)$/);
  if (m) {
    const s = soundFromString(decodeURIComponent(m[1]));
    if (s) {
      state.replaceSound(s);
      setTimeout(() => flash('LINK LOADED'), 0);
    }
    history.replaceState(null, '', location.pathname + location.search);
  }

  refreshEverything();
  refreshPresets();
  refreshExport();
  refreshBin();
  reRender();

  if ('serviceWorker' in navigator && location.protocol === 'https:') {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }
}

boot();
