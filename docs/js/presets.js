// Preset dispatcher. Port of scripts/presets.gd. Patch presets respect
// the user's lock map and return one channel; sound presets return a
// whole multi-channel Sound.

import { GROUPS, REGISTRY } from './presets-generated.js';
import { cloneMaster } from './sound-data.js';

export { REGISTRY };
export { effectiveLocks, randomizeAll, mutateChannel } from './presets-helpers.js';

// Ten registry groups fold into five display tabs (presentation only —
// dispatch still uses the source group).
export const PRESET_DISPLAY_GROUPS = {
  SHOOTER: 'COMBAT',
  DESTRUCT: 'COMBAT',
  MODERN: 'COMBAT',
  ARCADE: 'ARCADE',
  'MUSIC-UI': 'ARCADE',
  UI: 'UI',
  MAGIC: 'FANTASY',
  CREATURE: 'FANTASY',
  MOVEMENT: 'WORLD',
  AMBIENT: 'WORLD',
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
