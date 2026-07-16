// Client Supabase partagé — chargé depuis un CDN, aucune installation locale nécessaire.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

// Client principal : garde la session connectée (élève, parent ou enseignant) dans localStorage.
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true },
});

// Client jetable, sans persistance : utilisé pour créer un compte élève depuis l'espace
// enseignant sans écraser la session de l'enseignant actuellement connecté.
export function creerClientJetable() {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
