-- =========================================================
-- Plateforme Éducative Primaire — Bénin
-- Schéma Postgres complet + Row Level Security (Supabase)
--
-- COMMENT L'EXÉCUTER :
--   1. Ouvrir le projet sur https://supabase.com/dashboard
--   2. Aller dans "SQL Editor" > "New query"
--   3. Coller tout le contenu de ce fichier et cliquer "Run"
--   4. Faire de même ensuite avec supabase/seed.sql
--   5. Dans "Authentication > Providers > Email", désactiver
--      "Confirm email" (les comptes élèves n'ont pas de vraie
--      boîte mail et doivent pouvoir se connecter immédiatement).
--
-- NOTE DE SÉCURITÉ : cette plateforme n'a pas de serveur applicatif
-- (pas de backend Node/Next.js) : le navigateur parle directement à
-- Supabase. Le rôle d'un compte est donc déclaré par le client au
-- moment de l'inscription (via les métadonnées utilisateur), puis
-- verrouillé pour toujours par un trigger dès la création du profil
-- (voir empecher_changement_role ci-dessous). C'est un compromis
-- acceptable pour un outil pédagogique à faibles enjeux, mais il faut
-- savoir qu'un utilisateur malveillant pourrait en théorie s'inscrire
-- en se déclarant "enseignant". Si ce risque devient inacceptable,
-- il faudra ajouter un serveur (ex. Supabase Edge Functions) pour
-- valider les inscriptions enseignant.
-- =========================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------
-- Référentiels
-- ---------------------------------------------------------

create table if not exists niveaux (
  id smallint primary key,
  code text unique not null,      -- CI, CP, CE1, CE2, CM1, CM2
  nom text not null,
  ordre smallint not null
);

create table if not exists matieres (
  id smallint primary key,
  code text unique not null,      -- francais, mathematiques, eveil
  nom text not null,
  icone text
);

-- ---------------------------------------------------------
-- Identité
-- ---------------------------------------------------------

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('ecolier', 'parent', 'enseignant')),
  prenom text not null,
  nom text,
  niveau_id smallint references niveaux(id),         -- pertinent seulement pour role='ecolier'
  code_liaison_parent text unique,                    -- code à 6 caractères, pour role='ecolier'
  avatar_url text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Classes & liens parent-enfant
-- ---------------------------------------------------------

create table if not exists classes (
  id uuid primary key default gen_random_uuid(),
  enseignant_id uuid not null references profiles(id) on delete cascade,
  niveau_id smallint not null references niveaux(id),
  nom text not null,
  code_invitation text unique not null,
  annee_scolaire text not null,
  created_at timestamptz not null default now()
);

create table if not exists classe_eleves (
  classe_id uuid not null references classes(id) on delete cascade,
  eleve_id uuid not null references profiles(id) on delete cascade,
  date_ajout timestamptz not null default now(),
  primary key (classe_id, eleve_id)
);

create table if not exists parent_enfant (
  parent_id uuid not null references profiles(id) on delete cascade,
  enfant_id uuid not null references profiles(id) on delete cascade,
  statut text not null default 'confirme',
  created_at timestamptz not null default now(),
  primary key (parent_id, enfant_id)
);

-- ---------------------------------------------------------
-- Contenu pédagogique
-- ---------------------------------------------------------

create table if not exists lecons (
  id uuid primary key default gen_random_uuid(),
  titre text not null,
  contenu jsonb not null default '{}'::jsonb,
  niveau_id smallint not null references niveaux(id),
  matiere_id smallint not null references matieres(id),
  auteur_id uuid references profiles(id),
  classe_id uuid references classes(id),              -- null = bibliothèque partagée
  statut text not null default 'publie' check (statut in ('brouillon', 'publie')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists exercices (
  id uuid primary key default gen_random_uuid(),
  lecon_id uuid references lecons(id) on delete cascade,
  titre text not null,
  type text not null check (type in ('qcm', 'texte_a_trous', 'association', 'vrai_faux')),
  contenu jsonb not null,
  niveau_id smallint not null references niveaux(id),
  matiere_id smallint not null references matieres(id),
  auteur_id uuid references profiles(id),
  classe_id uuid references classes(id),
  points numeric not null default 1,
  ordre smallint not null default 0,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Devoirs, tentatives, progrès, badges
-- ---------------------------------------------------------

create table if not exists devoirs (
  id uuid primary key default gen_random_uuid(),
  enseignant_id uuid not null references profiles(id),
  classe_id uuid not null references classes(id) on delete cascade,
  titre text not null,
  description text,
  date_limite timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists devoir_exercices (
  devoir_id uuid not null references devoirs(id) on delete cascade,
  exercice_id uuid not null references exercices(id) on delete cascade,
  ordre smallint not null default 0,
  primary key (devoir_id, exercice_id)
);

create table if not exists tentatives (
  id uuid primary key default gen_random_uuid(),
  client_uuid uuid not null unique,                    -- généré côté client, garantit l'idempotence hors-ligne
  eleve_id uuid not null references profiles(id) on delete cascade,
  exercice_id uuid not null references exercices(id) on delete cascade,
  devoir_id uuid references devoirs(id),
  reponses jsonb not null,
  score numeric not null,
  score_max numeric not null,
  temps_passe_secondes integer,
  date_debut timestamptz,
  date_fin timestamptz not null default now(),
  source text not null default 'en_ligne' check (source in ('en_ligne', 'sync_hors_ligne'))
);
create index if not exists idx_tentatives_eleve on tentatives (eleve_id);
create index if not exists idx_tentatives_exercice on tentatives (exercice_id);

create table if not exists progres_lecons (
  eleve_id uuid not null references profiles(id) on delete cascade,
  lecon_id uuid not null references lecons(id) on delete cascade,
  statut text not null default 'non_commence' check (statut in ('non_commence', 'en_cours', 'termine')),
  date_completion timestamptz,
  primary key (eleve_id, lecon_id)
);

create table if not exists badges (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  nom text not null,
  description text,
  icone text,
  critere jsonb not null default '{}'::jsonb
);

create table if not exists eleve_badges (
  eleve_id uuid not null references profiles(id) on delete cascade,
  badge_id uuid not null references badges(id) on delete cascade,
  date_obtention timestamptz not null default now(),
  primary key (eleve_id, badge_id)
);

-- =========================================================
-- Fonctions utilitaires
-- =========================================================

create or replace function generer_code(longueur int default 6)
returns text
language plpgsql
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- sans 0/O/1/I pour éviter les confusions
  resultat text := '';
  i int;
begin
  for i in 1..longueur loop
    resultat := resultat || substr(alphabet, floor(random() * length(alphabet) + 1)::int, 1);
  end loop;
  return resultat;
end;
$$;

create or replace function role_courant()
returns text
language sql stable security definer set search_path = public
as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function is_teacher_of_classe(cid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(select 1 from classes where id = cid and enseignant_id = auth.uid());
$$;

create or replace function is_parent_of(child uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from parent_enfant
    where parent_id = auth.uid() and enfant_id = child and statut = 'confirme'
  );
$$;

create or replace function is_teacher_of_eleve(v_eleve_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from classe_eleves ce
    join classes c on c.id = ce.classe_id
    where ce.eleve_id = v_eleve_id and c.enseignant_id = auth.uid()
  );
$$;

-- =========================================================
-- Triggers
-- =========================================================

-- Crée automatiquement le profil applicatif à la création d'un compte Supabase Auth.
-- Le rôle et le prénom viennent des métadonnées passées à supabase.auth.signUp({ options: { data } }).
create or replace function handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_role text := coalesce(new.raw_user_meta_data->>'role', 'parent');
  v_code text;
begin
  if v_role = 'ecolier' then
    loop
      v_code := generer_code(6);
      exit when not exists (select 1 from profiles where code_liaison_parent = v_code);
    end loop;
  end if;

  insert into profiles (id, role, prenom, nom, niveau_id, code_liaison_parent)
  values (
    new.id,
    v_role,
    coalesce(new.raw_user_meta_data->>'prenom', 'Élève'),
    new.raw_user_meta_data->>'nom',
    nullif(new.raw_user_meta_data->>'niveau_id', '')::smallint,
    v_code
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Empêche toute modification du rôle ou du code de liaison après création du profil.
create or replace function empecher_changement_role()
returns trigger
language plpgsql
as $$
begin
  if new.role <> old.role then
    raise exception 'Le rôle d''un compte ne peut pas être modifié.';
  end if;
  new.code_liaison_parent := old.code_liaison_parent;
  return new;
end;
$$;

drop trigger if exists trg_profiles_empecher_changement_role on profiles;
create trigger trg_profiles_empecher_changement_role
  before update on profiles
  for each row execute function empecher_changement_role();

-- Génère un code d'invitation unique pour chaque nouvelle classe.
create or replace function generer_code_invitation()
returns trigger
language plpgsql
as $$
begin
  if new.code_invitation is null then
    loop
      new.code_invitation := generer_code(6);
      exit when not exists (select 1 from classes where code_invitation = new.code_invitation);
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_classes_code_invitation on classes;
create trigger trg_classes_code_invitation
  before insert on classes
  for each row execute function generer_code_invitation();

-- Dérive automatiquement la progression d'une leçon à chaque tentative d'exercice.
-- C'est la SEULE façon dont `progres_lecons` est écrite : jamais directement par le
-- client, ce qui élimine tout conflit d'écriture en cas de synchronisation hors-ligne.
create or replace function maj_progres_lecon()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_lecon_id uuid;
  v_total_exercices int;
  v_faits int;
begin
  select lecon_id into v_lecon_id from exercices where id = new.exercice_id;
  if v_lecon_id is null then
    return new;
  end if;

  select count(*) into v_total_exercices from exercices where lecon_id = v_lecon_id;
  select count(distinct t.exercice_id) into v_faits
    from tentatives t
    join exercices e on e.id = t.exercice_id
    where t.eleve_id = new.eleve_id and e.lecon_id = v_lecon_id;

  insert into progres_lecons (eleve_id, lecon_id, statut, date_completion)
  values (
    new.eleve_id,
    v_lecon_id,
    case when v_total_exercices > 0 and v_faits >= v_total_exercices then 'termine' else 'en_cours' end,
    case when v_total_exercices > 0 and v_faits >= v_total_exercices then now() else null end
  )
  on conflict (eleve_id, lecon_id) do update
    set statut = excluded.statut,
        date_completion = coalesce(progres_lecons.date_completion, excluded.date_completion);
  return new;
end;
$$;

drop trigger if exists trg_tentatives_progres on tentatives;
create trigger trg_tentatives_progres
  after insert on tentatives
  for each row execute function maj_progres_lecon();

-- =========================================================
-- Fonction pour lier un parent à un enfant via son code
-- (évite d'avoir à exposer une policy de lecture large sur `profiles`)
-- =========================================================

create or replace function lier_enfant(p_code text)
returns table(id uuid, prenom text, niveau_id smallint)
language plpgsql security definer set search_path = public
as $$
declare
  v_enfant profiles%rowtype;
begin
  if role_courant() <> 'parent' then
    raise exception 'Seul un compte parent peut lier un enfant.';
  end if;

  select * into v_enfant from profiles p
    where p.code_liaison_parent = upper(trim(p_code)) and p.role = 'ecolier';
  if not found then
    raise exception 'Code invalide. Vérifiez auprès de l''enseignant ou de l''enfant.';
  end if;

  insert into parent_enfant (parent_id, enfant_id, statut)
  values (auth.uid(), v_enfant.id, 'confirme')
  on conflict (parent_id, enfant_id) do nothing;

  return query select v_enfant.id, v_enfant.prenom, v_enfant.niveau_id;
end;
$$;

grant execute on function lier_enfant(text) to authenticated;

-- =========================================================
-- Row Level Security
-- =========================================================

alter table niveaux enable row level security;
create policy "niveaux_lecture" on niveaux for select using (true);

alter table matieres enable row level security;
create policy "matieres_lecture" on matieres for select using (true);

alter table profiles enable row level security;
create policy "profils_visibles" on profiles for select
  using (
    id = auth.uid()
    or is_parent_of(id)
    or is_teacher_of_eleve(id)
  );
create policy "profil_maj_soi" on profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

alter table classes enable row level security;
create policy "enseignant_gere_ses_classes" on classes for all
  using (enseignant_id = auth.uid()) with check (enseignant_id = auth.uid());
create policy "eleve_voit_sa_classe" on classes for select
  using (exists(select 1 from classe_eleves ce where ce.classe_id = classes.id and ce.eleve_id = auth.uid()));
create policy "parent_voit_classe_enfant" on classes for select
  using (exists(select 1 from classe_eleves ce where ce.classe_id = classes.id and is_parent_of(ce.eleve_id)));

alter table classe_eleves enable row level security;
create policy "enseignant_gere_classe_eleves" on classe_eleves for all
  using (is_teacher_of_classe(classe_id)) with check (is_teacher_of_classe(classe_id));
create policy "eleve_voit_son_inscription" on classe_eleves for select
  using (eleve_id = auth.uid());
create policy "parent_voit_inscription_enfant" on classe_eleves for select
  using (is_parent_of(eleve_id));

alter table parent_enfant enable row level security;
create policy "parent_voit_ses_liens" on parent_enfant for select using (parent_id = auth.uid());
create policy "enfant_voit_ses_parents" on parent_enfant for select using (enfant_id = auth.uid());
-- Pas de policy d'insertion directe : la liaison passe uniquement par lier_enfant() (SECURITY DEFINER).

alter table lecons enable row level security;
create policy "lecons_lecture" on lecons for select
  using (
    (statut = 'publie' and classe_id is null)
    or auteur_id = auth.uid()
    or (classe_id is not null and (
      is_teacher_of_classe(classe_id)
      or exists(select 1 from classe_eleves ce where ce.classe_id = lecons.classe_id and ce.eleve_id = auth.uid())
      or exists(select 1 from classe_eleves ce where ce.classe_id = lecons.classe_id and is_parent_of(ce.eleve_id))
    ))
  );
create policy "lecons_creation_enseignant" on lecons for insert
  with check (role_courant() = 'enseignant' and auteur_id = auth.uid());
create policy "lecons_maj_enseignant" on lecons for update
  using (auteur_id = auth.uid()) with check (auteur_id = auth.uid());
create policy "lecons_suppr_enseignant" on lecons for delete
  using (auteur_id = auth.uid());

alter table exercices enable row level security;
create policy "exercices_lecture" on exercices for select
  using (
    classe_id is null
    or auteur_id = auth.uid()
    or is_teacher_of_classe(classe_id)
    or exists(select 1 from classe_eleves ce where ce.classe_id = exercices.classe_id and ce.eleve_id = auth.uid())
  );
create policy "exercices_creation_enseignant" on exercices for insert
  with check (role_courant() = 'enseignant' and auteur_id = auth.uid());
create policy "exercices_maj_enseignant" on exercices for update
  using (auteur_id = auth.uid()) with check (auteur_id = auth.uid());
create policy "exercices_suppr_enseignant" on exercices for delete
  using (auteur_id = auth.uid());

alter table devoirs enable row level security;
create policy "devoirs_enseignant" on devoirs for all
  using (enseignant_id = auth.uid()) with check (enseignant_id = auth.uid());
create policy "devoirs_eleve_lecture" on devoirs for select
  using (exists(select 1 from classe_eleves ce where ce.classe_id = devoirs.classe_id and ce.eleve_id = auth.uid()));
create policy "devoirs_parent_lecture" on devoirs for select
  using (exists(select 1 from classe_eleves ce where ce.classe_id = devoirs.classe_id and is_parent_of(ce.eleve_id)));

alter table devoir_exercices enable row level security;
create policy "devoir_exercices_enseignant" on devoir_exercices for all
  using (exists(select 1 from devoirs d where d.id = devoir_id and d.enseignant_id = auth.uid()))
  with check (exists(select 1 from devoirs d where d.id = devoir_id and d.enseignant_id = auth.uid()));
create policy "devoir_exercices_eleve_lecture" on devoir_exercices for select
  using (exists(
    select 1 from devoirs d
    join classe_eleves ce on ce.classe_id = d.classe_id
    where d.id = devoir_exercices.devoir_id and ce.eleve_id = auth.uid()
  ));

alter table tentatives enable row level security;
create policy "tentatives_eleve_lecture" on tentatives for select using (eleve_id = auth.uid());
create policy "tentatives_eleve_insertion" on tentatives for insert with check (eleve_id = auth.uid());
create policy "tentatives_enseignant_lecture" on tentatives for select using (is_teacher_of_eleve(eleve_id));
create policy "tentatives_parent_lecture" on tentatives for select using (is_parent_of(eleve_id));

alter table progres_lecons enable row level security;
create policy "progres_eleve_lecture" on progres_lecons for select using (eleve_id = auth.uid());
create policy "progres_enseignant_lecture" on progres_lecons for select using (is_teacher_of_eleve(eleve_id));
create policy "progres_parent_lecture" on progres_lecons for select using (is_parent_of(eleve_id));
-- Pas de policy d'écriture : seul le trigger maj_progres_lecon() (SECURITY DEFINER) écrit cette table.

alter table badges enable row level security;
create policy "badges_lecture_publique" on badges for select using (true);

alter table eleve_badges enable row level security;
create policy "eleve_badges_eleve_lecture" on eleve_badges for select using (eleve_id = auth.uid());
create policy "eleve_badges_eleve_insertion" on eleve_badges for insert with check (eleve_id = auth.uid());
create policy "eleve_badges_parent_lecture" on eleve_badges for select using (is_parent_of(eleve_id));
create policy "eleve_badges_enseignant_lecture" on eleve_badges for select using (is_teacher_of_eleve(eleve_id));
