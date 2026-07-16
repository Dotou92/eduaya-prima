// Service worker écrit à la main (pas de build) : cache le shell applicatif pour un
// fonctionnement hors-ligne. Les requêtes vers Supabase (autre origine) ne sont jamais
// interceptées ici — le cache des leçons/exercices se fait explicitement via IndexedDB
// (voir js/offline-db.js et js/content-cache.js), pas via ce cache HTTP générique.

const CACHE_NAME = "ecole-benin-v1";

const URLS_PRECACHEES = [
  "/",
  "/index.html",
  "/offline.html",
  "/manifest.json",
  "/css/style.css",
  "/js/config.js",
  "/js/supabase-client.js",
  "/js/auth.js",
  "/js/ui.js",
  "/js/exercises.js",
  "/js/offline-db.js",
  "/js/sync-engine.js",
  "/js/content-cache.js",
  "/icons/icon.svg",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(URLS_PRECACHEES))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((noms) => Promise.all(noms.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return; // laisse passer Supabase et les CDN tels quels

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request)
        .then((reponse) => {
          caches.open(CACHE_NAME).then((cache) => cache.put(request, reponse.clone()));
          return reponse;
        })
        .catch(() => caches.match(request).then((r) => r || caches.match("/offline.html")))
    );
    return;
  }

  // Stale-while-revalidate pour les fichiers statiques (CSS/JS/icônes).
  event.respondWith(
    caches.match(request).then((reponseCache) => {
      const misAJour = fetch(request)
        .then((reponseReseau) => {
          if (reponseReseau && reponseReseau.ok) {
            caches.open(CACHE_NAME).then((cache) => cache.put(request, reponseReseau.clone()));
          }
          return reponseReseau;
        })
        .catch(() => reponseCache);
      return reponseCache || misAJour;
    })
  );
});
