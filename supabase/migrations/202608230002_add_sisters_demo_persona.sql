-- Presentation-only Sisters demo persona. Canonical organization and member
-- records remain unchanged; authorization continues to use access_role.

alter table public.app_user_access
  add column if not exists persona_code text not null default 'standard';

alter table public.app_user_access
  drop constraint if exists app_user_access_persona_code_check;
alter table public.app_user_access
  add constraint app_user_access_persona_code_check
  check (persona_code in ('standard', 'sisters'));

create table if not exists public.demo_persona_identities (
  persona_code text primary key,
  congregation_name text not null,
  abbreviation text not null,
  province_name text not null,
  motto text not null,
  active boolean not null default true
);

create table if not exists public.demo_persona_member_aliases (
  persona_code text not null references public.demo_persona_identities(persona_code) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  display_name text not null,
  ecclesiastical_title text not null default 'Sr.',
  photo_path text,
  role_display_override text,
  active boolean not null default true,
  primary key (persona_code, member_id)
);

insert into public.demo_persona_identities (
  persona_code, congregation_name, abbreviation, province_name, motto, active
) values (
  'sisters', 'Sisters of Our Lady of Communion', 'SOLC', 'Indian Province',
  'In Communion for Mission', true
) on conflict (persona_code) do update set
  congregation_name = excluded.congregation_name,
  abbreviation = excluded.abbreviation,
  province_name = excluded.province_name,
  motto = excluded.motto,
  active = excluded.active;

insert into public.demo_persona_member_aliases (
  persona_code, member_id, display_name, ecclesiastical_title, photo_path, active
)
select
  'sisters', member.id,
  case member.display_name
    when 'Thomas Mathew' then 'Teresa Mathew'
    when 'John Kuriakose' then 'Maria Kuriakose'
    when 'Dominic Kurian' then 'Dominic Mary'
    when 'Paul Sebastian' then 'Pauline Sebastian'
    when 'Francis Thomas' then 'Frances Thomas'
    when 'Sebastian Fernandes' then 'Sebastiana Fernandes'
    when 'Felix Xalxo' then 'Felicia Xalxo'
    when 'Roy Noronha' then 'Rose Noronha'
    when 'Anthony Minz' then 'Anitha Minz'
    when 'Joseph Kochuparambil' then 'Josephine Kochuparambil'
    when 'Augustine Palackal' then 'Augusta Palackal'
    when 'Joseph Vadakkel' then 'Josephine Vadakkel'
    when 'Thomas Kottaram' then 'Thomasina Kottaram'
    when 'Paul Thekkekara' then 'Pauline Thekkekara'
    when 'George Mundackal' then 'Georgina Mundackal'
    when 'Albert Kindo' then 'Alberta Kindo'
    when 'Thomas Kochupurackal' then 'Theresa Kochupurackal'
    when 'George Nedumkallel' then 'Georgia Nedumkallel'
    else 'Maria ' || coalesce(
      nullif(regexp_replace(member.display_name, '^.*\s+', ''), ''),
      member.display_name
    )
  end,
  'Sr.', null, true
from public.members member
on conflict (persona_code, member_id) do nothing;

create or replace function public.current_demo_persona()
returns text language sql stable security definer set search_path = public
as $$
  select coalesce((
    select access.persona_code from public.app_user_access access
    where access.auth_user_id = auth.uid() and access.active
    limit 1
  ), 'standard');
$$;

alter table public.demo_persona_identities enable row level security;
alter table public.demo_persona_member_aliases enable row level security;

drop policy if exists persona_identity_read_own on public.demo_persona_identities;
create policy persona_identity_read_own on public.demo_persona_identities
for select to authenticated
using (active and persona_code = public.current_demo_persona());

drop policy if exists persona_member_alias_read_own on public.demo_persona_member_aliases;
create policy persona_member_alias_read_own on public.demo_persona_member_aliases
for select to authenticated
using (active and persona_code = public.current_demo_persona());

revoke all on public.demo_persona_identities, public.demo_persona_member_aliases from public, anon;
grant select on public.demo_persona_identities, public.demo_persona_member_aliases to authenticated;
revoke all on function public.current_demo_persona() from public, anon;
grant execute on function public.current_demo_persona() to authenticated;

-- Map only an already-created Auth user; this migration never creates one.
insert into public.app_user_access (
  auth_user_id, access_role, member_id, persona_code, active
)
select auth_user.id, 'provincial', null, 'sisters', true
from auth.users auth_user
where lower(auth_user.email) = 'sister@communio.com'
on conflict (auth_user_id) do update set
  access_role = 'provincial', member_id = null,
  persona_code = 'sisters', active = true;

comment on table public.demo_persona_member_aliases is
  'Presentation-only member aliases. Sisters photos belong under member-photos/sisters-demo/.';
