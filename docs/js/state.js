// Sound, channels, locks, samples, undo/redo and bin. Port of
// scripts/app/sound_state.gd — a pure data container; app.js mutates it
// through these methods and then refreshes the UI.

import { seed, randi } from './rng.js';
import { MAX_CHANNELS, cloneParams, cloneMaster, defaultSound, deepClone } from './sound-data.js';

const UNDO_MAX = 50;
const BIN_MAX = 100;

export class SoundState {
  constructor() {
    this.sound = defaultSound();
    this.activeChannel = 0;
    this.locks = [{}];
    this.samples = new Float32Array(0);
    this.soundString = '';
    this.bin = [];
    // Snapshots are taken before discrete replacements (GEN, preset,
    // paste, bin-load) — never on knob drags, which would flood the stack.
    this.undoStack = [];
    this.redoStack = [];
    // Consumed before every preset / GEN, then incremented: each tap is a
    // fresh take, and typing an earlier value brings that take back.
    this.variationSeed = 0;
  }

  snapshot() {
    return { sound: deepClone(this.sound), locks: deepClone(this.locks), activeChannel: this.activeChannel };
  }

  pushUndo() {
    this.undoStack.push(this.snapshot());
    if (this.undoStack.length > UNDO_MAX) this.undoStack.shift();
    this.redoStack.length = 0;
  }

  undo() {
    if (!this.undoStack.length) return false;
    this.redoStack.push(this.snapshot());
    if (this.redoStack.length > UNDO_MAX) this.redoStack.shift();
    this._restore(this.undoStack.pop());
    return true;
  }

  redo() {
    if (!this.redoStack.length) return false;
    this.undoStack.push(this.snapshot());
    if (this.undoStack.length > UNDO_MAX) this.undoStack.shift();
    this._restore(this.redoStack.pop());
    return true;
  }

  _restore(snap) {
    this.sound = snap.sound;
    this.locks = snap.locks;
    this.activeChannel = Math.min(Math.max(0, snap.activeChannel), this.sound.channels.length - 1);
  }

  // Replace the whole sound; locks reset, jump to channel 1.
  replaceSound(newSound) {
    this.sound = newSound;
    this.locks = newSound.channels.map(() => ({}));
    this.activeChannel = 0;
  }

  // Patch presets collapse to a fresh single-channel sound, keeping the
  // active channel's locks.
  applyPatchPreset(patch) {
    const preserved = deepClone(this.activeLocks());
    this.sound = { channels: [{ ...cloneParams(), ...patch }], master: cloneMaster() };
    this.locks = [preserved];
    this.activeChannel = 0;
  }

  addChannel() {
    if (this.sound.channels.length >= MAX_CHANNELS) return false;
    this.sound.channels.push(cloneParams());
    this.locks.push({});
    this.activeChannel = this.sound.channels.length - 1;
    return true;
  }

  removeChannel(idx) {
    if (this.sound.channels.length <= 1) return false;
    this.sound.channels.splice(idx, 1);
    if (idx < this.locks.length) this.locks.splice(idx, 1);
    if (idx < this.activeChannel) this.activeChannel--;
    else if (idx === this.activeChannel) this.activeChannel = Math.max(0, this.activeChannel - 1);
    return true;
  }

  consumeVariationSeed() {
    seed(this.variationSeed);
    this.variationSeed = (this.variationSeed + 1) % 10000;
  }

  randomizeVariationSeed() {
    this.variationSeed = randi() % 10000;
  }

  addToBin(entry) {
    this.bin.unshift(entry);
    if (this.bin.length > BIN_MAX) this.bin.length = BIN_MAX;
  }

  removeFromBin(id) {
    this.bin = this.bin.filter((e) => e.id !== id);
  }

  findBinEntry(id) {
    return this.bin.find((e) => e.id === id) || null;
  }

  activeLocks() {
    return this.locks[this.activeChannel] || (this.locks[this.activeChannel] = {});
  }

  activeParams() {
    return this.sound.channels[this.activeChannel];
  }
}
