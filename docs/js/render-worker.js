// Off-main-thread renderer. Heavy patches (four long channels with delay
// and a big reverb) take a second or more on a phone; rendering here
// keeps knob drags and scrolling smooth meanwhile.

import { renderSound } from './synth.js';
import { normalize, encodeWav } from './sound-data.js';

self.onmessage = (e) => {
  const { id, type } = e.data;
  if (type === 'render') {
    const samples = renderSound(e.data.sound);
    self.postMessage({ id, samples }, [samples.buffer]);
  } else if (type === 'batch') {
    const { sounds, sampleRate, bits, doNormalize } = e.data;
    const files = [];
    sounds.forEach((sound, i) => {
      let buf = renderSound(sound);
      if (doNormalize) buf = normalize(buf);
      files.push(encodeWav(buf, sampleRate, bits));
      self.postMessage({ id, progress: i + 1 });
    });
    self.postMessage({ id, files }, files.map((f) => f.buffer));
  }
};
