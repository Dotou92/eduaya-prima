-- =========================================================
-- EduAya Prima — Identifiant élève visible en permanence dans le roster enseignant
--
-- À EXÉCUTER APRÈS schema.sql, seed.sql, seed_contenu.sql, schema_communes.sql
-- et schema_phase3.sql. Coller dans le SQL Editor Supabase et cliquer "Run".
-- =========================================================

alter table profiles add column if not exists identifiant text;

create or replace function handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_role text := coalesce(new.raw_user_meta_data->>'role', 'non_defini');
  v_code text;
  v_identifiant text;
begin
  if v_role = 'ecolier' then
    loop
      v_code := generer_code(6);
      exit when not exists (select 1 from profiles where code_liaison_parent = v_code);
    end loop;
    v_identifiant := split_part(new.email, '@', 1);
  end if;

  insert into profiles (id, role, prenom, nom, niveau_id, code_liaison_parent, ecole_id, commune_id, identifiant)
  values (
    new.id,
    v_role,
    coalesce(
      new.raw_user_meta_data->>'prenom',
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      'Utilisateur'
    ),
    new.raw_user_meta_data->>'nom',
    nullif(new.raw_user_meta_data->>'niveau_id', '')::smallint,
    v_code,
    nullif(new.raw_user_meta_data->>'ecole_id', '')::uuid,
    nullif(new.raw_user_meta_data->>'commune_id', '')::uuid,
    v_identifiant
  );
  return new;
end;
$$;

-- Complète l'identifiant des comptes élèves déjà créés avant cette mise à jour.
update profiles p
set identifiant = split_part(u.email, '@', 1)
from auth.users u
where p.id = u.id and p.role = 'ecolier' and p.identifiant is null;
