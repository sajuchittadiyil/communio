-- Member-visible annual celebrations. This projection intentionally omits
-- birth years, ages, contacts, notes, locations and all personnel history.
create or replace view public.v_member_celebrations_safe
with (security_barrier = true)
as
with source_dates as (
  select
    directory.member_id,
    directory.religious_id,
    directory.display_name,
    directory.photo_url,
    'birthday'::text as celebration_type,
    extract(month from member.date_of_birth)::smallint as celebration_month,
    extract(day from member.date_of_birth)::smallint as celebration_day,
    null::integer as source_year
  from public.v_member_directory_safe directory
  join public.members member on member.id = directory.member_id
  where member.date_of_birth is not null

  union all

  select
    directory.member_id,
    directory.religious_id,
    directory.display_name,
    directory.photo_url,
    'feast_day'::text,
    extract(month from feast.next_feast_date)::smallint,
    extract(day from feast.next_feast_date)::smallint,
    null::integer
  from public.v_member_directory_safe directory
  join public.v_demo_upcoming_feast_days feast
    on feast.member_id = directory.member_id
  where feast.next_feast_date is not null

  union all

  select
    directory.member_id,
    directory.religious_id,
    directory.display_name,
    directory.photo_url,
    case regexp_replace(lower(vocation.event_type_code), '[^a-z0-9]+', '_', 'g')
      when 'first_profession' then 'first_profession'
      when 'perpetual_profession' then 'perpetual_profession'
      when 'final_profession' then 'perpetual_profession'
      when 'ordination' then 'ordination'
      when 'priestly_ordination' then 'ordination'
    end,
    extract(month from vocation.event_date)::smallint,
    extract(day from vocation.event_date)::smallint,
    extract(year from vocation.event_date)::integer
  from public.v_member_directory_safe directory
  join public.member_vocation_events vocation
    on vocation.member_id = directory.member_id
  where vocation.event_date is not null
    and regexp_replace(lower(vocation.event_type_code), '[^a-z0-9]+', '_', 'g')
      in (
        'first_profession',
        'perpetual_profession',
        'final_profession',
        'ordination',
        'priestly_ordination'
      )
), target_years as (
  select
    source.*,
    case
      when (source.celebration_month, source.celebration_day) >=
           (extract(month from current_date), extract(day from current_date))
        then extract(year from current_date)::integer
      else extract(year from current_date)::integer + 1
    end as target_year
  from source_dates source
), next_dates as (
  select
    target.*,
    make_date(
      target.target_year,
      target.celebration_month,
      least(
        target.celebration_day,
        extract(
          day from (
            make_date(target.target_year, target.celebration_month, 1)
            + interval '1 month - 1 day'
          )
        )::integer
      )
    ) as next_celebration_date
  from target_years target
)
select
  member_id,
  religious_id,
  display_name,
  photo_url,
  celebration_type,
  celebration_month,
  celebration_day,
  source_year,
  next_celebration_date
from next_dates;

revoke all on public.v_member_celebrations_safe from public, anon;
grant select on public.v_member_celebrations_safe to authenticated;

comment on view public.v_member_celebrations_safe is
  'Member-safe annual celebrations without birth years, ages, contacts or private personnel details.';
