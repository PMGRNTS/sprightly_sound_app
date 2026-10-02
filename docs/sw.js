// Offline support for the Home Screen app. Network-first: when online you
// always get the latest deploy; the cache is only the fallback, so there
// is no stale-version dance after pushing an update. Bump CACHE when the
// file list changes.

const CACHE = 'hone-v1';
const SHELL = [
  './',
  'index.html',
  'style.css',
  'manifest.webmanifest',
  'icons/icon.svg',
  'icons/apple-touch-icon.png',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'js/app.js',
  'js/audio.js',
  'js/knob.js',
  'js/presets.js',
  'js/presets-generated.js',
  'js/presets-helpers.js',
  'js/render-worker.js',
  'js/rng.js',
  'js/sound-data.js',
  'js/state.js',
  'js/storage.js',
  'js/synth.js',
  'js/themes.js',
  'js/waveform.js',
  'js/zip.js',
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== self.location.origin) return;
  e.respondWith(
    fetch(req)
      .then((res) => {
        if (res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
        }
        return res;
      })
      .catch(() => caches.match(req, { ignoreSearch: true }).then((hit) => hit || caches.match('index.html'))),
  );
});
