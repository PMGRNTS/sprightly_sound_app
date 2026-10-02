// Seedable global RNG — the web stand-in for Godot's seed() / randf().
//
// Presets and GEN draw from this stream after the variation seed is
// consumed, so the same seed always yields the same take. (The stream is
// mulberry32, not Godot's PCG32, so a given seed produces a different
// take here than in the desktop build — but it is stable within the web
// app.) Synthesis noise uses Math.random and never touches this stream.

let state = (Math.random() * 0x100000000) >>> 0;

export function seed(n) {
  // Spread small integer seeds across the state space so seed 1 and seed 2
  // don't start on nearly identical streams.
  state = Math.imul((n >>> 0) ^ 0x9e3779b9, 0x85ebca6b) >>> 0;
}

export function randf() {
  state = (state + 0x6d2b79f5) >>> 0;
  let t = state;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

export function randi() {
  return Math.floor(randf() * 0x100000000);
}
