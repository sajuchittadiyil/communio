begin;

do $$
declare sample public.member_transfers%rowtype;
begin
  if (select count(*) from public.member_transfers where status_code = 'CONFIRMED') < 5 then
    raise exception 'expected deliberate confirmed demo transfers';
  end if;
  if exists (
    select 1 from public.v_member_transfers
    where to_jsonb(v_member_transfers) ?| array[
      'reason', 'reference_code', 'notes', 'document_id'
    ]
  ) then
    raise exception 'safe transfer view leaks restricted fields';
  end if;
  select * into sample from public.member_transfers limit 1;

  begin
    insert into public.member_transfers (
      congregation_id, province_id, member_id, from_community_id,
      to_community_id, effective_date
    ) values (
      sample.congregation_id, sample.province_id, sample.member_id,
      sample.from_community_id, sample.to_community_id, sample.effective_date
    );
    raise exception 'duplicate transfer constraint did not reject';
  exception when unique_violation then null;
  end;
  begin
    insert into public.member_transfers (
      congregation_id, province_id, member_id, from_community_id,
      to_community_id, effective_date
    ) values (
      sample.congregation_id, sample.province_id, sample.member_id,
      sample.from_community_id, sample.from_community_id, date '2016-01-01'
    );
    raise exception 'same endpoints constraint did not reject';
  exception when check_violation then null;
  end;
  begin
    insert into public.member_transfers (
      congregation_id, province_id, member_id, effective_date
    ) values (
      sample.congregation_id, sample.province_id, sample.member_id, date '2016-01-01'
    );
    raise exception 'endpoint-required constraint did not reject';
  exception when check_violation then null;
  end;
  begin
    insert into public.member_transfers (
      congregation_id, province_id, member_id, from_community_id,
      effective_date, transfer_type_code
    ) values (
      sample.congregation_id, sample.province_id, sample.member_id,
      sample.from_community_id, date '2016-01-01', 'PROMOTION'
    );
    raise exception 'type constraint did not reject';
  exception when check_violation then null;
  end;
  begin
    insert into public.member_transfers (
      congregation_id, province_id, member_id, from_community_id,
      effective_date, status_code
    ) values (
      sample.congregation_id, sample.province_id, sample.member_id,
      sample.from_community_id, date '2016-01-01', 'DONE'
    );
    raise exception 'status constraint did not reject';
  exception when check_violation then null;
  end;
  begin
    insert into public.member_transfers (
      congregation_id, province_id, member_id, from_community_id, effective_date
    ) values (
      sample.congregation_id, sample.province_id, gen_random_uuid(),
      sample.from_community_id, date '2016-01-01'
    );
    raise exception 'member foreign key did not reject';
  exception when foreign_key_violation then null;
  end;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'member_transfers'
      and policyname = 'member_transfers_scoped_read'
      and roles @> array['authenticated']::name[]
      and qual like '%congregation_id%'
      and qual like '%province_id%'
      and qual like '%current_managed_community_id%'
  ) then
    raise exception 'scoped transfer RLS policy is missing';
  end if;
  if coalesce((
    select c.reloptions @> array['security_invoker=true']
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'v_member_transfers'
  ), false) is not true then
    raise exception 'transfer view is not security-invoker';
  end if;
end $$;

rollback;
