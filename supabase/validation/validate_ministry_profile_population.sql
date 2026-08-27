-- Read-only validation for the internal Communio demo Ministry Profiles.
select
  operational.ministry_code as code,
  operational.ministry_name as name,
  operational.ministry_type,
  ministry.patron_saint_name,
  ministry.feast_day,
  ministry.feast_month,
  ministry.motto,
  nullif(btrim(ministry.mission_statement), '') is not null as mission_present,
  nullif(btrim(ministry.vision_statement), '') is not null as vision_present,
  coalesce(cardinality(ministry.apostolic_focus), 0) as focus_count,
  coalesce(cardinality(ministry.ministry_values), 0) as values_count,
  nullif(btrim(ministry.founding_story), '') is not null as story_present,
  nullif(btrim(ministry.history_summary), '') is not null as history_present
from public.v_demo_ministry_operational as operational
join public.ministries as ministry on ministry.id = operational.ministry_id
where operational.ministry_code between 'MIN001' and 'MIN024'
order by operational.ministry_code;
