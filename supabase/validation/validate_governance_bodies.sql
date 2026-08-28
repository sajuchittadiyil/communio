do $$
declare
  body_count integer;
  current_count integer;
  history_count integer;
  chair_count integer;
  invalid_scope_count integer;
  invalid_date_count integer;
  insecure_view_count integer;
begin
  select count(*) into body_count
  from public.governance_bodies
  where province_id = '20000000-0000-4000-8000-000000000001';
  if body_count <> 5 then
    raise exception 'Expected 5 demo governance bodies, found %', body_count;
  end if;

  select count(*) into current_count
  from public.v_governance_body_current_members;
  if current_count <> 22 then
    raise exception 'Expected 22 current governance memberships, found %', current_count;
  end if;

  select count(*) into history_count
  from public.v_governance_body_membership_history
  where end_date < current_date;
  if history_count <> 7 then
    raise exception 'Expected 7 historical governance memberships, found %', history_count;
  end if;

  select count(*) into chair_count
  from public.v_governance_body_directory
  where chair_member_id is not null;
  if chair_count <> 5 then
    raise exception 'Expected every demo body to resolve a current leader, found %', chair_count;
  end if;

  select count(*) into invalid_scope_count
  from public.governance_bodies body
  join public.provinces province on province.id = body.province_id
  where province.congregation_id <> body.congregation_id;
  if invalid_scope_count <> 0 then
    raise exception 'Found governance bodies crossing congregation/Province scope';
  end if;

  select count(*) into invalid_date_count
  from public.governance_body_memberships
  where end_date < start_date;
  if invalid_date_count <> 0 then
    raise exception 'Found invalid governance membership dates';
  end if;

  select count(*) into insecure_view_count
  from pg_class
  where relname in (
    'v_governance_body_directory',
    'v_governance_body_current_members',
    'v_governance_body_membership_history'
  )
    and not coalesce(reloptions, '{}'::text[]) @> array['security_invoker=true'];
  if insecure_view_count <> 0 then
    raise exception 'A governance reporting view is not security-invoker';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'governance_bodies'
      and policyname = 'governance_bodies_provincial_read'
  ) or not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'governance_body_memberships'
      and policyname = 'governance_memberships_provincial_read'
  ) then
    raise exception 'Governance RLS policies are missing';
  end if;
end
$$;

select body.name, body.current_member_count, body.chair_display_name,
  body.chair_role_code
from public.v_governance_body_directory body
order by body.display_order, body.name;

begin;
select set_config(
  'request.jwt.claim.sub',
  (select id::text from auth.users where lower(email) = 'admin@communio.com'),
  true
);
set local role authenticated;
do $$
begin
  if (select count(*) from public.governance_bodies) <> 5 then
    raise exception 'Scoped Provincial caller did not receive exactly five bodies';
  end if;
end
$$;
rollback;

begin;
select set_config(
  'request.jwt.claim.sub',
  (select id::text from auth.users where lower(email) = 'member@communio.com'),
  true
);
set local role authenticated;
do $$
begin
  if (select count(*) from public.governance_bodies) <> 0 then
    raise exception 'Ordinary member received unauthorized governance rows';
  end if;
end
$$;
rollback;
