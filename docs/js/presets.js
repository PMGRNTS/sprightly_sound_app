// Preset dispatcher. Port of scripts/presets.gd. Patch presets respect
// the user's lock map and return one channel; sound presets return a
// whole multi-channel Sound.

import { GROUPS, REGISTRY } from './presets-generated.js';
import { cloneMaster } from './sound-data.js';

export { REGISTRY };
export { effectiveLocks, randomizeAll, mutateChannel } from './presets-helpers.js';

// Twelve registry groups fold into six display tabs (presentation only —
// dispatch still uses the source group).
export const PRESET_DISPLAY_GROUPS = {
  FIREARM: 'COMBAT',
  MELEE: 'COMBAT',
  FOLEY: 'FOLEY',
  IMPACT: 'FOLEY',
  WEATHER: 'NATURE',
  ANIMAL: 'NATURE',
  MAGIC: 'FANTASY',
  MONSTER: 'FANTASY',
  SCIFI: 'TECH',
  MACHINE: 'TECH',
  UI: 'UI',
  GAME: 'UI',
};

export function runPreset(entry, params, locked) {
  const fn = GROUPS[entry.group]?.[entry.fn];
  if (!fn) {
    console.warn(`Unknown preset ${entry.group}/${entry.fn}`);
    return null;
  }
  if (entry.kind === 'sound') {
    const s = fn();
    return { channels: s.channels, master: { ...cloneMaster(), ...s.master } };
  }
  return fn(params, locked);
}
