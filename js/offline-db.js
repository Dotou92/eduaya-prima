// Stockage local (IndexedDB) pour l'usage hors-ligne : leçons/exercices téléchargés
// et file d'attente des tentatives d'exercice en attente de synchronisation.
// Écrit à la main (sans dépendance externe) pour rester utilisable même sans réseau
// au tout premier chargement une fois le service worker installé.

const NOM_DB = "primaire-offline";
const VERSION_DB = 1;

function ouvrirDB() {
  return new Promise((resolve, reject) => {
    const requete = indexedDB.open(NOM_DB, VERSION_DB);
    requete.onupgradeneeded = () => {
      const db = requete.result;
      if (!db.objectStoreNames.contains("lecons")) {
        db.createObjectStore("lecons", { keyPath: "id" });
      }
      if (!db.objectStoreNames.contains("exercices")) {
        db.createObjectStore("exercices", { keyPath: "id" });
      }
      if (!db.objectStoreNames.contains("tentatives_queue")) {
        db.createObjectStore("tentatives_queue", { keyPath: "client_uuid" });
      }
    };
    requete.onsuccess = () => resolve(requete.result);
    requete.onerror = () => reject(requete.error);
  });
}

async function magasin(nom, mode) {
  const db = await ouvrirDB();
  const transaction = db.transaction(nom, mode);
  return transaction.objectStore(nom);
}

function enPromesse(requete) {
  return new Promise((resolve, reject) => {
    requete.onsuccess = () => resolve(requete.result);
    requete.onerror = () => reject(requete.error);
  });
}

// ---- Leçons & exercices mis en cache pour consultation hors-ligne ----

export async function sauvegarderLeconHorsLigne(lecon) {
  const store = await magasin("lecons", "readwrite");
  await enPromesse(store.put(lecon));
}

export async function obtenirLeconHorsLigne(id) {
  const store = await magasin("lecons", "readonly");
  return enPromesse(store.get(id));
}

export async function listerLeconsHorsLigne() {
  const store = await magasin("lecons", "readonly");
  return enPromesse(store.getAll());
}

export async function sauvegarderExerciceHorsLigne(exercice) {
  const store = await magasin("exercices", "readwrite");
  await enPromesse(store.put(exercice));
}

export async function obtenirExerciceHorsLigne(id) {
  const store = await magasin("exercices", "readonly");
  return enPromesse(store.get(id));
}

export async function listerExercicesDeLeconHorsLigne(leconId) {
  const tous = await (async () => {
    const store = await magasin("exercices", "readonly");
    return enPromesse(store.getAll());
  })();
  return tous.filter(e => e.lecon_id === leconId);
}

// ---- File d'attente des tentatives (résultats d'exercices) ----

export async function mettreTentativeEnAttente(tentative) {
  const store = await magasin("tentatives_queue", "readwrite");
  await enPromesse(store.put({
    ...tentative,
    statut: "en_attente",
    tentatives_envoi: 0,
    cree_le: tentative.cree_le || new Date().toISOString(),
  }));
}

export async function listerTentativesEnAttente() {
  const store = await magasin("tentatives_queue", "readonly");
  return enPromesse(store.getAll());
}

export async function supprimerTentativeEnAttente(clientUuid) {
  const store = await magasin("tentatives_queue", "readwrite");
  await enPromesse(store.delete(clientUuid));
}

export async function incrementerEchecTentative(clientUuid) {
  const store = await magasin("tentatives_queue", "readwrite");
  const item = await enPromesse(store.get(clientUuid));
  if (!item) return;
  item.tentatives_envoi = (item.tentatives_envoi || 0) + 1;
  item.statut = "echec";
  await enPromesse(store.put(item));
}

export async function compterTentativesEnAttente() {
  const toutes = await listerTentativesEnAttente();
  return toutes.length;
}
