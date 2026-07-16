// Données de référence (niveaux, matières) — partagées par toutes les pages.
import { supabase } from "./supabase-client.js";

let capNiveaux = null;
let capMatieres = null;

export async function obtenirNiveaux() {
  if (capNiveaux) return capNiveaux;
  const { data } = await supabase.from("niveaux").select("*").order("ordre");
  capNiveaux = data || [];
  return capNiveaux;
}

export async function obtenirMatieres() {
  if (capMatieres) return capMatieres;
  const { data } = await supabase.from("matieres").select("*").order("id");
  capMatieres = data || [];
  return capMatieres;
}

export function optionsNiveaux(niveaux, valeurSelectionnee) {
  return niveaux.map(n => `<option value="${n.id}" ${n.id == valeurSelectionnee ? "selected" : ""}>${n.code} — ${n.nom}</option>`).join("");
}

export function optionsMatieres(matieres, valeurSelectionnee) {
  return matieres.map(m => `<option value="${m.id}" ${m.id == valeurSelectionnee ? "selected" : ""}>${m.icone || ""} ${m.nom}</option>`).join("");
}
