-- Keep the Missionaries of St. Antony / Indian Province demo internally
-- consistent. Legacy cover_image_path values deliberately remain unchanged:
-- they are storage object identifiers, not user-facing identity labels.

update public.communities
set name = replace(
  replace(name, 'Chaminade', 'St. Antony'),
  'Marianist', 'St. Antonia''s'
),
updated_at = now()
where name ilike any (array['%chaminade%', '%marianist%']);

update public.ministries
set name = replace(
  replace(name, 'Chaminade', 'St. Antony'),
  'Marianist', 'St. Antonia''s'
),
updated_at = now()
where name ilike any (array['%chaminade%', '%marianist%']);

update public.member_community_assignments
set remarks = replace(
  replace(remarks, 'Chaminade', 'St. Antony'),
  'Marianist', 'St. Antonia''s'
)
where remarks ilike any (array['%chaminade%', '%marianist%']);

update public.member_qualifications
set institution = replace(
  replace(institution, 'Chaminade', 'St. Antony'),
  'Marianist', 'St. Antonia''s'
)
where institution ilike any (array['%chaminade%', '%marianist%']);

update public.member_vocation_events
set remarks = replace(
  replace(remarks, 'Chaminade', 'St. Antony'),
  'Marianist', 'St. Antonia''s'
)
where remarks ilike any (array['%chaminade%', '%marianist%']);

update public.ministry_operational_profiles
set head_display_name = replace(
  replace(head_display_name, 'Chaminade', 'St. Antony'),
  'Marianist', 'St. Antonia''s'
),
updated_at = now()
where head_display_name ilike any (array['%chaminade%', '%marianist%']);
