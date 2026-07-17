-- =========================================================
-- EduAya Prima — Réinitialisation du mot de passe des comptes institutionnels
-- (directeur, agent_commune, agent_numerique) par le super-admin.
--
-- Jusqu'ici, si le mot de passe temporaire affiché à la création n'était pas
-- noté, le compte était définitivement bloqué. Cette fonction couvre ce cas,
-- comme regenerer_identifiants_eleve() le fait déjà pour les élèves.
--
-- À exécuter après tous les fichiers précédents.
-- =========================================================

create or replace function lister_comptes_institutionnels()
returns table(id uuid, prenom text, nom text, role text, email text, ecole_nom text, commune_nom text)
language plpgsql security definer set search_path = public
as $$
begin
  if role_courant() <> 'super_admin' then
    raise exception 'Réservé au super-administrateur.';
  end if;

  return query
    select p.id, p.prenom, p.nom, p.role, u.email,
           e.nom as ecole_nom, c.nom as commune_nom
    from profiles p
    join auth.users u on u.id = p.id
    left join ecoles e on e.id = p.ecole_id
    left join communes c on c.id = p.commune_id
    where p.role in ('directeur', 'agent_commune', 'agent_numerique')
    order by p.role, p.prenom;
end;
$$;
grant execute on function lister_comptes_institutionnels() to authenticated;

create or replace function reinitialiser_mot_de_passe(p_utilisateur_id uuid)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_role text;
  v_nouveau_mdp text;
begin
  if role_courant() <> 'super_admin' then
    raise exception 'Réservé au super-administrateur.';
  end if;

  select role into v_role from profiles where id = p_utilisateur_id;
  if v_role not in ('directeur', 'agent_commune', 'agent_numerique') then
    raise exception 'Ce compte ne peut pas être réinitialisé depuis cette fonction.';
  end if;

  v_nouveau_mdp := generer_code(10);

  update auth.users
    set encrypted_password = crypt(v_nouveau_mdp, gen_salt('bf')),
        updated_at = now()
    where id = p_utilisateur_id;

  return v_nouveau_mdp;
end;
$$;
grant execute on function reinitialiser_mot_de_passe(uuid) to authenticated;
