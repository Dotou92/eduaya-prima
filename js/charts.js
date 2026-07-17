// Graphique en barres horizontales minimal, sans dépendance externe.
// Usage : comparer une même métrique (ex. score moyen en %) entre plusieurs
// entités (classes, écoles). Une seule série → une seule couleur (l'accent de
// l'espace courant), valeurs affichées directement (pas besoin de légende ni
// d'infobulle pour ce cas simple : le tableau détaillé reste toujours présent
// juste à côté sur la page, qui sert de vue "données brutes").
import { echapperHtml } from "./ui.js";

// donnees: [{ label: string, valeur: number|null }] — valeur en pourcentage (0-100), null = pas de données.
export function graphiqueBarres(conteneur, donnees) {
  if (!conteneur) return;
  if (!donnees || donnees.length === 0) {
    conteneur.innerHTML = `<p class="texte-att">Pas encore de données à comparer.</p>`;
    return;
  }
  conteneur.innerHTML = `
    <div class="graphique-barres">
      ${donnees.map(d => `
        <div class="graphique-barres__ligne">
          <span class="graphique-barres__label" title="${echapperHtml(d.label)}">${echapperHtml(d.label)}</span>
          <span class="graphique-barres__piste">
            <span class="graphique-barres__valeur" style="width:${d.valeur ?? 0}%;"></span>
          </span>
          <span class="graphique-barres__chiffre">${d.valeur === null || d.valeur === undefined ? "—" : `${Math.round(d.valeur)}%`}</span>
        </div>
      `).join("")}
    </div>
  `;
}
