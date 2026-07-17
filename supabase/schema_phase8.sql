-- =========================================================
-- EduAya Prima — Correctif : lister_comptes_institutionnels()
--
-- Erreur "structure of query does not match function result type" :
-- auth.users.email n'est pas exactement de type `text` (character varying),
-- il faut le caster explicitement. Remplace simplement la fonction précédente.
--
-- À exécuter après schema_phase7.sql.
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
    select p.id, p.prenom, p.nom, p.role, u.email::text as email,
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
