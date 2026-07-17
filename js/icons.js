// Petit set d'icônes SVG inline (style trait, 24x24, hérite la couleur via `currentColor`).
// Évite toute dépendance externe — cohérent avec le reste du projet (aucun build, aucun CDN d'icônes).

const TRACE = 'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';

const ICONES = {
  accueil: `<path ${TRACE} d="M3 11.5 12 4l9 7.5"/><path ${TRACE} d="M5 10v9a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1v-9"/>`,
  ecole: `<path ${TRACE} d="M12 3 2 8l10 5 10-5-10-5Z"/><path ${TRACE} d="M6 10.5V16c0 1 2.5 3 6 3s6-2 6-3v-5.5"/><path ${TRACE} d="M22 8v6"/>`,
  livre: `<path ${TRACE} d="M4 4.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5V4.5Z"/><path ${TRACE} d="M4 20.5A2.5 2.5 0 0 1 6.5 18H20"/>`,
  carnet: `<rect x="4" y="3" width="16" height="18" rx="2" ${TRACE}/><path ${TRACE} d="M8 8h8M8 12h8M8 16h5"/>`,
  graphique: `<path ${TRACE} d="M4 20V10M11 20V4M18 20v-7"/><path ${TRACE} d="M3 20h18"/>`,
  medaille: `<circle cx="12" cy="9" r="6" ${TRACE}/><path ${TRACE} d="m8.5 14-1.7 6.5L12 18l5.2 2.5L15.5 14"/>`,
  lien: `<path ${TRACE} d="M9 12a4 4 0 0 0 5.5 1.2l3-3a4 4 0 0 0-5.5-5.6l-1.6 1.6"/><path ${TRACE} d="M15 12a4 4 0 0 0-5.5-1.2l-3 3a4 4 0 0 0 5.5 5.6l1.5-1.5"/>`,
  globe: `<circle cx="12" cy="12" r="9" ${TRACE}/><path ${TRACE} d="M3 12h18M12 3c2.5 2.6 4 6 4 9s-1.5 6.4-4 9c-2.5-2.6-4-6-4-9s1.5-6.4 4-9Z"/>`,
  batiment: `<path ${TRACE} d="M4 21V9l8-5 8 5v12"/><path ${TRACE} d="M4 21h16M9 21v-6h6v6"/>`,
  reglages: `<circle cx="12" cy="12" r="3" ${TRACE}/><path ${TRACE} d="M19.4 13a7.6 7.6 0 0 0 0-2l2-1.5-2-3.4-2.4.6a7.7 7.7 0 0 0-1.7-1L15 3h-4l-.3 2.7a7.7 7.7 0 0 0-1.7 1l-2.4-.6-2 3.4L6.6 11a7.6 7.6 0 0 0 0 2l-2 1.5 2 3.4 2.4-.6c.5.4 1.1.75 1.7 1L10 21h4l.3-2.7c.6-.25 1.2-.6 1.7-1l2.4.6 2-3.4-2-1.5Z"/>`,
  deconnexion: `<path ${TRACE} d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path ${TRACE} d="M16 17l5-5-5-5"/><path ${TRACE} d="M21 12H9"/>`,
  personnes: `<circle cx="9" cy="8" r="3" ${TRACE}/><path ${TRACE} d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6"/><circle cx="17.5" cy="8.5" r="2.3" ${TRACE}/><path ${TRACE} d="M15.5 14.3c2.6.4 4.5 2.6 4.5 5.2"/>`,
  message: `<path ${TRACE} d="M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v10a1.5 1.5 0 0 1-1.5 1.5H9l-4.5 4v-4H5.5A1.5 1.5 0 0 1 4 15.5v-10Z"/>`,
  alerte: `<path ${TRACE} d="M12 3 2 20h20L12 3Z"/><path ${TRACE} d="M12 10v4"/><circle cx="12" cy="17" r="0.6" fill="currentColor" stroke="none"/>`,
};

// Retourne le HTML d'une icône (24x24 par défaut). `cle` doit exister dans ICONES.
export function icone(cle, taille = 20) {
  const trace = ICONES[cle];
  if (!trace) return "";
  return `<svg width="${taille}" height="${taille}" viewBox="0 0 24 24" aria-hidden="true">${trace}</svg>`;
}

// Petit logo de marque (même silhouette que icons/icon.svg, simplifié pour un usage inline en petite taille).
export function logoMarque(taille = 22) {
  return `<svg width="${taille}" height="${taille}" viewBox="0 0 24 24" aria-hidden="true">
    <path fill="currentColor" d="M12 2 1.5 7.5 12 13l8-4.2V13h1.5V7.5L12 2Z"/>
    <path fill="currentColor" d="M5 9.6v4.7c0 1.9 3.1 4.2 7 4.2s7-2.3 7-4.2V9.6l-7 3.7-7-3.7Z" opacity="0.55"/>
  </svg>`;
}
