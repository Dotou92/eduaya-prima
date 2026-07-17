-- =========================================================
-- EduAya Prima — Numérique communal, absences, messagerie, ressources élargies
--
-- À EXÉCUTER APRÈS tous les fichiers précédents (schema.sql, seed.sql,
-- seed_contenu.sql, schema_communes.sql, schema_phase3.sql, schema_phase4.sql).
-- Coller dans le SQL Editor Supabase et cliquer "Run".
-- =========================================================

-- ---------------------------------------------------------
-- 1. Nouveau rôle : agent_numerique (Responsable communal du Numérique).
--    Rattaché à une commune comme agent_commune, mais avec un regard
--    "usage/technique" plutôt que pédagogique. On généralise les fonctions
--    RLS existantes plutôt que d'en dupliquer une deuxième version.
-- ---------------------------------------------------------

alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check
  check (role in ('ecolier', 'parent', 'enseignant', 'directeur', 'agent_commune', 'agent_numerique', 'super_admin', 'non_defini'));

create or replace function is_agent_of_commune(cid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from profiles
    where id = auth.uid() and role in ('agent_commune', 'agent_numerique') and commune_id = cid
  );
$$;
-- is_agent_of_eleve() appelle déjà is_agent_of_commune() en interne (voir schema_communes.sql) :
-- elle se généralise donc automatiquement, aucune modification nécessaire.

create or replace function empecher_changement_role()
returns trigger
language plpgsql
as $$
begin
  if new.role <> old.role then
    if old.role <> 'non_defini' then
      raise exception 'Le rôle d''un compte ne peut pas être modifié.';
    end if;
    if new.role not in ('enseignant', 'parent') then
      raise exception 'Transition de rôle non autorisée.';
    end if;
  end if;
  new.code_liaison_parent := old.code_liaison_parent;
  return new;
end;
$$;
-- (recréée à l'identique ici uniquement pour rester cohérente si ce fichier est
-- exécuté seul après une réinitialisation — pas de changement de comportement)

-- ---------------------------------------------------------
-- 2. Absences
-- ---------------------------------------------------------

create table if not exists absences (
  id uuid primary key default gen_random_uuid(),
  eleve_id uuid not null references profiles(id) on delete cascade,
  date_absence date not null default current_date,
  motif text,
  signale_par uuid references profiles(id),
  created_at timestamptz not null default now()
);

alter table absences enable row level security;
create policy "absences_enseignant_gestion" on absences for all
  using (is_teacher_of_eleve(eleve_id)) with check (is_teacher_of_eleve(eleve_id));
create policy "absences_eleve_lecture" on absences for select
  using (eleve_id = auth.uid());
create policy "absences_parent_lecture" on absences for select
  using (is_parent_of(eleve_id));
create policy "absences_directeur_lecture" on absences for select
  using (is_directeur_of_eleve(eleve_id));
create policy "absences_agent_lecture" on absences for select
  using (is_agent_of_eleve(eleve_id));

-- ---------------------------------------------------------
-- 3. Messagerie parent ↔ enseignant
-- ---------------------------------------------------------

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  expediteur_id uuid not null references profiles(id) on delete cascade,
  destinataire_id uuid not null references profiles(id) on delete cascade,
  eleve_id uuid references profiles(id),
  contenu text not null,
  lu boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_messages_destinataire on messages (destinataire_id);
create index if not exists idx_messages_expediteur on messages (expediteur_id);

alter table messages enable row level security;
create policy "messages_participants_lecture" on messages for select
  using (auth.uid() in (expediteur_id, destinataire_id));
create policy "messages_envoi" on messages for insert
  with check (expediteur_id = auth.uid());
create policy "messages_marquer_lu" on messages for update
  using (destinataire_id = auth.uid()) with check (destinataire_id = auth.uid());

-- ---------------------------------------------------------
-- 4. Ressources : classement par niveau / matière (en plus de source / catégorie)
-- ---------------------------------------------------------

alter table ressources add column if not exists niveau_id smallint references niveaux(id);
alter table ressources add column if not exists matiere_id smallint references matieres(id);

-- Le responsable communal du Numérique doit aussi pouvoir consulter la bibliothèque.
drop policy if exists "ressources_lecture" on ressources;
create policy "ressources_lecture" on ressources for select
  using (role_courant() in ('enseignant', 'directeur', 'agent_commune', 'agent_numerique', 'super_admin'));
