-- Données de référence — à exécuter une fois après schema.sql dans le SQL Editor Supabase.

insert into niveaux (id, code, nom, ordre) values
  (1, 'CI', 'Cours d''Initiation', 1),
  (2, 'CP', 'Cours Préparatoire', 2),
  (3, 'CE1', 'Cours Élémentaire 1', 3),
  (4, 'CE2', 'Cours Élémentaire 2', 4),
  (5, 'CM1', 'Cours Moyen 1', 5),
  (6, 'CM2', 'Cours Moyen 2', 6)
on conflict (id) do nothing;

insert into matieres (id, code, nom, icone) values
  (1, 'francais', 'Français', '📖'),
  (2, 'mathematiques', 'Mathématiques', '🔢'),
  (3, 'eveil', 'Éveil / Sciences d''observation', '🔎')
on conflict (id) do nothing;

insert into badges (code, nom, description, icone, critere) values
  ('premier_pas', 'Premier pas', 'Terminer son tout premier exercice', '🌱', '{"type":"nb_tentatives","valeur":1}'),
  ('serie_de_5', 'Série de 5', 'Terminer 5 exercices', '🔥', '{"type":"nb_tentatives","valeur":5}'),
  ('serie_de_20', 'Série de 20', 'Terminer 20 exercices', '⭐', '{"type":"nb_tentatives","valeur":20}'),
  ('sans_faute', 'Sans faute', 'Obtenir un score parfait sur un exercice', '💯', '{"type":"score_parfait"}'),
  ('premiere_lecon', 'Leçon terminée', 'Terminer sa première leçon complète', '📘', '{"type":"lecon_terminee","valeur":1}')
on conflict (code) do nothing;
