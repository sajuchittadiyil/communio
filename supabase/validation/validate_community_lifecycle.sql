begin;

do $$
declare sample public.community_lifecycle_events%rowtype;
begin
  if not exists (select 1 from public.community_lifecycle_events) then
    raise exception 'community lifecycle has no canonical opening records';
  end if;
  if exists (
    select 1 from public.community_lifecycle_events event
    left join public.communities community on community.id = event.community_id
    where community.id is null
  ) then
    raise exception 'orphan lifecycle community reference found';
  end if;
  if exists (
    select 1 from public.v_community_lifecycle
    where to_jsonb(v_community_lifecycle) ?| array[
      'phone', 'email', 'address', 'notes', 'reason', 'reference'
    ]
  ) then
    raise exception 'lifecycle reporting view exposes private fields';
  end if;

  select * into sample from public.community_lifecycle_events limit 1;
  begin
    insert into public.community_lifecycle_events (
      congregation_id, province_id, community_id, event_type_code,
      effective_date, date_precision_code
    ) values (
      sample.congregation_id, sample.province_id, sample.community_id,
      sample.event_type_code, sample.effective_date, sample.date_precision_code
    );
    raise exception 'duplicate lifecycle constraint did not reject';
  exception when unique_violation then null;
  end;
  begin
    insert into public.community_lifecycle_events (
      congregation_id, province_id, community_id, event_type_code, effective_date
    ) values (
      sample.congregation_id, sample.province_id, sample.community_id,
      'MOVED', date '2015-01-01'
    );
    raise exception 'event type constraint did not reject';
  exception when check_violation then null;
  end;
  begin
    insert into public.community_lifecycle_events (
      congregation_id, province_id, community_id, event_type_code, effective_date
    ) values (
      sample.congregation_id, sample.province_id, gen_random_uuid(),
      'OPENED', date '2015-01-01'
    );
    raise exception 'community foreign key did not reject';
  exception when foreign_key_violation then null;
  end;
  begin
    insert into public.community_lifecycle_events (
      congregation_id, province_id, community_id, event_type_code,
      effective_date, date_precision_code
    ) values (
      sample.congregation_id, sample.province_id, sample.community_id,
      'STATUS_CHANGED', date '2015-06-01', 'YEAR'
    );
    raise exception 'year precision date constraint did not reject';
  exception when check_violation then null;
  end;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'community_lifecycle_events'
      and policyname = 'community_lifecycle_scoped_read'
      and roles @> array['authenticated']::name[]
      and qual like '%congregation_id%'
      and qual like '%province_id%'
      and qual like '%current_managed_community_id%'
  ) then
    raise exception 'scoped lifecycle RLS policy is missing';
  end if;
  if coalesce((
    select c.reloptions @> array['security_invoker=true']
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'v_community_lifecycle'
  ), false) is not true then
    raise exception 'lifecycle reporting view is not security-invoker';
  end if;
end $$;

rollback;
