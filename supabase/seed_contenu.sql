-- Contenu pédagogique de démonstration — une leçon + deux exercices par niveau et par matière.
-- IMPORTANT : ce contenu est un EXEMPLE pour valider la structure de la plateforme.
-- Il doit être relu et validé par un personnel enseignant qualifié, conformément au
-- programme officiel béninois, avant tout usage réel en classe.
-- À exécuter après schema.sql et seed.sql dans le SQL Editor Supabase.

-- ================= CI — Cours d'Initiation (niveau_id = 1) =================

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les voyelles a, e, i, o, u',
    '{"blocs":[{"texte":"Les voyelles sont des lettres que l''on peut chanter toutes seules : a, e, i, o, u."},{"texte":"Répète chaque voyelle à voix haute plusieurs fois."}]}'::jsonb,
    1, 1, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Reconnaître les voyelles', 'qcm',
  '{"type":"qcm","question":"Quelle lettre parmi celles-ci est une voyelle ?","choix":[{"id":"c1","texte":"a"},{"id":"c2","texte":"b"},{"id":"c3","texte":"c"}],"bonnesReponses":["c1"],"multiple":false}'::jsonb,
  1, 1, 1 from l
union all
select id, 'Compléter le mot', 'texte_a_trous',
  '{"type":"texte_a_trous","texte":"Le mot ''{{1}}'' commence par une voyelle : a-m-i.","trous":[{"id":"1","reponsesAcceptees":["ami"]}]}'::jsonb,
  1, 1, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Compter jusqu''à 10',
    '{"blocs":[{"texte":"On compte : 1, 2, 3, 4, 5, 6, 7, 8, 9, 10."},{"texte":"Compte tes doigts pour t''aider !"}]}'::jsonb,
    1, 2, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Le nombre après', 'qcm',
  '{"type":"qcm","question":"Quel nombre vient juste après 6 ?","choix":[{"id":"c1","texte":"5"},{"id":"c2","texte":"7"},{"id":"c3","texte":"8"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  1, 2, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"10 est plus grand que 3.","reponse":true}'::jsonb,
  1, 2, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les parties du corps',
    '{"blocs":[{"texte":"Mon corps a une tête, deux bras, deux mains, deux jambes et deux pieds."},{"texte":"Touche ta tête, puis tes pieds !"}]}'::jsonb,
    1, 3, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Associer les parties du corps', 'association',
  '{"type":"association","paires":[{"id":"p1","gauche":"On voit avec…","droite":"les yeux"},{"id":"p2","gauche":"On entend avec…","droite":"les oreilles"},{"id":"p3","gauche":"On marche avec…","droite":"les pieds"}]}'::jsonb,
  1, 3, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"On a deux mains.","reponse":true}'::jsonb,
  1, 3, 2 from l;

-- ================= CP — Cours Préparatoire (niveau_id = 2) =================

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Le son "ch"',
    '{"blocs":[{"texte":"Le son ch s''écrit avec les lettres c et h ensemble."},{"texte":"Exemples : chat, cheval, chapeau."}]}'::jsonb,
    2, 1, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Trouver le son ch', 'qcm',
  '{"type":"qcm","question":"Quel mot contient le son ch ?","choix":[{"id":"c1","texte":"chat"},{"id":"c2","texte":"lune"},{"id":"c3","texte":"table"}],"bonnesReponses":["c1"],"multiple":false}'::jsonb,
  2, 1, 1 from l
union all
select id, 'Compléter la phrase', 'texte_a_trous',
  '{"type":"texte_a_trous","texte":"Le {{1}} dort sur le tapis (indice : miaule).","trous":[{"id":"1","reponsesAcceptees":["chat"]}]}'::jsonb,
  2, 1, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('L''addition jusqu''à 20',
    '{"blocs":[{"texte":"Additionner, c''est mettre ensemble deux quantités pour en trouver le total."},{"texte":"Exemple : 7 + 5 = 12."}]}'::jsonb,
    2, 2, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Calculer une addition', 'qcm',
  '{"type":"qcm","question":"Combien font 8 + 6 ?","choix":[{"id":"c1","texte":"12"},{"id":"c2","texte":"14"},{"id":"c3","texte":"16"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  2, 2, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"9 + 9 = 18","reponse":true}'::jsonb,
  2, 2, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les animaux domestiques',
    '{"blocs":[{"texte":"Un animal domestique vit avec les humains : le chien, le chat, la poule, la chèvre."},{"texte":"Ils ont besoin de nourriture, d''eau et de soins."}]}'::jsonb,
    2, 3, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Associer l''animal à son cri', 'association',
  '{"type":"association","paires":[{"id":"p1","gauche":"Le chien","droite":"aboie"},{"id":"p2","gauche":"Le chat","droite":"miaule"},{"id":"p3","gauche":"La poule","droite":"caquette"}]}'::jsonb,
  2, 3, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"Le chat est un animal domestique.","reponse":true}'::jsonb,
  2, 3, 2 from l;

-- ================= CE1 — Cours Élémentaire 1 (niveau_id = 3) =================

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Noms communs et noms propres',
    '{"blocs":[{"texte":"Un nom commun désigne une chose générale : chien, ville, école."},{"texte":"Un nom propre désigne quelque chose de précis et prend une majuscule : Rex, Cotonou, Bénin."}]}'::jsonb,
    3, 1, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Nom propre ou nom commun ?', 'qcm',
  '{"type":"qcm","question":"Lequel de ces mots est un nom propre ?","choix":[{"id":"c1","texte":"ville"},{"id":"c2","texte":"Bénin"},{"id":"c3","texte":"maison"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  3, 1, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"Les noms propres commencent toujours par une majuscule.","reponse":true}'::jsonb,
  3, 1, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('La table de multiplication par 2',
    '{"blocs":[{"texte":"Multiplier par 2, c''est ajouter un nombre à lui-même."},{"texte":"Exemple : 4 × 2 = 8, car 4 + 4 = 8."}]}'::jsonb,
    3, 2, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Calculer une multiplication', 'qcm',
  '{"type":"qcm","question":"Combien font 6 × 2 ?","choix":[{"id":"c1","texte":"10"},{"id":"c2","texte":"12"},{"id":"c3","texte":"14"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  3, 2, 1 from l
union all
select id, 'Compléter', 'texte_a_trous',
  '{"type":"texte_a_trous","texte":"9 × 2 = {{1}}","trous":[{"id":"1","reponsesAcceptees":["18"]}]}'::jsonb,
  3, 2, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Le cycle de l''eau',
    '{"blocs":[{"texte":"L''eau s''évapore, forme des nuages, puis retombe en pluie. C''est le cycle de l''eau."}]}'::jsonb,
    3, 3, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Les étapes du cycle', 'association',
  '{"type":"association","paires":[{"id":"p1","gauche":"L''eau chauffée devient…","droite":"vapeur"},{"id":"p2","gauche":"La vapeur forme…","droite":"des nuages"},{"id":"p3","gauche":"Les nuages libèrent…","droite":"la pluie"}]}'::jsonb,
  3, 3, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"La pluie vient des nuages.","reponse":true}'::jsonb,
  3, 3, 2 from l;

-- ================= CE2 — Cours Élémentaire 2 (niveau_id = 4) =================

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les synonymes',
    '{"blocs":[{"texte":"Deux mots sont synonymes quand ils ont un sens proche."},{"texte":"Exemple : content et heureux."}]}'::jsonb,
    4, 1, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Trouver le synonyme', 'qcm',
  '{"type":"qcm","question":"Quel est le synonyme de \"content\" ?","choix":[{"id":"c1","texte":"triste"},{"id":"c2","texte":"heureux"},{"id":"c3","texte":"fatigué"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  4, 1, 1 from l
union all
select id, 'Associer les synonymes', 'association',
  '{"type":"association","paires":[{"id":"p1","gauche":"grand","droite":"immense"},{"id":"p2","gauche":"rapide","droite":"vite"},{"id":"p3","gauche":"joli","droite":"beau"}]}'::jsonb,
  4, 1, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('La division simple',
    '{"blocs":[{"texte":"Diviser, c''est partager en parts égales."},{"texte":"Exemple : 12 divisé par 3 = 4, car 4 + 4 + 4 = 12."}]}'::jsonb,
    4, 2, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Calculer une division', 'qcm',
  '{"type":"qcm","question":"Combien font 20 ÷ 4 ?","choix":[{"id":"c1","texte":"4"},{"id":"c2","texte":"5"},{"id":"c3","texte":"6"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  4, 2, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"15 ÷ 3 = 5","reponse":true}'::jsonb,
  4, 2, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les plantes et leurs besoins',
    '{"blocs":[{"texte":"Une plante a besoin d''eau, de lumière et de terre pour grandir."}]}'::jsonb,
    4, 3, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Les besoins de la plante', 'qcm',
  '{"type":"qcm","question":"De quoi une plante a-t-elle besoin pour grandir ?","choix":[{"id":"c1","texte":"D''eau et de lumière"},{"id":"c2","texte":"De sable uniquement"},{"id":"c3","texte":"De rien"}],"bonnesReponses":["c1"],"multiple":false}'::jsonb,
  4, 3, 1 from l
union all
select id, 'Compléter', 'texte_a_trous',
  '{"type":"texte_a_trous","texte":"La plante pousse grâce à la {{1}} du soleil.","trous":[{"id":"1","reponsesAcceptees":["lumiere","lumière"]}]}'::jsonb,
  4, 3, 2 from l;

-- ================= CM1 — Cours Moyen 1 (niveau_id = 5) =================

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les temps du verbe : présent, passé, futur',
    '{"blocs":[{"texte":"Le présent décrit une action qui se passe maintenant : je mange."},{"texte":"Le passé décrit une action déjà terminée : j''ai mangé."},{"texte":"Le futur décrit une action à venir : je mangerai."}]}'::jsonb,
    5, 1, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Identifier le temps', 'qcm',
  '{"type":"qcm","question":"\"Il jouera demain\" est au…","choix":[{"id":"c1","texte":"présent"},{"id":"c2","texte":"passé"},{"id":"c3","texte":"futur"}],"bonnesReponses":["c3"],"multiple":false}'::jsonb,
  5, 1, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"\"J''ai mangé\" est au passé.","reponse":true}'::jsonb,
  5, 1, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les fractions simples',
    '{"blocs":[{"texte":"Une fraction représente une partie d''un tout. 1/2 signifie une part sur deux parts égales."}]}'::jsonb,
    5, 2, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Comprendre les fractions', 'qcm',
  '{"type":"qcm","question":"Si je partage un pain en 4 parts égales, chaque part vaut…","choix":[{"id":"c1","texte":"1/2"},{"id":"c2","texte":"1/4"},{"id":"c3","texte":"1/3"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  5, 2, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"1/2 est plus grand que 1/4.","reponse":true}'::jsonb,
  5, 2, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Les régions du Bénin',
    '{"blocs":[{"texte":"Le Bénin est découpé en départements, comme le Littoral, l''Atlantique, le Borgou et l''Atacora."}]}'::jsonb,
    5, 3, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Reconnaître un département', 'qcm',
  '{"type":"qcm","question":"Lequel de ces noms est un département du Bénin ?","choix":[{"id":"c1","texte":"Littoral"},{"id":"c2","texte":"Paris"},{"id":"c3","texte":"Sahara"}],"bonnesReponses":["c1"],"multiple":false}'::jsonb,
  5, 3, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"Cotonou se trouve au Bénin.","reponse":true}'::jsonb,
  5, 3, 2 from l;

-- ================= CM2 — Cours Moyen 2 (niveau_id = 6) =================

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('L''accord sujet-verbe',
    '{"blocs":[{"texte":"Le verbe s''accorde toujours avec son sujet."},{"texte":"Exemple : Les enfants jouent (pluriel), l''enfant joue (singulier)."}]}'::jsonb,
    6, 1, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Accorder le verbe', 'texte_a_trous',
  '{"type":"texte_a_trous","texte":"Les élèves {{1}} bien en classe (verbe travailler).","trous":[{"id":"1","reponsesAcceptees":["travaillent"]}]}'::jsonb,
  6, 1, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"Le verbe s''accorde avec son sujet.","reponse":true}'::jsonb,
  6, 1, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Le calcul du périmètre',
    '{"blocs":[{"texte":"Le périmètre d''un rectangle se calcule ainsi : (longueur + largeur) × 2."}]}'::jsonb,
    6, 2, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Calculer un périmètre', 'qcm',
  '{"type":"qcm","question":"Quel est le périmètre d''un rectangle de 5 m de long et 3 m de large ?","choix":[{"id":"c1","texte":"8 m"},{"id":"c2","texte":"16 m"},{"id":"c3","texte":"15 m"}],"bonnesReponses":["c2"],"multiple":false}'::jsonb,
  6, 2, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"Le périmètre d''un carré de 4 m de côté est 16 m.","reponse":true}'::jsonb,
  6, 2, 2 from l;

with l as (
  insert into lecons (titre, contenu, niveau_id, matiere_id, statut)
  values ('Le corps humain : les organes',
    '{"blocs":[{"texte":"Le cœur fait circuler le sang, les poumons permettent de respirer, l''estomac digère les aliments."}]}'::jsonb,
    6, 3, 'publie')
  returning id
)
insert into exercices (lecon_id, titre, type, contenu, niveau_id, matiere_id, ordre)
select id, 'Associer l''organe à sa fonction', 'association',
  '{"type":"association","paires":[{"id":"p1","gauche":"Le cœur","droite":"fait circuler le sang"},{"id":"p2","gauche":"Les poumons","droite":"permettent de respirer"},{"id":"p3","gauche":"L''estomac","droite":"digère les aliments"}]}'::jsonb,
  6, 3, 1 from l
union all
select id, 'Vrai ou faux', 'vrai_faux',
  '{"type":"vrai_faux","affirmation":"Les poumons servent à respirer.","reponse":true}'::jsonb,
  6, 3, 2 from l;
