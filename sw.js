/* Network first, cache as a fallback.
   You push an update and get it on the next load; if the wifi is out, the
   last good copy still opens. Bump CACHE to force everyone onto a new shell. */
const CACHE = 'lesson-planner-v2';
const SHELL = ['./', './index.html', './manifest.json',
               './icon-192.png', './icon-512.png', './icon-maskable-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE)
    .then(c => c.addAll(SHELL))
    .then(() => self.skipWaiting())
    .catch(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  /* Page loads skip the HTTP cache entirely. GitHub Pages serves assets with
     a ten-minute max-age, so without this a fresh deploy could sit unseen for
     ten minutes even on a reload — the update would be on the server and the
     browser would never ask for it. Everything else can use the cache. */
  const req = e.request.mode === 'navigate'
    ? new Request(e.request.url, { cache:'no-store' })
    : e.request;
  e.respondWith(
    fetch(req)
      .then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(e.request).then(r => r || caches.match('./index.html')))
  );
});
