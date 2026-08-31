// sw.js — Phase 11g-a. The PWA shell's service worker.
//
// SCOPE OF THIS FILE, DELIBERATELY NARROW: this caches the APP SHELL
// (the HTML/JS/CSS that boots the Jaspr app) so a hard reload, a
// pasted link, or opening the installed app works with zero
// connection — DESIGN_BRIEF_COMMERCE.md §4's "installable, works
// offline" requirement. It does NOT cache API responses, does NOT
// queue sales, and does NOT know anything about products or the till.
// That is 11g-b/11g-c/11g-d/11g-f's job (an IndexedDB outbox + a
// last-known-catalog cache, both driven from Dart) — mixing that logic
// into this file would make the queue's correctness depend on service
// worker lifecycle quirks (versioning, activation timing, the browser
// evicting the cache under storage pressure) instead of an explicit,
// inspectable, testable data layer. This file's only job is: "can the
// page itself load with no network."
//
// STRATEGY: network-first for the shell, falling back to cache only on
// failure. NOT cache-first — main.dart.js changes on every deploy, and
// a cache-first shell would trap a returning-online user on a stale
// build forever, since nothing here would ever notice a fresher one
// exists. Network-first means: online, you always get what's actually
// deployed (and the cache quietly updates behind you); offline, you get
// the last version that ever loaded successfully. A brief network
// hiccup costs one extra round-trip, never staleness.
//
// SAME-ORIGIN, GET-ONLY. Deliberately does not intercept anything else
// — not Serverpod API calls (a different origin), not POST/PUT
// requests, not the Google Fonts stylesheet (cross-origin, and a
// missing web font offline is a cosmetic fallback-font degradation,
// not a functional break — not worth this file's complexity budget on
// its first pass). An intercepted API call silently answering from a
// stale cache would be a much worse bug than this file simply staying
// out of the way of anything it isn't confident about.

const CACHE_VERSION = 'kola-shell-v1';

const SHELL_ASSETS = [
  '/',
  '/index.html',
  '/styles.css',
  '/main.dart.js',
  '/favicon.ico',
  '/manifest.json',
  '/icon.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => cache.addAll(SHELL_ASSETS)),
  );
  // Take over immediately rather than waiting for every open tab to
  // close — this is a shell cache, not user data; there is nothing
  // unsafe about a new version taking effect right away.
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_VERSION)
          .map((key) => caches.delete(key)),
      ),
    ),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Only GET — a POST/PUT to the Serverpod API must never be answered
  // by this worker, cached or otherwise.
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // A navigation (address bar hit, refresh, pasted link, opening the
  // installed app) — mirror web/_redirects' own SPA-fallback behaviour
  // so a route like /knowledge resolves offline exactly as it does
  // online: served index.html, router reads the URL, correct page
  // renders. Without this, an offline hard-load of a nested route
  // would fail even though the shell itself is cached.
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          caches.open(CACHE_VERSION).then((cache) => cache.put('/index.html', response.clone()));
          return response;
        })
        .catch(() => caches.match('/index.html')),
    );
    return;
  }

  if (SHELL_ASSETS.includes(url.pathname)) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Only cache a real, successful response — never cache an
          // error page as if it were the app shell.
          if (response.ok) {
            caches.open(CACHE_VERSION).then((cache) => cache.put(request, response.clone()));
          }
          return response;
        })
        .catch(() => caches.match(request)),
    );
  }
  // Anything else same-origin (e.g. a future asset not in the shell
  // list) just goes to the network untouched.
});
