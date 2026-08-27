-- Structured congregation/province identity for the Communio demo.
-- Existing members, communities, ministries, and Province office appointments
-- remain unchanged; tenant foreign keys can be added in a later migration.

create table if not exists public.congregations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  abbreviation text,
  motto text,
  charism text,
  founder text,
  founded_year smallint check (founded_year between 1000 and 9999),
  generalate_city text,
  generalate_address text,
  country text,
  email text,
  phone text,
  website text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.provinces (
  id uuid primary key default gen_random_uuid(),
  congregation_id uuid not null references public.congregations(id) on delete restrict,
  code text not null,
  name text not null,
  motto text,
  headquarters text,
  address text,
  country text,
  email text,
  phone text,
  website text,
  established_date date,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (congregation_id, code)
);

create table if not exists public.congregation_leadership (
  id uuid primary key default gen_random_uuid(),
  congregation_id uuid not null references public.congregations(id) on delete restrict,
  display_name text not null,
  title text,
  post_nominal text,
  role_code text not null,
  role_name text not null,
  country_of_origin text,
  administration_city text,
  email text,
  phone text,
  photo_url text,
  display_order smallint not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (congregation_id, role_code, display_order)
);

alter table public.congregations enable row level security;
alter table public.provinces enable row level security;
alter table public.congregation_leadership enable row level security;

revoke all on public.congregations from anon, authenticated;
revoke all on public.provinces from anon, authenticated;
revoke all on public.congregation_leadership from anon, authenticated;
grant select on public.congregations to authenticated;
grant select on public.provinces to authenticated;
grant select on public.congregation_leadership to authenticated;
grant all on public.congregations to service_role;
grant all on public.provinces to service_role;
grant all on public.congregation_leadership to service_role;

drop policy if exists congregation_identity_authenticated on public.congregations;
create policy congregation_identity_authenticated on public.congregations
  for select to authenticated using (active);

drop policy if exists province_identity_authenticated on public.provinces;
create policy province_identity_authenticated on public.provinces
  for select to authenticated using (active);

drop policy if exists congregation_leadership_authenticated on public.congregation_leadership;
create policy congregation_leadership_authenticated on public.congregation_leadership
  for select to authenticated using (active);

insert into public.congregations (
  id, code, name, abbreviation, motto, charism, founder, founded_year,
  generalate_city, generalate_address, country, email, phone, website, active
) values (
  '10000000-0000-4000-8000-000000000001',
  'MSA',
  'Missionaries of St. Antony',
  'MSA',
  'In Communion for Mission',
  'To witness to the Gospel through community life, education, pastoral ministry, formation, social service, and compassionate service to people in need.',
  'Fr. Antony Maria De Rossi',
  1938,
  'Rome',
  E'Via Sant’Antonio 48\n00165 Rome\nItaly',
  'Italy',
  'generalate@missionariesofstantony.org',
  '+39 06 5550 1840',
  'https://www.missionariesofstantony.org',
  true
) on conflict (id) do update set
  code = excluded.code,
  name = excluded.name,
  abbreviation = excluded.abbreviation,
  motto = excluded.motto,
  charism = excluded.charism,
  founder = excluded.founder,
  founded_year = excluded.founded_year,
  generalate_city = excluded.generalate_city,
  generalate_address = excluded.generalate_address,
  country = excluded.country,
  email = excluded.email,
  phone = excluded.phone,
  website = excluded.website,
  active = excluded.active,
  updated_at = now();

insert into public.provinces (
  id, congregation_id, code, name, motto, headquarters, address, country, active
) values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'IND',
  'Indian Province',
  'Together in Faith, United in Mission',
  'Provincial House, Bengaluru',
  E'Bengaluru Urban\nKarnataka\nIndia',
  'India',
  true
) on conflict (id) do update set
  congregation_id = excluded.congregation_id,
  code = excluded.code,
  name = excluded.name,
  motto = excluded.motto,
  headquarters = excluded.headquarters,
  address = excluded.address,
  country = excluded.country,
  active = excluded.active,
  updated_at = now();

insert into public.congregation_leadership (
  id, congregation_id, display_name, title, post_nominal, role_code,
  role_name, country_of_origin, administration_city, email, phone,
  display_order, active
) values
  ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Fr. Michael D’Souza, MSA', 'Fr.', 'MSA', 'superior_general', 'Superior General', 'India', 'Rome', 'superiorgeneral@missionariesofstantony.org', '+39 06 5550 1841', 1, true),
  ('30000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Fr. Paolo Ricci, MSA', 'Fr.', 'MSA', 'assistant_superior_general', 'Assistant Superior General', 'Italy', 'Rome', 'assistantgeneral@missionariesofstantony.org', '+39 06 5550 1842', 2, true),
  ('30000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Fr. Daniel Okoro, MSA', 'Fr.', 'MSA', 'general_treasurer', 'General Treasurer', 'Nigeria', 'Rome', 'treasurer@missionariesofstantony.org', '+39 06 5550 1843', 3, true),
  ('30000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'Fr. Carlos Mendoza, MSA', 'Fr.', 'MSA', 'general_councillor', 'General Councillor', 'Mexico', 'Rome', 'councillor1@missionariesofstantony.org', '+39 06 5550 1844', 4, true),
  ('30000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'Fr. Jean-Baptiste Moreau, MSA', 'Fr.', 'MSA', 'general_councillor', 'General Councillor', 'France', 'Rome', 'councillor2@missionariesofstantony.org', '+39 06 5550 1845', 5, true)
on conflict (id) do update set
  congregation_id = excluded.congregation_id,
  display_name = excluded.display_name,
  title = excluded.title,
  post_nominal = excluded.post_nominal,
  role_code = excluded.role_code,
  role_name = excluded.role_name,
  country_of_origin = excluded.country_of_origin,
  administration_city = excluded.administration_city,
  email = excluded.email,
  phone = excluded.phone,
  display_order = excluded.display_order,
  active = excluded.active,
  updated_at = now();

comment on table public.congregations is
  'Top-level congregation identity, ready to own multiple provinces.';
comment on table public.provinces is
  'Province identity linked to its congregation; existing domain tables remain unmigrated.';
comment on table public.congregation_leadership is
  'Structured General Administration records for future deterministic reporting and Ask Communio support.';
