// Aides d'interface partagées : notifications, navigation par rôle, bandeau hors-ligne.
import { deconnexion, initialesDe } from "./auth.js";
import { demarrerSynchronisationAutomatique } from "./sync-engine.js";

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js").catch(() => {});
  });
}

const LIENS_PAR_ROLE = {
  ecolier: [
    { href: "/ecolier/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "🏠" },
    { href: "/ecolier/progres.html", id: "progres", label: "Mes progrès", icone: "📈" },
    { href: "/ecolier/badges.html", id: "badges", label: "Mes badges", icone: "🏅" },
  ],
  parent: [
    { href: "/parent/tableau-de-bord.html", id: "tableau-de-bord", label: "Mes enfants", icone: "🏠" },
    { href: "/parent/lier-enfant.html", id: "lier-enfant", label: "Lier un enfant", icone: "🔗" },
  ],
  enseignant: [
    { href: "/enseignant/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "🏠" },
    { href: "/enseignant/classes.html", id: "classes", label: "Mes classes", icone: "🏫" },
    { href: "/enseignant/lecons.html", id: "lecons", label: "Leçons", icone: "📘" },
    { href: "/enseignant/devoirs.html", id: "devoirs", label: "Devoirs", icone: "📝" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "🌍" },
  ],
  directeur: [
    { href: "/directeur/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "🏠" },
    { href: "/directeur/classes.html", id: "classes", label: "Classes de l'école", icone: "🏫" },
    { href: "/directeur/resultats.html", id: "resultats", label: "Résultats", icone: "📊" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "🌍" },
  ],
  agent_commune: [
    { href: "/commune/tableau-de-bord.html", id: "tableau-de-bord", label: "Écoles de la commune", icone: "🏠" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "🌍" },
  ],
  super_admin: [
    { href: "/super-admin/tableau-de-bord.html", id: "tableau-de-bord", label: "Accueil", icone: "🏠" },
    { href: "/super-admin/communes.html", id: "communes", label: "Communes & écoles", icone: "🏛️" },
    { href: "/super-admin/ressources.html", id: "ressources-gestion", label: "Gérer les ressources", icone: "🌍" },
    { href: "/ressources/liste.html", id: "ressources", label: "Ressources UNESCO", icone: "📚" },
  ],
};

const NOMS_ESPACE = {
  ecolier: "Espace Écolier",
  parent: "Espace Parent",
  enseignant: "Espace Enseignant",
  directeur: "Espace Directeur",
  agent_commune: "Espace Commune",
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
      <div class="app-nav__marque">🎓 ${NOMS_ESPACE[role]}</div>
      ${liens.map(l => `<a class="app-nav__lien${l.id === actif ? " actif" : ""}" href="${l.href}"><span>${l.icone}</span><span>${l.label}</span></a>`).join("")}
      <div class="app-nav__bas">
        ${profile ? `<div class="flex items-center gap-1"><span class="avatar-rond">${initialesDe(profile.prenom, profile.nom)}</span><span>${profile.prenom || ""}</span></div>` : ""}
        <button class="bouton bouton-contour bouton-bloc" id="bouton-deconnexion">Se déconnecter</button>
      </div>
    `;
  }
  if (topbar) {
    topbar.innerHTML = liens.map(l => `<a class="${l.id === actif ? "actif" : ""}" href="${l.href}">${l.icone}</a>`).join("")
      + `<a href="#" id="bouton-deconnexion-mobile">🚪</a>`;
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

export function echapperHtml(texte) {
  const div = document.createElement("div");
  div.textContent = texte ?? "";
  return div.innerHTML;
}
