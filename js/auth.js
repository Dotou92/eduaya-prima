// Aide à l'authentification et au contrôle d'accès par rôle.
// Comme il n'y a pas de serveur, le contrôle de rôle repose sur les policies RLS
// de Supabase (source de vérité) ; ce module ne fait que guider la navigation.
import { supabase } from "./supabase-client.js";

export const TABLEAUX_DE_BORD = {
  ecolier: "/ecolier/tableau-de-bord.html",
  parent: "/parent/tableau-de-bord.html",
  enseignant: "/enseignant/tableau-de-bord.html",
  directeur: "/directeur/tableau-de-bord.html",
  agent_commune: "/commune/tableau-de-bord.html",
  agent_numerique: "/numerique/tableau-de-bord.html",
  super_admin: "/super-admin/tableau-de-bord.html",
};

// Récupère la session active et le profil associé (table `profiles`).
export async function obtenirSessionEtProfil() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", session.user.id)
    .single();

  if (error || !profile) return null;
  return { user: session.user, profile };
}

// À appeler en haut de chaque page protégée. Redirige si non connecté ou mauvais rôle.
// roleAttendu peut être une chaîne ("enseignant") ou un tableau de rôles autorisés
// (["enseignant", "directeur"]) pour les pages partagées entre plusieurs rôles.
// Retourne { user, profile } si tout est en ordre.
export async function exigerRole(roleAttendu) {
  const contexte = await obtenirSessionEtProfil();
  if (!contexte) {
    window.location.href = "/auth/login.html";
    return null;
  }
  const rolesAutorises = Array.isArray(roleAttendu) ? roleAttendu : [roleAttendu];
  if (!rolesAutorises.includes(contexte.profile.role)) {
    window.location.href = TABLEAUX_DE_BORD[contexte.profile.role] || "/auth/login.html";
    return null;
  }
  return contexte;
}

export async function deconnexion() {
  await supabase.auth.signOut();
  window.location.href = "/auth/login.html";
}

export function initialesDe(prenom, nom) {
  const a = (prenom || "").trim()[0] || "";
  const b = (nom || "").trim()[0] || "";
  return (a + b).toUpperCase() || "?";
}
