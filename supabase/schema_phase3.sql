-- =========================================================
-- EduAya Prima — Connexion Google + réinitialisation du code secret élève
--
-- À EXÉCUTER APRÈS schema.sql, seed.sql, seed_contenu.sql et schema_communes.sql.
-- Coller dans le SQL Editor Supabase et cliquer "Run".
-- =========================================================

-- ---------------------------------------------------------
-- 1. Connexion Google : un compte créé via OAuth n'a pas de "role" dans ses
--    métadonnées (Google ne fournit que nom/email/photo). On lui donne le
--    rôle temporaire 'non_defini', que la page auth/oauth-callback.html
--    remplace ensuite par 'enseignant' ou 'parent' — la SEULE transition de
--    rôle autorisée après création, pour ne pas rouvrir la porte à une
--    usurpation de rôle (ex. passer enseignant → directeur).
-- ---------------------------------------------------------

alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check
  check (role in ('ecolier', 'parent', 'enseignant', 'directeur', 'agent_commune', 'super_admin', 'non_defini'));

create or replace function handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_role text := coalesce(new.raw_user_meta_data->>'role', 'non_defini');
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
    nullif(new.raw_user_meta_data->>'commune_id', '')::uuid
  );
  return new;
end;
$$;

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

-- ---------------------------------------------------------
-- 2. Réinitialisation du code secret (PIN) d'un élève par son enseignant,
--    en cas de carte perdue. Manipule directement auth.users (hachage bcrypt
--    via pgcrypto, déjà activé) : approche non officiellement documentée par
--    Supabase mais couramment utilisée en l'absence de clé service-role côté
--    client — à surveiller en cas de changement interne de Supabase Auth.
-- ---------------------------------------------------------

create or replace function regenerer_identifiants_eleve(p_eleve_id uuid)
returns table(identifiant text, nouveau_pin text)
language plpgsql security definer set search_path = public
as $$
declare
  v_email text;
  v_pin text;
begin
  if not is_teacher_of_eleve(p_eleve_id) then
    raise exception 'Seul l''enseignant de cet élève peut réinitialiser son code secret.';
  end if;

  select email into v_email from auth.users where id = p_eleve_id;
  if v_email is null then
    raise exception 'Élève introuvable.';
  end if;

  v_pin := lpad(floor(random() * 900000 + 100000)::text, 6, '0');

  update auth.users
    set encrypted_password = crypt(v_pin, gen_salt('bf')),
        updated_at = now()
    where id = p_eleve_id;

  return query select split_part(v_email, '@', 1), v_pin;
end;
$$;

grant execute on function regenerer_identifiants_eleve(uuid) to authenticated;
