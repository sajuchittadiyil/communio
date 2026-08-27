-- Dedicated caller-authorized, column-limited sources for MEMBER community
-- browsing and deterministic Ask Communio facts. The views intentionally use
-- no movement, contact, document, governance, personnel, or financial tables.

create or replace view public.v_member_communities_safe
with (security_barrier = true)
as
select
  community.id as community_id,
  to_jsonb(community)->>'code' as code,
  community.name,
  coalesce(
    to_jsonb(community)->>'community_type_code',
    to_jsonb(community)->>'type_code',
    to_jsonb(community)->>'type'
  ) as community_type,
  to_jsonb(community)->>'community_category' as community_category,
  coalesce(to_jsonb(community)->>'city', to_jsonb(community)->>'location_city') as city,
  to_jsonb(community)->>'district' as district,
  to_jsonb(community)->>'state' as state,
  to_jsonb(community)->>'country' as country,
  community.active,
  coalesce(
    nullif(to_jsonb(community)->>'opened_on', '')::date,
    nullif(to_jsonb(community)->>'foundation_date', '')::date,
    nullif(to_jsonb(community)->>'established_on', '')::date
  ) as opened_on,
  to_jsonb(community)->>'cover_image_path' as cover_image_path,
  coalesce(residents.current_resident_count, 0)::integer as current_resident_count,
  coalesce(ministry_count.current_ministry_count, 0)::integer as ministry_count,
  superior.display_name as current_superior_display_name,
  superior.member_id as current_superior_member_id
from public.communities community
left join lateral (
  select count(*) as current_resident_count
  from public.member_community_assignments assignment
  where assignment.community_id = community.id
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
) residents on true
left join lateral (
  select count(*) as current_ministry_count
  from public.ministries ministry
  where (to_jsonb(ministry)->>'community_id')::uuid = community.id
    and ministry.active
) ministry_count on true
left join lateral (
  select member.id as member_id, member.display_name
  from public.member_community_assignments assignment
  join public.members member on member.id = assignment.member_id and member.active
  where assignment.community_id = community.id
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and lower(assignment.responsibility_code) in ('community_superior', 'superior')
  order by assignment.from_date desc
  limit 1
) superior on true
where community.active
  and public.current_access_role() in ('member', 'provincial');

create or replace view public.v_member_ministries_safe
with (security_barrier = true)
as
select
  ministry.id as ministry_id,
  coalesce(to_jsonb(ministry)->>'code', to_jsonb(ministry)->>'ministry_code') as ministry_code,
  ministry.name as ministry_name,
  coalesce(to_jsonb(ministry)->>'ministry_type_code', to_jsonb(ministry)->>'type_code', to_jsonb(ministry)->>'type') as ministry_type,
  coalesce(to_jsonb(ministry)->>'operational_status', case when ministry.active then 'active' else 'inactive' end) as operational_status,
  coalesce(to_jsonb(ministry)->>'city', to_jsonb(ministry)->>'location_city') as city,
  to_jsonb(ministry)->>'district' as district,
  to_jsonb(ministry)->>'state' as state,
  to_jsonb(ministry)->>'country' as country,
  community.id as community_id,
  community.name as community_name,
  head.member_id as head_member_id,
  head.display_name as head_display_name,
  head.responsibility_code as head_role,
  to_jsonb(ministry)->>'student_count' as student_count,
  to_jsonb(ministry)->>'beneficiary_count' as beneficiary_count,
  to_jsonb(ministry)->>'staff_count' as staff_count,
  to_jsonb(ministry)->>'motto' as motto,
  to_jsonb(ministry)->>'mission_statement' as mission_statement,
  to_jsonb(ministry)->>'vision_statement' as vision_statement,
  to_jsonb(ministry)->>'patron_saint_name' as patron_saint_name,
  to_jsonb(ministry)->'apostolic_focus' as apostolic_focus,
  to_jsonb(ministry)->'ministry_values' as ministry_values
from public.ministries ministry
left join public.communities community
  on community.id = nullif(to_jsonb(ministry)->>'community_id', '')::uuid
left join lateral (
  select member.id as member_id, member.display_name, assignment.responsibility_code
  from public.member_ministry_assignments assignment
  join public.members member on member.id = assignment.member_id and member.active
  where assignment.ministry_id = ministry.id
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and lower(assignment.responsibility_code) in (
      'principal', 'parish_priest', 'pastor', 'director', 'head',
      'novice_master', 'formation_director', 'vocation_promoter'
    )
  order by assignment.from_date desc
  limit 1
) head on true
where ministry.active
  and public.current_access_role() in ('member', 'provincial');

revoke all on public.v_member_communities_safe, public.v_member_ministries_safe
  from public, anon;
grant select on public.v_member_communities_safe, public.v_member_ministries_safe
  to authenticated;

comment on view public.v_member_communities_safe is
  'Active Province communities with current directory-safe counts and superior identity only.';
comment on view public.v_member_ministries_safe is
  'Active ministries with public profile facts and current directory-safe operational head only.';
