-- Explicit effective-dated community lifecycle history. Membership assignment
-- boundaries and current active flags are never treated as lifecycle dates.

create table public.community_lifecycle_events (
  id uuid primary key default gen_random_uuid(),
  congregation_id uuid not null references public.congregations(id) on delete restrict,
  province_id uuid not null references public.provinces(id) on delete restrict,
  community_id uuid not null references public.communities(id) on delete restrict,
  event_type_code text not null,
  effective_date date not null,
  date_precision_code text not null default 'DAY',
  reason text,
  reference text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint community_lifecycle_event_type check (
    event_type_code in ('OPENED', 'CLOSED', 'REOPENED', 'STATUS_CHANGED')
  ),
  constraint community_lifecycle_date_precision check (
    date_precision_code in ('YEAR', 'DAY')
  ),
  constraint community_lifecycle_year_precision check (
    date_precision_code <> 'YEAR'
    or (extract(month from effective_date) = 1 and extract(day from effective_date) = 1)
  ),
  constraint community_lifecycle_unique_event unique (
    community_id, event_type_code, effective_date
  )
);

create index community_lifecycle_scope_idx
  on public.community_lifecycle_events (
    congregation_id, province_id, effective_date, event_type_code
  );
create index community_lifecycle_community_idx
  on public.community_lifecycle_events (community_id, effective_date, event_type_code);

create trigger community_lifecycle_set_updated_at
before update on public.community_lifecycle_events
for each row execute function public.set_updated_at();

alter table public.community_lifecycle_events enable row level security;
revoke all on public.community_lifecycle_events from public, anon, authenticated;
grant select on public.community_lifecycle_events to authenticated;
grant all on public.community_lifecycle_events to service_role;

create policy community_lifecycle_scoped_read
on public.community_lifecycle_events for select to authenticated using (
  exists (
    select 1
    from public.app_user_access access
    where access.auth_user_id = auth.uid()
      and access.active
      and access.congregation_id = community_lifecycle_events.congregation_id
      and access.province_id = community_lifecycle_events.province_id
      and (
        access.access_role in ('provincial', 'member')
        or (
          access.access_role = 'community_superior'
          and community_lifecycle_events.community_id = public.current_managed_community_id()
        )
      )
  )
);

create or replace view public.v_community_lifecycle
with (security_invoker = true) as
select
  event.id as lifecycle_event_id,
  event.congregation_id,
  event.province_id,
  event.community_id,
  community.code as community_code,
  community.name as community_name,
  community.active as current_active,
  event.event_type_code,
  event.effective_date,
  extract(year from event.effective_date)::integer as effective_year,
  event.date_precision_code
from public.community_lifecycle_events event
join public.communities community on community.id = event.community_id;

revoke all on public.v_community_lifecycle from public, anon;
grant select on public.v_community_lifecycle to authenticated;

-- Existing January 1 demo dates encode verified opening years, not invented
-- day precision. Any future non-January-1 canonical date retains day precision.
with scope as (
  select province.congregation_id, province.id as province_id
  from public.provinces province
  where province.active
  order by province.created_at, province.id
  limit 1
)
insert into public.community_lifecycle_events (
  congregation_id, province_id, community_id, event_type_code,
  effective_date, date_precision_code, reference
)
select
  scope.congregation_id, scope.province_id, community.id, 'OPENED',
  community.opened_on,
  case
    when extract(month from community.opened_on) = 1
      and extract(day from community.opened_on) = 1 then 'YEAR'
    else 'DAY'
  end,
  'Canonical communities.opened_on'
from public.communities community
cross join scope
where community.opened_on is not null
on conflict (community_id, event_type_code, effective_date) do nothing;

with scope as (
  select province.congregation_id, province.id as province_id
  from public.provinces province
  where province.active
  order by province.created_at, province.id
  limit 1
)
insert into public.community_lifecycle_events (
  congregation_id, province_id, community_id, event_type_code,
  effective_date, date_precision_code, reference
)
select
  scope.congregation_id, scope.province_id, community.id, 'CLOSED',
  community.closed_on, 'DAY', 'Canonical communities.closed_on'
from public.communities community
cross join scope
where community.closed_on is not null
on conflict (community_id, event_type_code, effective_date) do nothing;

comment on table public.community_lifecycle_events is
  'Explicit effective-dated community opening, closure, reopening, and status-change history.';
comment on view public.v_community_lifecycle is
  'Security-invoker lifecycle reporting with safe community identity and no private fields.';
