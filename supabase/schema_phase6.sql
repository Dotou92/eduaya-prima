-- =========================================================
-- EduAya Prima — Correction de la messagerie parent ↔ enseignant
--
-- Sans ces policies, un enseignant ne peut pas savoir quel parent est lié à
-- quel élève (ni voir son profil), donc impossible d'initier ou de bien
-- afficher une conversation. À exécuter après schema_phase5.sql.
-- =========================================================

-- L'enseignant peut voir les liens parent-enfant de ses propres élèves
-- (nécessaire pour savoir à qui écrire).
create policy "parent_enfant_lecture_enseignant" on parent_enfant for select
  using (is_teacher_of_eleve(enfant_id));

-- L'enseignant peut voir le profil (prénom) d'un parent lié à un de ses élèves.
create policy "profils_visibles_enseignant_parent" on profiles for select
  using (
    exists(
      select 1 from parent_enfant pe
      where pe.parent_id = profiles.id and is_teacher_of_eleve(pe.enfant_id)
    )
  );

-- Réciproquement, le parent peut voir le profil (prénom) de l'enseignant
-- de son enfant (purement cosmétique : afficher le vrai nom au lieu d'un
-- libellé générique).
create policy "profils_visibles_parent_enseignant" on profiles for select
  using (
    role = 'enseignant' and exists(
      select 1 from classes c
      join classe_eleves ce on ce.classe_id = c.id
      where c.enseignant_id = profiles.id and is_parent_of(ce.eleve_id)
    )
  );
