// Téléchargement explicite d'une leçon (et ses exercices) pour consultation hors-ligne planifiée
// — au-delà du cache incidentel du service worker, utile pour une école sans connexion pendant plusieurs jours.
import { supabase } from "./supabase-client.js";
import { sauvegarderLeconHorsLigne, sauvegarderExerciceHorsLigne } from "./offline-db.js";

export async function telechargerLeconPourHorsLigne(leconId) {
  const { data: lecon, error: erreurLecon } = await supabase
    .from("lecons").select("*").eq("id", leconId).single();
  if (erreurLecon) throw erreurLecon;

  const { data: exercices, error: erreurExercices } = await supabase
    .from("exercices").select("*").eq("lecon_id", leconId).order("ordre");
  if (erreurExercices) throw erreurExercices;

  await sauvegarderLeconHorsLigne(lecon);
  for (const exercice of exercices || []) {
    await sauvegarderExerciceHorsLigne(exercice);
  }
  return { lecon, exercices };
}
