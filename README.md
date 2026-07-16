# EduAya Prima — Plateforme éducative du primaire

Site statique (HTML/CSS/JS, aucune installation locale requise) pour écoliers, parents et
enseignants, avec Supabase comme backend et un fonctionnement hors-ligne (PWA).

## 1. Configurer Supabase

1. Créez un projet sur [supabase.com](https://supabase.com).
2. Dans **SQL Editor**, exécutez dans l'ordre :
   1. `supabase/schema.sql` (tables, sécurité, fonctions)
   2. `supabase/seed.sql` (niveaux, matières, badges)
   3. `supabase/seed_contenu.sql` (leçons et exercices d'exemple — à adapter/valider par un enseignant)
3. Dans **Authentication > Providers > Email**, désactivez **"Confirm email"** — les comptes
   élèves utilisent une adresse e-mail interne fictive et doivent pouvoir se connecter
   immédiatement après leur création par l'enseignant.
4. Dans **Project Settings > API**, copiez l'**URL du projet** et la **clé anon publique**.
5. Ouvrez `js/config.js` et remplacez les deux valeurs par les vôtres.

## 2. Lancer le site en local

Le site est 100% statique, mais les modules JavaScript (`import`) nécessitent d'être servis
via `http://`, pas ouverts directement en double-cliquant sur le fichier. Utilisez n'importe
quel serveur statique, par exemple :

- L'extension **Live Server** de VS Code (clic droit sur `index.html` > "Open with Live Server")
- Ou, si Python est installé : `python -m http.server 8080` puis ouvrez `http://localhost:8080`

## 3. Déployer

N'importe quel hébergeur de fichiers statiques convient (Vercel, Netlify, GitHub Pages, etc.) :
il suffit de publier le contenu de ce dossier tel quel, sans étape de build.

## Limites connues (MVP)

- **Rôle déclaré côté client** : sans serveur applicatif, le rôle (élève/parent/enseignant)
  est fixé au moment de l'inscription par la personne qui s'inscrit, puis verrouillé pour
  toujours. Un utilisateur malveillant pourrait en théorie s'inscrire en se déclarant
  "enseignant". Acceptable pour un outil pédagogique à faibles enjeux ; à durcir avec un
  serveur (ex. Supabase Edge Functions) si les enjeux augmentent.
- **Score auto-corrigé côté client** : les résultats sont calculés dans le navigateur (pour
  permettre la correction hors-ligne) puis stockés tels quels, sans revalidation serveur.
- **Contenu pédagogique d'exemple** : les leçons de `seed_contenu.sql` sont des placeholders
  pour démontrer la structure — à faire relire par un enseignant avant usage réel.
