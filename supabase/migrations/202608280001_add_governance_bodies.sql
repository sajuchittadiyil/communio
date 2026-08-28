-- Effective-dated governance bodies and memberships. Governance membership is
-- deliberately separate from canonical Province office appointments.

alter table public.app_user_access
  add column if not exists congregation_id uuid references public.congregations(id) on delete restrict,
  add column if not exists province_id uuid references public.provinces(id) on delete restrict;

update public.app_user_access access
set congregation_id = province.congregation_id,
    province_id = province.id,
    updated_at = now()
from public.provinces province
where province.active
  and (access.congregation_id is null or access.province_id is null)
  and (select count(*) from public.provinces active_province where active_province.active) = 1;

create index if not exists app_user_access_scope_idx
  on public.app_user_access (auth_user_id, congregation_id, province_id)
  where active;

create table if not exists public.governance_bodies (
  id uuid primary key default gen_random_uuid(),
  congregation_id uuid not null references public.congregations(id) on delete restrict,
  province_id uuid not null references public.provinces(id) on delete restrict,
  code text not null,
  name text not null,
  short_name text,
  body_type_code text not null,
  description text,
  purpose text,
  status_code text not null default 'ACTIVE',
  established_date date,
  dissolved_date date,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint governance_bodies_code_format check (code ~ '^[A-Z][A-Z0-9_-]*$'),
  constraint governance_bodies_type_format check (body_type_code ~ '^[A-Z][A-Z0-9_-]*$'),
  constraint governance_bodies_status check (status_code in ('ACTIVE', 'INACTIVE')),
  constraint governance_bodies_dates check (
    dissolved_date is null or established_date is null or dissolved_date >= established_date
  ),
  constraint governance_bodies_name_present check (btrim(name) <> ''),
  unique (province_id, code)
);

create table if not exists public.governance_body_memberships (
  id uuid primary key default gen_random_uuid(),
  governance_body_id uuid not null references public.governance_bodies(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete restrict,
  role_code text not null,
  role_title text,
  start_date date not null,
  end_date date,
  appointment_reference text,
  notes text,
  status_code text not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint governance_membership_role_format check (role_code ~ '^[A-Z][A-Z0-9_-]*$'),
  constraint governance_membership_status check (status_code in ('ACTIVE', 'INACTIVE', 'CANCELLED')),
  constraint governance_membership_dates check (end_date is null or end_date >= start_date),
  constraint governance_membership_unique_start unique (
    governance_body_id, member_id, role_code, start_date
  )
);

create index if not exists governance_bodies_province_idx
  on public.governance_bodies (province_id, status_code, display_order, name);
create index if not exists governance_bodies_congregation_idx
  on public.governance_bodies (congregation_id, province_id);
create index if not exists governance_memberships_body_idx
  on public.governance_body_memberships (governance_body_id);
create index if not exists governance_memberships_member_idx
  on public.governance_body_memberships (member_id);
create index if not exists governance_memberships_dates_idx
  on public.governance_body_memberships (start_date, end_date);
create index if not exists governance_memberships_role_idx
  on public.governance_body_memberships (role_code);

create or replace function public.prevent_overlapping_governance_membership_terms()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.status_code <> 'CANCELLED' and exists (
    select 1
    from public.governance_body_memberships existing
    where existing.governance_body_id = new.governance_body_id
      and existing.member_id = new.member_id
      and existing.role_code = new.role_code
      and existing.status_code <> 'CANCELLED'
      and existing.id <> new.id
      and daterange(existing.start_date, coalesce(existing.end_date, 'infinity'::date), '[]')
          && daterange(new.start_date, coalesce(new.end_date, 'infinity'::date), '[]')
  ) then
    raise exception 'Overlapping governance membership term' using errcode = '23P01';
  end if;
  return new;
end;
$$;

drop trigger if exists governance_membership_no_overlap on public.governance_body_memberships;
create trigger governance_membership_no_overlap
before insert or update of governance_body_id, member_id, role_code, start_date, end_date, status_code
on public.governance_body_memberships
for each row execute function public.prevent_overlapping_governance_membership_terms();

alter table public.governance_bodies enable row level security;
alter table public.governance_body_memberships enable row level security;

revoke all on public.governance_bodies from anon, authenticated;
revoke all on public.governance_body_memberships from anon, authenticated;
grant select on public.governance_bodies to authenticated;
grant select on public.governance_body_memberships to authenticated;
grant all on public.governance_bodies to service_role;
grant all on public.governance_body_memberships to service_role;

create policy governance_bodies_provincial_read on public.governance_bodies
for select to authenticated using (
  exists (
    select 1 from public.app_user_access access
    where access.auth_user_id = auth.uid()
      and access.active
      and access.access_role = 'provincial'
      and access.congregation_id = governance_bodies.congregation_id
      and access.province_id = governance_bodies.province_id
  )
);

create policy governance_memberships_provincial_read on public.governance_body_memberships
for select to authenticated using (
  exists (
    select 1
    from public.governance_bodies body
    join public.app_user_access access
      on access.congregation_id = body.congregation_id
     and access.province_id = body.province_id
    where body.id = governance_body_memberships.governance_body_id
      and access.auth_user_id = auth.uid()
      and access.active
      and access.access_role = 'provincial'
  )
);

create or replace view public.v_governance_body_directory
with (security_invoker = true) as
select
  body.id as governance_body_id,
  body.congregation_id,
  body.province_id,
  body.code,
  body.name,
  body.short_name,
  body.body_type_code,
  body.description,
  body.purpose,
  body.status_code,
  body.established_date,
  body.dissolved_date,
  body.display_order,
  leader.member_id as chair_member_id,
  leader.display_name as chair_display_name,
  leader.role_code as chair_role_code,
  coalesce(current_members.member_count, 0) as current_member_count
from public.governance_bodies body
left join lateral (
  select membership.member_id, member.display_name, membership.role_code
  from public.governance_body_memberships membership
  join public.members member on member.id = membership.member_id
  where membership.governance_body_id = body.id
    and membership.status_code = 'ACTIVE'
    and membership.start_date <= current_date
    and (membership.end_date is null or membership.end_date >= current_date)
    and membership.role_code in ('CHAIR', 'PRESIDENT')
  order by case membership.role_code when 'PRESIDENT' then 0 else 1 end,
    membership.start_date desc, member.display_name
  limit 1
) leader on true
left join lateral (
  select count(distinct membership.member_id) as member_count
  from public.governance_body_memberships membership
  where membership.governance_body_id = body.id
    and membership.status_code = 'ACTIVE'
    and membership.start_date <= current_date
    and (membership.end_date is null or membership.end_date >= current_date)
) current_members on true;

create or replace view public.v_governance_body_current_members
with (security_invoker = true) as
select
  body.id as governance_body_id,
  body.congregation_id,
  body.province_id,
  body.code,
  body.name,
  body.body_type_code,
  membership.id as membership_id,
  member.id as member_id,
  member.religious_id,
  member.display_name,
  member.ecclesiastical_title_code,
  member.photo_url,
  membership.role_code,
  membership.role_title,
  membership.start_date,
  membership.end_date
from public.governance_bodies body
join public.governance_body_memberships membership on membership.governance_body_id = body.id
join public.members member on member.id = membership.member_id
where membership.status_code = 'ACTIVE'
  and membership.start_date <= current_date
  and (membership.end_date is null or membership.end_date >= current_date);

create or replace view public.v_governance_body_membership_history
with (security_invoker = true) as
select
  body.id as governance_body_id,
  body.congregation_id,
  body.province_id,
  body.code,
  body.name,
  body.body_type_code,
  membership.id as membership_id,
  member.id as member_id,
  member.religious_id,
  member.display_name,
  member.ecclesiastical_title_code,
  member.photo_url,
  membership.role_code,
  membership.role_title,
  membership.start_date,
  membership.end_date,
  membership.status_code
from public.governance_bodies body
join public.governance_body_memberships membership on membership.governance_body_id = body.id
join public.members member on member.id = membership.member_id;

revoke all on public.v_governance_body_directory from anon, authenticated;
revoke all on public.v_governance_body_current_members from anon, authenticated;
revoke all on public.v_governance_body_membership_history from anon, authenticated;
grant select on public.v_governance_body_directory to authenticated;
grant select on public.v_governance_body_current_members to authenticated;
grant select on public.v_governance_body_membership_history to authenticated;

create or replace function public.get_provincial_governance_bodies_safe()
returns setof jsonb language plpgsql stable security definer set search_path = public as $$
declare
  caller_scope public.app_user_access%rowtype;
begin
  select access.* into caller_scope
  from public.app_user_access access
  where access.auth_user_id = auth.uid()
    and access.active
    and access.access_role = 'provincial';

  if caller_scope.auth_user_id is null
      or caller_scope.congregation_id is null
      or caller_scope.province_id is null then
    raise exception 'Scoped Provincial access required' using errcode = '42501';
  end if;

  return query
  select to_jsonb(body) || jsonb_build_object(
    'governance_body_id', body.id,
    'current_member_count', (
      select count(distinct membership.member_id)
      from public.governance_body_memberships membership
      where membership.governance_body_id = body.id
        and membership.status_code = 'ACTIVE'
        and membership.start_date <= current_date
        and (membership.end_date is null or membership.end_date >= current_date)
    ),
    'memberships', coalesce((
      select jsonb_agg(
        to_jsonb(membership) || jsonb_build_object(
          'membership_id', membership.id,
          'religious_id', member.religious_id,
          'display_name', member.display_name,
          'ecclesiastical_title_code', member.ecclesiastical_title_code,
          'photo_url', member.photo_url
        ) order by
          case when membership.start_date <= current_date
            and (membership.end_date is null or membership.end_date >= current_date)
            and membership.status_code = 'ACTIVE' then 0 else 1 end,
          case membership.role_code
            when 'PRESIDENT' then 0 when 'CHAIR' then 1 when 'SECRETARY' then 2
            when 'TREASURER' then 3 when 'EX_OFFICIO' then 4 else 5 end,
          membership.start_date desc,
          member.display_name
      )
      from public.governance_body_memberships membership
      join public.members member on member.id = membership.member_id
      where membership.governance_body_id = body.id
    ), '[]'::jsonb)
  )
  from public.governance_bodies body
  where body.congregation_id = caller_scope.congregation_id
    and body.province_id = caller_scope.province_id
  order by body.display_order, body.name;
end;
$$;

revoke all on function public.get_provincial_governance_bodies_safe() from public, anon;
grant execute on function public.get_provincial_governance_bodies_safe() to authenticated;

insert into public.governance_bodies (
  id, congregation_id, province_id, code, name, short_name, body_type_code,
  description, purpose, status_code, established_date, display_order
) values
  ('41000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'PROVINCIAL_COUNCIL', 'Provincial Council', 'Council', 'COUNCIL', 'The consultative governance body serving the Provincial administration.', 'To support discernment, accountability, and coordinated leadership across the Province.', 'ACTIVE', '1950-01-01', 10),
  ('41000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'EDUCATION_COMMISSION', 'Education Commission', 'Education', 'COMMISSION', 'Coordinates the Province educational apostolate.', 'To strengthen mission, quality, collaboration, and responsible stewardship in education.', 'ACTIVE', '1984-07-01', 20),
  ('41000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'FINANCE_COMMISSION', 'Finance Commission', 'Finance', 'COMMISSION', 'Advises the Province on financial planning and stewardship.', 'To promote transparent, prudent, and mission-aligned use of resources.', 'ACTIVE', '1992-07-01', 30),
  ('41000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'SUSTAINABILITY_COMMISSION', 'Sustainability Commission', 'Sustainability', 'COMMISSION', 'Coordinates ecological and long-term sustainability priorities.', 'To embed care for creation and resilient stewardship throughout Province life and mission.', 'ACTIVE', '2021-07-01', 40),
  ('41000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'FORMATION_COMMISSION', 'Formation Commission', 'Formation', 'COMMISSION', 'Supports coordination and review of initial and ongoing formation.', 'To foster coherent, discerning, and mission-centered formation across the Province.', 'ACTIVE', '1978-07-01', 50)
on conflict (id) do update set
  congregation_id = excluded.congregation_id,
  province_id = excluded.province_id,
  code = excluded.code,
  name = excluded.name,
  short_name = excluded.short_name,
  body_type_code = excluded.body_type_code,
  description = excluded.description,
  purpose = excluded.purpose,
  status_code = excluded.status_code,
  established_date = excluded.established_date,
  display_order = excluded.display_order,
  updated_at = now();

do $$
declare
  available_members integer;
begin
  select count(*) into available_members from public.members where active;
  if available_members < 9 then
    raise exception 'Governance demo requires at least nine active canonical members';
  end if;
end
$$;

with ranked_members as (
  select id, row_number() over (order by religious_id, id) as position
  from public.members where active
), membership_seed(body_id, member_position, role_code, role_title, start_date, end_date, reference) as (
  values
    ('41000000-0000-4000-8000-000000000001'::uuid, 1, 'PRESIDENT', 'Provincial President', '2024-07-01'::date, '2027-06-30'::date, 'Demo Provincial Council term 2024–2027'),
    ('41000000-0000-4000-8000-000000000001'::uuid, 2, 'SECRETARY', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Provincial Council term 2024–2027'),
    ('41000000-0000-4000-8000-000000000001'::uuid, 3, 'MEMBER', 'Councillor', '2024-07-01'::date, '2027-06-30'::date, 'Demo Provincial Council term 2024–2027'),
    ('41000000-0000-4000-8000-000000000001'::uuid, 4, 'MEMBER', 'Councillor', '2024-07-01'::date, '2027-06-30'::date, 'Demo Provincial Council term 2024–2027'),
    ('41000000-0000-4000-8000-000000000001'::uuid, 5, 'MEMBER', 'Councillor', '2024-07-01'::date, '2027-06-30'::date, 'Demo Provincial Council term 2024–2027'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 3, 'CHAIR', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Education Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 6, 'SECRETARY', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Education Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 7, 'MEMBER', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Education Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 8, 'MEMBER', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Education Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 9, 'EX_OFFICIO', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Education Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000003'::uuid, 5, 'CHAIR', null, '2025-07-01'::date, '2028-06-30'::date, 'Demo Finance Commission term 2025–2028'),
    ('41000000-0000-4000-8000-000000000003'::uuid, 2, 'TREASURER', null, '2025-07-01'::date, '2028-06-30'::date, 'Demo Finance Commission term 2025–2028'),
    ('41000000-0000-4000-8000-000000000003'::uuid, 6, 'SECRETARY', null, '2025-07-01'::date, '2028-06-30'::date, 'Demo Finance Commission term 2025–2028'),
    ('41000000-0000-4000-8000-000000000003'::uuid, 8, 'MEMBER', null, '2025-07-01'::date, '2028-06-30'::date, 'Demo Finance Commission term 2025–2028'),
    ('41000000-0000-4000-8000-000000000004'::uuid, 7, 'CHAIR', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Sustainability Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000004'::uuid, 4, 'SECRETARY', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Sustainability Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000004'::uuid, 6, 'MEMBER', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Sustainability Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000004'::uuid, 9, 'MEMBER', null, '2024-07-01'::date, '2027-06-30'::date, 'Demo Sustainability Commission term 2024–2027'),
    ('41000000-0000-4000-8000-000000000005'::uuid, 2, 'CHAIR', null, '2025-07-01'::date, null::date, 'Demo Formation Commission term from 2025'),
    ('41000000-0000-4000-8000-000000000005'::uuid, 3, 'SECRETARY', null, '2025-07-01'::date, null::date, 'Demo Formation Commission term from 2025'),
    ('41000000-0000-4000-8000-000000000005'::uuid, 5, 'MEMBER', null, '2025-07-01'::date, null::date, 'Demo Formation Commission term from 2025'),
    ('41000000-0000-4000-8000-000000000005'::uuid, 8, 'MEMBER', null, '2025-07-01'::date, null::date, 'Demo Formation Commission term from 2025'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 2, 'CHAIR', null, '2021-07-01'::date, '2024-06-30'::date, 'Demo Education Commission term 2021–2024'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 3, 'SECRETARY', null, '2021-07-01'::date, '2024-06-30'::date, 'Demo Education Commission term 2021–2024'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 5, 'MEMBER', null, '2021-07-01'::date, '2024-06-30'::date, 'Demo Education Commission term 2021–2024'),
    ('41000000-0000-4000-8000-000000000002'::uuid, 7, 'MEMBER', null, '2021-07-01'::date, '2024-06-30'::date, 'Demo Education Commission term 2021–2024'),
    ('41000000-0000-4000-8000-000000000003'::uuid, 4, 'CHAIR', null, '2022-07-01'::date, '2025-06-30'::date, 'Demo Finance Commission term 2022–2025'),
    ('41000000-0000-4000-8000-000000000003'::uuid, 2, 'MEMBER', null, '2022-07-01'::date, '2025-06-30'::date, 'Demo Finance Commission term 2022–2025'),
    ('41000000-0000-4000-8000-000000000003'::uuid, 9, 'SECRETARY', null, '2022-07-01'::date, '2025-06-30'::date, 'Demo Finance Commission term 2022–2025')
)
insert into public.governance_body_memberships (
  governance_body_id, member_id, role_code, role_title, start_date, end_date,
  appointment_reference, status_code
)
select seed.body_id, member.id, seed.role_code, seed.role_title,
  seed.start_date, seed.end_date, seed.reference, 'ACTIVE'
from membership_seed seed
join ranked_members member on member.position = seed.member_position
on conflict (governance_body_id, member_id, role_code, start_date) do update set
  role_title = excluded.role_title,
  end_date = excluded.end_date,
  appointment_reference = excluded.appointment_reference,
  status_code = excluded.status_code,
  updated_at = now();

comment on table public.governance_bodies is
  'Data-driven governance bodies scoped to the existing congregation and Province hierarchy.';
comment on table public.governance_body_memberships is
  'Effective-dated governance membership and role history; separate from canonical office appointments.';
comment on view public.v_governance_body_directory is
  'Security-invoker, Province-scoped governance directory for future authorized reporting.';
comment on view public.v_governance_body_current_members is
  'Security-invoker current governance membership reporting without private profile fields.';
comment on view public.v_governance_body_membership_history is
  'Security-invoker effective-dated governance membership history without private profile fields.';
