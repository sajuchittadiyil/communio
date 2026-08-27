-- Map the already-created Google Play closed-testing Auth identity onto the
-- existing least-privileged application persona. This migration creates no
-- Auth user and changes no canonical member or assignment data.
do $$
declare
  tester_auth_id uuid;
  tester_member_id uuid;
  target_count integer;
begin
  -- Assert the frozen demo-account mappings before adding another identity.
  if not exists (
    select 1
    from auth.users auth_user
    join public.app_user_access access on access.auth_user_id = auth_user.id
    where lower(auth_user.email) = 'admin@communio.com'
      and access.active
      and access.access_role = 'provincial'
  ) then
    raise exception 'Expected admin@communio.com Provincial mapping is missing';
  end if;

  if not exists (
    select 1
    from auth.users auth_user
    join public.app_user_access access on access.auth_user_id = auth_user.id
    join public.members member on member.id = access.member_id
    where lower(auth_user.email) = 'member@communio.com'
      and access.active
      and access.access_role = 'member'
      and member.religious_id = 'REL-0019'
      and member.display_name = 'Roy Noronha'
  ) then
    raise exception 'Expected member@communio.com / Roy Noronha mapping is missing';
  end if;

  if not exists (
    select 1
    from auth.users auth_user
    join public.app_user_access access on access.auth_user_id = auth_user.id
    join public.members member on member.id = access.member_id
    where lower(auth_user.email) = 'superior@communio.com'
      and access.active
      and access.access_role = 'community_superior'
      and member.religious_id = 'REL-0030'
      and member.display_name = 'Felix Xalxo'
  ) then
    raise exception 'Expected superior@communio.com / Felix Xalxo mapping is missing';
  end if;

  select id into tester_auth_id
  from auth.users
  where lower(email) = 'tester@nilacode.com';

  if tester_auth_id is null then
    raise exception 'Existing tester@nilacode.com Auth user was not found';
  end if;
  if tester_auth_id <> '2eac503a-c6a0-4edd-b179-f8d12017871d'::uuid then
    raise exception 'tester@nilacode.com Auth UUID does not match the verified identity';
  end if;
  if exists (
    select 1 from public.app_user_access
    where auth_user_id = tester_auth_id
  ) then
    raise exception 'tester@nilacode.com already has an application mapping';
  end if;

  -- David is an active demo resident and is not one of the frozen login
  -- personas. Mapping to his existing record gives the tester normal MEMBER
  -- navigation without inventing or modifying member/community data.
  select count(*)
    into target_count
  from public.members member
  where member.active
    and member.display_name = 'David Pradhan'
    and not exists (
      select 1 from public.app_user_access access
      where access.member_id = member.id and access.active
    );

  if target_count <> 1 then
    raise exception 'Expected exactly one active unmapped David Pradhan demo member';
  end if;

  select member.id into tester_member_id
  from public.members member
  where member.active
    and member.display_name = 'David Pradhan'
    and not exists (
      select 1 from public.app_user_access access
      where access.member_id = member.id and access.active
    );

  insert into public.app_user_access (
    auth_user_id,
    member_id,
    access_role,
    active
  ) values (
    tester_auth_id,
    tester_member_id,
    'member',
    true
  );
end
$$;
