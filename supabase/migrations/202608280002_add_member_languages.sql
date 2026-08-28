-- Structured current language capabilities for member profiles and reporting.

create table public.member_languages (
  id uuid primary key default gen_random_uuid(),
  congregation_id uuid not null references public.congregations(id) on delete restrict,
  province_id uuid not null references public.provinces(id) on delete restrict,
  member_id uuid not null references public.members(id) on delete restrict,
  language_code text,
  language_name text not null,
  proficiency_level_code text,
  can_speak boolean,
  can_read boolean,
  can_write boolean,
  is_primary boolean not null default false,
  is_native boolean,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_languages_name_present check (btrim(language_name) <> ''),
  constraint member_languages_code_format check (
    language_code is null or language_code ~ '^[a-z]{2,3}$'
  ),
  constraint member_languages_proficiency check (
    proficiency_level_code is null or proficiency_level_code in (
      'BASIC', 'WORKING', 'PROFICIENT', 'FLUENT', 'NATIVE'
    )
  )
);

create unique index member_languages_member_name_unique
  on public.member_languages (member_id, lower(btrim(language_name)));
create unique index member_languages_one_primary_per_member
  on public.member_languages (member_id) where is_primary;
create index member_languages_scope_idx
  on public.member_languages (congregation_id, province_id, member_id);
create index member_languages_language_idx
  on public.member_languages (lower(btrim(language_name)), can_speak);

create trigger member_languages_set_updated_at before update on public.member_languages
for each row execute function public.set_updated_at();

alter table public.member_languages enable row level security;
revoke all on public.member_languages from public, anon, authenticated;
grant select on public.member_languages to authenticated;
grant all on public.member_languages to service_role;

create policy member_languages_scoped_read on public.member_languages
for select to authenticated using (
  exists (
    select 1
    from public.app_user_access access
    where access.auth_user_id = auth.uid()
      and access.active
      and access.access_role in ('provincial', 'community_superior', 'member')
      and access.congregation_id = member_languages.congregation_id
      and access.province_id = member_languages.province_id
  )
);

create or replace view public.v_member_languages
with (security_invoker = true) as
select
  language.member_id,
  member.religious_id,
  member.display_name,
  language.language_name,
  language.language_code,
  language.proficiency_level_code,
  language.can_speak,
  language.can_read,
  language.can_write,
  language.is_primary,
  language.is_native
from public.member_languages language
join public.members member on member.id = language.member_id
where member.active;

revoke all on public.v_member_languages from public, anon;
grant select on public.v_member_languages to authenticated;

-- Deliberate fictional demo assignments. They are not derived from names,
-- geography, education, ethnicity, or another inferred attribute.
with scope as (
  select province.congregation_id, province.id as province_id
  from public.provinces province
  where province.active
  order by province.created_at, province.id
  limit 1
), assignments(display_name, language_code, language_name, proficiency, can_speak, can_read, can_write, is_primary, is_native) as (
  values
    ('Joseph Varghese', 'ml', 'Malayalam', 'NATIVE', true, true, true, true, true),
    ('Joseph Varghese', 'en', 'English', 'FLUENT', true, true, true, false, false),
    ('Joseph Varghese', 'hi', 'Hindi', 'WORKING', true, true, false, false, false),
    ('Thomas Mathew', 'ml', 'Malayalam', 'NATIVE', true, true, true, true, true),
    ('Thomas Mathew', 'en', 'English', 'PROFICIENT', true, true, true, false, false),
    ('Mathew Joseph', 'ml', 'Malayalam', 'NATIVE', true, true, true, true, true),
    ('Mathew Joseph', 'ta', 'Tamil', 'WORKING', true, false, false, false, false),
    ('Francis Thomas', 'en', 'English', 'FLUENT', true, true, true, false, false),
    ('Francis Thomas', 'kn', 'Kannada', 'NATIVE', true, true, true, true, true),
    ('John Kuriakose', 'ml', 'Malayalam', 'NATIVE', true, true, true, true, true),
    ('John Kuriakose', 'te', 'Telugu', 'WORKING', true, true, false, false, false),
    ('Roy Noronha', 'en', 'English', 'FLUENT', true, true, true, false, false),
    ('Roy Noronha', 'kn', 'Kannada', 'PROFICIENT', true, true, true, true, false),
    ('Felix Xalxo', 'hi', 'Hindi', 'FLUENT', true, true, true, false, false),
    ('Felix Xalxo', 'en', 'English', 'PROFICIENT', true, true, true, false, false),
    ('David Pradhan', 'or', 'Odia', 'NATIVE', true, true, true, true, true),
    ('David Pradhan', 'hi', 'Hindi', 'FLUENT', true, true, true, false, false),
    ('David Pradhan', 'en', 'English', 'PROFICIENT', true, true, true, false, false),
    ('Akhil Biswas', 'bn', 'Bengali', 'NATIVE', true, true, true, true, true),
    ('Akhil Biswas', 'en', 'English', null, true, true, null, false, false)
)
insert into public.member_languages (
  congregation_id, province_id, member_id, language_code, language_name,
  proficiency_level_code, can_speak, can_read, can_write, is_primary, is_native
)
select
  scope.congregation_id, scope.province_id, member.id, assignment.language_code,
  assignment.language_name, assignment.proficiency, assignment.can_speak,
  assignment.can_read, assignment.can_write, assignment.is_primary, assignment.is_native
from assignments assignment
join public.members member on lower(member.display_name) = lower(assignment.display_name)
cross join scope
where member.active
on conflict do nothing;

comment on table public.member_languages is
  'Current explicit member language capabilities; no geographic or biographical inference.';
comment on view public.v_member_languages is
  'Security-invoker reporting source limited to safe identity and explicit language capability fields.';
