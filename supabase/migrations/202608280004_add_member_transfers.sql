-- Explicit formal member-transfer ledger. Assignment transitions are not
-- transfer records and are never used to populate this table automatically.

create table public.member_transfers (
  id uuid primary key default gen_random_uuid(),
  congregation_id uuid not null references public.congregations(id) on delete restrict,
  province_id uuid not null references public.provinces(id) on delete restrict,
  member_id uuid not null references public.members(id) on delete restrict,
  from_community_id uuid references public.communities(id) on delete restrict,
  to_community_id uuid references public.communities(id) on delete restrict,
  effective_date date not null,
  transfer_type_code text not null default 'TRANSFER',
  status_code text not null default 'CONFIRMED',
  reason text,
  reference_code text,
  document_id uuid references public.province_documents(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_transfers_endpoint_present check (
    from_community_id is not null or to_community_id is not null
  ),
  constraint member_transfers_distinct_endpoints check (
    from_community_id is null or to_community_id is null
    or from_community_id <> to_community_id
  ),
  constraint member_transfers_type check (
    transfer_type_code in (
      'TRANSFER', 'TEMPORARY_TRANSFER', 'REASSIGNMENT', 'RETURN', 'OTHER'
    )
  ),
  constraint member_transfers_status check (
    status_code in ('CONFIRMED', 'CANCELLED', 'PLANNED')
  )
);

create unique index member_transfers_unique_movement
on public.member_transfers (
  member_id,
  coalesce(from_community_id, '00000000-0000-0000-0000-000000000000'::uuid),
  coalesce(to_community_id, '00000000-0000-0000-0000-000000000000'::uuid),
  effective_date
);
create index member_transfers_scope_date_idx
  on public.member_transfers (congregation_id, province_id, effective_date);
create index member_transfers_member_date_idx
  on public.member_transfers (member_id, effective_date desc);
create index member_transfers_from_date_idx
  on public.member_transfers (from_community_id, effective_date, status_code);

create or replace function public.validate_member_transfer_scope()
returns trigger language plpgsql set search_path = public as $$
begin
  if not exists (
    select 1 from public.provinces province
    where province.id = new.province_id
      and province.congregation_id = new.congregation_id
  ) then
    raise exception 'Transfer province does not belong to congregation'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger member_transfers_validate_scope
before insert on public.member_transfers
for each row execute function public.validate_member_transfer_scope();

create trigger member_transfers_set_updated_at
before update on public.member_transfers
for each row execute function public.set_updated_at();

alter table public.member_transfers enable row level security;
revoke all on public.member_transfers from public, anon, authenticated, service_role;
grant select on public.member_transfers to authenticated;
grant select, insert on public.member_transfers to service_role;

create policy member_transfers_scoped_read
on public.member_transfers for select to authenticated using (
  exists (
    select 1
    from public.app_user_access access
    where access.auth_user_id = auth.uid()
      and access.active
      and access.congregation_id = member_transfers.congregation_id
      and access.province_id = member_transfers.province_id
      and (
        access.access_role in ('provincial', 'member')
        or (
          access.access_role = 'community_superior'
          and (
            member_transfers.from_community_id = public.current_managed_community_id()
            or member_transfers.to_community_id = public.current_managed_community_id()
            or exists (
              select 1 from public.member_community_assignments assignment
              where assignment.member_id = member_transfers.member_id
                and assignment.community_id = public.current_managed_community_id()
                and assignment.from_date <= current_date
                and (assignment.to_date is null or assignment.to_date >= current_date)
            )
          )
        )
      )
  )
);

create or replace view public.v_member_transfers
with (security_invoker = true) as
select
  transfer.id as transfer_id,
  transfer.congregation_id,
  transfer.province_id,
  transfer.member_id,
  member.religious_id,
  member.display_name,
  transfer.from_community_id,
  source.name as from_community_name,
  transfer.to_community_id,
  destination.name as to_community_name,
  transfer.effective_date,
  transfer.transfer_type_code,
  transfer.status_code
from public.member_transfers transfer
join public.members member on member.id = transfer.member_id
left join public.communities source on source.id = transfer.from_community_id
left join public.communities destination on destination.id = transfer.to_community_id;

revoke all on public.v_member_transfers from public, anon;
grant select on public.v_member_transfers to authenticated;

-- Deliberate fictional formal records. Assignment chronology was checked only
-- for consistency; these explicit rows are the source of transfer semantics.
with scope as (
  select province.congregation_id, province.id as province_id
  from public.provinces province
  where province.active
  order by province.created_at, province.id
  limit 1
), demo(religious_id, from_code, to_code, effective_date, reference_code) as (
  values
    ('REL-0112', 'COM005', 'COM006', date '2015-07-01', 'DEMO-TR/2015/001'),
    ('REL-0101', 'COM005', 'COM007', date '2015-07-01', 'DEMO-TR/2015/002'),
    ('REL-0113', 'COM005', 'COM013', date '2015-07-01', 'DEMO-TR/2015/003'),
    ('REL-0002', 'COM005', 'COM006', date '2005-01-01', 'DEMO-TR/2005/001'),
    ('REL-0106', 'COM005', 'COM008', date '2026-08-08', 'DEMO-TR/2026/017')
)
insert into public.member_transfers (
  congregation_id, province_id, member_id, from_community_id,
  to_community_id, effective_date, transfer_type_code, status_code,
  reason, reference_code
)
select
  scope.congregation_id, scope.province_id, member.id, source.id,
  destination.id, demo.effective_date, 'TRANSFER', 'CONFIRMED',
  'New community assignment', demo.reference_code
from demo
join public.members member on member.religious_id = demo.religious_id
join public.communities source on source.code = demo.from_code
join public.communities destination on destination.code = demo.to_code
cross join scope
where member.active
on conflict do nothing;

comment on table public.member_transfers is
  'Immutable explicit formal-transfer ledger; never inferred from assignment boundaries.';
comment on view public.v_member_transfers is
  'Security-invoker formal-transfer reporting without reasons, references, notes, or documents.';
