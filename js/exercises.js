// Modèle des exercices et correction automatique — 100% côté client, sans réseau.
// Permet une correction instantanée même hors-ligne.
//
// Formats de `contenu` (stocké en jsonb dans la table `exercices`) :
//
//  qcm            { type, question, choix: [{id, texte}], bonnesReponses: [id...], multiple }
//  texte_a_trous  { type, texte /* contient {{id}} */, trous: [{id, reponsesAcceptees: [texte...]}] }
//  association    { type, paires: [{id, gauche, droite}] }
//  vrai_faux      { type, affirmation, reponse: true|false }
//
// Formats de `reponse` (ce que l'apprenant a saisi) :
//  qcm            { selection: [id...] }
//  texte_a_trous  { valeurs: { [trouId]: texte } }
//  association    { associations: { [paireId]: paireIdChoisie } }
//  vrai_faux      { valeur: true|false }

function normaliserTexte(t) {
  return (t ?? "")
    .toString()
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, ""); // retire les accents pour tolérer les fautes de frappe
}

function corrigerQcm(contenu, reponse) {
  const selection = new Set(reponse?.selection || []);
  const bonnes = new Set(contenu.bonnesReponses || []);
  const corrections = {};
  let ok = selection.size === bonnes.size;
  for (const choix of contenu.choix) {
    const estBonne = bonnes.has(choix.id);
    const estChoisie = selection.has(choix.id);
    corrections[choix.id] = estBonne === estChoisie;
    if (estBonne !== estChoisie) ok = false;
  }
  return { score: ok ? 1 : 0, max: 1, corrections };
}

function corrigerTexteATrous(contenu, reponse) {
  const valeurs = reponse?.valeurs || {};
  const corrections = {};
  let score = 0;
  for (const trou of contenu.trous) {
    const saisie = normaliserTexte(valeurs[trou.id]);
    const accepte = (trou.reponsesAcceptees || []).some(r => normaliserTexte(r) === saisie);
    corrections[trou.id] = accepte;
    if (accepte) score += 1;
  }
  return { score, max: contenu.trous.length, corrections };
}

function corrigerAssociation(contenu, reponse) {
  const associations = reponse?.associations || {};
  const corrections = {};
  let score = 0;
  for (const paire of contenu.paires) {
    const correct = associations[paire.id] === paire.id;
    corrections[paire.id] = correct;
    if (correct) score += 1;
  }
  return { score, max: contenu.paires.length, corrections };
}

function corrigerVraiFaux(contenu, reponse) {
  const correct = !!reponse?.valeur === !!contenu.reponse;
  return { score: correct ? 1 : 0, max: 1, corrections: { unique: correct } };
}

// Fonction pure : ne fait aucun accès réseau/stockage. Utilisable en ligne comme hors-ligne.
export function corriger(contenu, reponse) {
  switch (contenu?.type) {
    case "qcm": return corrigerQcm(contenu, reponse);
    case "texte_a_trous": return corrigerTexteATrous(contenu, reponse);
    case "association": return corrigerAssociation(contenu, reponse);
    case "vrai_faux": return corrigerVraiFaux(contenu, reponse);
    default: throw new Error(`Type d'exercice inconnu : ${contenu?.type}`);
  }
}

export function melanger(tableau) {
  const copie = [...tableau];
  for (let i = copie.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copie[i], copie[j]] = [copie[j], copie[i]];
  }
  return copie;
}
