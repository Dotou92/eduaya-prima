// Moteur de synchronisation : vide la file d'attente locale (IndexedDB) vers Supabase
// dès qu'une connexion est disponible. Chaque tentative porte un client_uuid unique
// généré hors-ligne, ce qui rend le renvoi idempotent (pas de doublon possible en base).
import { supabase } from "./supabase-client.js";
import {
  listerTentativesEnAttente,
  supprimerTentativeEnAttente,
  incrementerEchecTentative,
} from "./offline-db.js";

let enCours = false;
const ecouteurs = new Set();

export function surSynchronisation(fn) {
  ecouteurs.add(fn);
  return () => ecouteurs.delete(fn);
}

function notifier(evenement) {
  for (const fn of ecouteurs) fn(evenement);
}

export async function synchroniserTentatives() {
  if (enCours || !navigator.onLine) return;
  enCours = true;
  try {
    const enAttente = await listerTentativesEnAttente();
    if (enAttente.length === 0) return;
    notifier({ type: "debut", total: enAttente.length });

    for (const tentative of enAttente) {
      try {
        const { client_uuid, statut, tentatives_envoi, cree_le, ...donnees } = tentative;
        const { error } = await supabase.from("tentatives").insert({
          ...donnees,
          client_uuid,
          source: "sync_hors_ligne",
        });
        // Code 23505 = violation de contrainte unique : déjà synchronisé précédemment, on l'accepte.
        if (error && error.code !== "23505") throw error;
        await supprimerTentativeEnAttente(client_uuid);
        notifier({ type: "progres", client_uuid });
      } catch (e) {
        await incrementerEchecTentative(tentative.client_uuid);
        notifier({ type: "erreur", client_uuid: tentative.client_uuid, erreur: e });
      }
    }
    notifier({ type: "fin" });
  } finally {
    enCours = false;
  }
}

let minuteurDemarre = false;
export function demarrerSynchronisationAutomatique() {
  if (minuteurDemarre) return;
  minuteurDemarre = true;
  window.addEventListener("online", synchroniserTentatives);
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") synchroniserTentatives();
  });
  setInterval(synchroniserTentatives, 60_000);
  synchroniserTentatives();
}
