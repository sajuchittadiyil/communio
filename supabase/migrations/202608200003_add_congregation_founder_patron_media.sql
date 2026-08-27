alter table public.congregations
  add column if not exists founder_image_url text,
  add column if not exists patron_saint_name text,
  add column if not exists patron_saint_image_url text;

update public.congregations
set patron_saint_name = coalesce(nullif(patron_saint_name, ''), 'St. Antony'),
    updated_at = now()
where id = '10000000-0000-4000-8000-000000000001';

comment on column public.congregations.founder_image_url is
  'Optional founder image URL; null when no approved historical portrait is available.';
comment on column public.congregations.patron_saint_name is
  'Optional patron saint display name.';
comment on column public.congregations.patron_saint_image_url is
  'Optional approved patron saint image URL.';
