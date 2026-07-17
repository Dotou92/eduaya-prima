// Aides d'interface partagées : notifications, navigation par rôle, bandeau hors-ligne.
import { deconnexion, initialesDe } from "./auth.js";
import { demarrerSynchronisationAutomatique } from "./sync-engine.js";
import { icone, logoMarque } from "./icons.js";

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js").catch(() => {});
  });
}

const LIENS_PAR_ROLE = {
  ecolier: [
    { href: "/ecolier/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "accueil" },
    { href: "/ecolier/progres.html", id: "progres", label: "Mes progrès", icone: "graphique" },
    { href: "/ecolier/badges.html", id: "badges", label: "Mes badges", icone: "medaille" },
  ],
  parent: [
    { href: "/parent/tableau-de-bord.html", id: "tableau-de-bord", label: "Mes enfants", icone: "accueil" },
    { href: "/parent/lier-enfant.html", id: "lier-enfant", label: "Lier un enfant", icone: "lien" },
  ],
  enseignant: [
    { href: "/enseignant/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "accueil" },
    { href: "/enseignant/classes.html", id: "classes", label: "Mes classes", icone: "ecole" },
    { href: "/enseignant/lecons.html", id: "lecons", label: "Leçons", icone: "livre" },
    { href: "/enseignant/devoirs.html", id: "devoirs", label: "Devoirs", icone: "carnet" },
    { href: "/enseignant/messages.html", id: "messages", label: "Messages", icone: "message" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "globe" },
  ],
  directeur: [
    { href: "/directeur/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "accueil" },
    { href: "/directeur/classes.html", id: "classes", label: "Classes de l'école", icone: "ecole" },
    { href: "/directeur/resultats.html", id: "resultats", label: "Résultats", icone: "graphique" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "globe" },
  ],
  agent_commune: [
    { href: "/commune/tableau-de-bord.html", id: "tableau-de-bord", label: "Écoles de la commune", icone: "accueil" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "globe" },
  ],
  agent_numerique: [
    { href: "/numerique/tableau-de-bord.html", id: "tableau-de-bord", label: "Utilisation par école", icone: "accueil" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "globe" },
  ],
  super_admin: [
    { href: "/super-admin/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "accueil" },
    { href: "/super-admin/communes.html", id: "communes", label: "Communes & écoles", icone: "batiment" },
    { href: "/super-admin/comptes.html", id: "comptes", label: "Comptes institutionnels", icone: "personnes" },
    { href: "/super-admin/ressources.html", id: "ressources-gestion", label: "Gérer les ressources", icone: "reglages" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "globe" },
  ],
};

const NOMS_ESPACE = {
  ecolier: "Espace Écolier",
  parent: "Espace Parent",
  enseignant: "Espace Enseignant",
  directeur: "Espace Directeur",
  agent_commune: "Espace Commune",
  agent_numerique: "Espace Numérique",
  super_admin: "Super-Admin",
};

// Construit la nav latérale + la barre mobile, et branche déconnexion/affichage profil.
// role: 'ecolier' | 'parent' | 'enseignant' — actif: id du lien courant.
export function initLayout({ role, actif, profile }) {
  document.body.classList.add(`espace-${role}`);
  const liens = LIENS_PAR_ROLE[role] || [];

  const nav = document.getElementById("app-nav");
  const topbar = document.getElementById("app-topbar-liens");

  if (nav) {
    nav.innerHTML = `
      <div class="app-nav__marque">${logoMarque(24)} ${NOMS_ESPACE[role]}</div>
      ${liens.map(l => `<a class="app-nav__lien${l.id === actif ? " actif" : ""}" href="${l.href}">${icone(l.icone)}<span>${l.label}</span></a>`).join("")}
      <div class="app-nav__bas">
        ${profile ? `<div class="flex items-center gap-1"><span class="avatar-rond">${initialesDe(profile.prenom, profile.nom)}</span><span>${profile.prenom || ""}</span></div>` : ""}
        <button class="bouton bouton-contour bouton-bloc" id="bouton-deconnexion">${icone("deconnexion", 16)} Se déconnecter</button>
      </div>
    `;
  }
  if (topbar) {
    topbar.innerHTML = liens.map(l => `<a class="${l.id === actif ? "actif" : ""}" href="${l.href}">${icone(l.icone)}</a>`).join("")
      + `<a href="#" id="bouton-deconnexion-mobile">${icone("deconnexion")}</a>`;
  }

  document.getElementById("bouton-deconnexion")?.addEventListener("click", deconnexion);
  document.getElementById("bouton-deconnexion-mobile")?.addEventListener("click", (e) => { e.preventDefault(); deconnexion(); });

  initBandeauHorsLigne();
  demarrerSynchronisationAutomatique();
}

export function afficherToast(message, type = "info") {
  let zone = document.querySelector(".toast-zone");
  if (!zone) {
    zone = document.createElement("div");
    zone.className = "toast-zone";
    document.body.appendChild(zone);
  }
  const toast = document.createElement("div");
  toast.className = "toast";
  if (type === "erreur") toast.style.background = "#d62828";
  if (type === "succes") toast.style.background = "#2b8a3e";
  toast.textContent = message;
  zone.appendChild(toast);
  setTimeout(() => toast.remove(), 4000);
}

export function initBandeauHorsLigne() {
  const bandeau = document.getElementById("bandeau-hors-ligne");
  if (!bandeau) return;
  const majEtat = () => bandeau.classList.toggle("visible", !navigator.onLine);
  majEtat();
  window.addEventListener("online", majEtat);
  window.addEventListener("offline", majEtat);
}

export function parametreUrl(nom) {
  return new URLSearchParams(window.location.search).get(nom);
}

export function formaterDate(iso) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("fr-FR", { day: "2-digit", month: "short", year: "numeric" });
}

export function genererCode(longueur = 10) {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
  let resultat = "";
  for (let i = 0; i < longueur; i++) resultat += alphabet[Math.floor(Math.random() * alphabet.length)];
  return resultat;
}

// Exporte un tableau d'objets en CSV et déclenche le téléchargement (aucune dépendance).
export function exporterCSV(nomFichier, entetes, lignes) {
  const echapperCellule = (v) => {
    const s = v === null || v === undefined ? "" : String(v);
    return /[";\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const contenu = [entetes, ...lignes].map(l => l.map(echapperCellule).join(";")).join("\r\n");
  const blob = new Blob(["﻿" + contenu], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const lien = document.createElement("a");
  lien.href = url;
  lien.download = nomFichier.endsWith(".csv") ? nomFichier : `${nomFichier}.csv`;
  document.body.appendChild(lien);
  lien.click();
  lien.remove();
  URL.revokeObjectURL(url);
}

export function echapperHtml(texte) {
  const div = document.createElement("div");
  div.textContent = texte ?? "";
  return div.innerHTML;
}
