-- =========================================================
-- EduAya Prima — Phase institutionnelle
-- Communes, écoles, rôles Directeur/Agent communal, Ressources UNESCO.
--
-- À EXÉCUTER APRÈS schema.sql, seed.sql et seed_contenu.sql (jamais avant,
-- jamais à la place). Coller tout le contenu dans le SQL Editor Supabase
-- et cliquer "Run".
-- =========================================================

-- ---------------------------------------------------------
-- Référentiels institutionnels
-- ---------------------------------------------------------

create table if not exists communes (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  departement text,
  created_at timestamptz not null default now()
);

create table if not exists ecoles (
  id uuid primary key default gen_random_uuid(),
  commune_id uuid not null references communes(id) on delete cascade,
  nom text not null,
  created_at timestamptz not null default now()
);

alter table classes add column if not exists ecole_id uuid references ecoles(id);
-- Nullable : les classes existantes (démo) restent non rattachées ; l'enseignant
-- choisit désormais son école dans le formulaire de création de classe.

alter table profiles add column if not exists ecole_id uuid references ecoles(id);     -- pour role='directeur'
alter table profiles add column if not exists commune_id uuid references communes(id); -- pour role='agent_commune'

alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check
  check (role in ('ecolier', 'parent', 'enseignant', 'directeur', 'agent_commune', 'super_admin'));

-- ---------------------------------------------------------
-- Ressources UNESCO / partenaires
-- ---------------------------------------------------------

create table if not exists ressources (
  id uuid primary key default gen_random_uuid(),
  titre text not null,
  description text,
  source text not null,       -- 'UNESCO' | 'UNICEF' | 'Ministere' | 'Partenaire'
  categorie text,              -- 'guide' | 'rapport' | 'recherche' | 'recommandation' | 'formation'
  lien_url text not null,
  publie_par uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- handle_new_user() étendu : reprend la version de schema.sql et lit
-- en plus ecole_id/commune_id depuis les métadonnées d'inscription,
-- pour les comptes directeur/agent_commune provisionnés par le super-admin.
-- ---------------------------------------------------------

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

  insert into profiles (id, role, prenom, nom, niveau_id, code_liaison_parent, ecole_id, commune_id)
  values (
    new.id,
    v_role,
    coalesce(new.raw_user_meta_data->>'prenom', 'Utilisateur'),
    new.raw_user_meta_data->>'nom',
    nullif(new.raw_user_meta_data->>'niveau_id', '')::smallint,
    v_code,
    nullif(new.raw_user_meta_data->>'ecole_id', '')::uuid,
    nullif(new.raw_user_meta_data->>'commune_id', '')::uuid
  );
  return new;
end;
$$;
-- Le trigger on_auth_user_created (défini dans schema.sql) pointe déjà vers
-- cette fonction par son nom : le CREATE OR REPLACE ci-dessus suffit à mettre
-- à jour son comportement, pas besoin de recréer le trigger.

-- ---------------------------------------------------------
-- Fonctions RLS supplémentaires (même pattern SECURITY DEFINER que schema.sql)
-- ---------------------------------------------------------

create or replace function is_directeur_of_ecole(eid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from profiles where id = auth.uid() and role = 'directeur' and ecole_id = eid
  );
$$;

create or replace function is_agent_of_commune(cid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from profiles where id = auth.uid() and role = 'agent_commune' and commune_id = cid
  );
$$;

create or replace function is_directeur_of_eleve(v_eleve_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from classe_eleves ce
    join classes c on c.id = ce.classe_id
    where ce.eleve_id = v_eleve_id and is_directeur_of_ecole(c.ecole_id)
  );
$$;

create or replace function is_agent_of_eleve(v_eleve_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from classe_eleves ce
    join classes c on c.id = ce.classe_id
    join ecoles e on e.id = c.ecole_id
    where ce.eleve_id = v_eleve_id and is_agent_of_commune(e.commune_id)
  );
$$;

-- ---------------------------------------------------------
-- Fonctions de provisionnement (super-admin uniquement)
-- ---------------------------------------------------------

create or replace function creer_commune(p_nom text, p_departement text default null)
returns communes
language plpgsql security definer set search_path = public
as $$
declare
  v_commune communes%rowtype;
begin
  if role_courant() <> 'super_admin' then
    raise exception 'Seul un super-administrateur peut créer une commune.';
  end if;
  insert into communes (nom, departement) values (p_nom, p_departement) returning * into v_commune;
  return v_commune;
end;
$$;
grant execute on function creer_commune(text, text) to authenticated;

create or replace function creer_ecole(p_commune_id uuid, p_nom text)
returns ecoles
language plpgsql security definer set search_path = public
as $$
declare
  v_ecole ecoles%rowtype;
begin
  if role_courant() <> 'super_admin' then
    raise exception 'Seul un super-administrateur peut créer une école.';
  end if;
  insert into ecoles (commune_id, nom) values (p_commune_id, p_nom) returning * into v_ecole;
  return v_ecole;
end;
$$;
grant execute on function creer_ecole(uuid, text) to authenticated;

-- ---------------------------------------------------------
-- Row Level Security — nouvelles tables
-- ---------------------------------------------------------

alter table communes enable row level security;
create policy "communes_lecture" on communes for select using (true);

alter table ecoles enable row level security;
create policy "ecoles_lecture" on ecoles for select using (true);

alter table ressources enable row level security;
create policy "ressources_lecture" on ressources for select
  using (role_courant() in ('enseignant', 'directeur', 'agent_commune', 'super_admin'));
create policy "ressources_gestion_super_admin" on ressources for all
  using (role_courant() = 'super_admin') with check (role_courant() = 'super_admin');

-- ---------------------------------------------------------
-- Row Level Security — extensions des tables existantes
-- (policies SELECT additionnelles : PostgreSQL combine plusieurs policies
-- permissives avec OR, ceci ne remplace aucune policy déjà en place)
-- ---------------------------------------------------------

create policy "classes_lecture_directeur" on classes for select
  using (is_directeur_of_ecole(ecole_id));
create policy "classes_lecture_agent_commune" on classes for select
  using (exists(select 1 from ecoles e where e.id = classes.ecole_id and is_agent_of_commune(e.commune_id)));

create policy "classe_eleves_lecture_directeur" on classe_eleves for select
  using (is_directeur_of_eleve(eleve_id));
create policy "classe_eleves_lecture_agent" on classe_eleves for select
  using (is_agent_of_eleve(eleve_id));

create policy "tentatives_directeur_lecture" on tentatives for select
  using (is_directeur_of_eleve(eleve_id));
create policy "tentatives_agent_lecture" on tentatives for select
  using (is_agent_of_eleve(eleve_id));

create policy "progres_directeur_lecture" on progres_lecons for select
  using (is_directeur_of_eleve(eleve_id));
create policy "progres_agent_lecture" on progres_lecons for select
  using (is_agent_of_eleve(eleve_id));

create policy "profils_visibles_directeur" on profiles for select
  using (is_directeur_of_eleve(id));
create policy "profils_visibles_agent" on profiles for select
  using (is_agent_of_eleve(id));
