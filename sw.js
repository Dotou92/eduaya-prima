// Service worker écrit à la main (pas de build) : cache le shell applicatif pour un
// fonctionnement hors-ligne. Les requêtes vers Supabase (autre origine) ne sont jamais
// interceptées ici — le cache des leçons/exercices se fait explicitement via IndexedDB
// (voir js/offline-db.js et js/content-cache.js), pas via ce cache HTTP générique.
//
// IMPORTANT : incrémenter CACHE_NAME à chaque modification de ce fichier force les
// navigateurs à réinstaller le service worker (sinon, tant que ce fichier ne change
// pas d'un seul octet, l'ancien service worker et son cache restent actifs indéfiniment
// — c'est ce qui a provoqué du JS périmé pendant plusieurs déploiements).

const CACHE_NAME = "ecole-benin-v2";

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
  "/js/icons.js",
  "/js/charts.js",
  "/js/exercises.js",
  "/js/offline-db.js",
  "/js/sync-engine.js",
  "/js/content-cache.js",
  "/js/reference-data.js",
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

  // Réseau en priorité pour les fichiers statiques (CSS/JS/icônes) : le code doit
  // toujours être à jour pour un utilisateur en ligne. Le cache ne sert que de secours
  // hors-ligne, jamais de version "pas trop vieille" servie par défaut.
  event.respondWith(
    fetch(request)
      .then((reponseReseau) => {
        if (reponseReseau && reponseReseau.ok) {
          caches.open(CACHE_NAME).then((cache) => cache.put(request, reponseReseau.clone()));
        }
        return reponseReseau;
      })
      .catch(() => caches.match(request))
  );
});
