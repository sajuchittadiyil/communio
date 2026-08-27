-- Use the existing operational ministry projection as the canonical
-- community/ministry relationship. The base ministries table deliberately has
-- no community_id column.
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
  superior.member_id as current_superior_member_id,
  superior.photo_url as current_superior_photo_url,
  accountant.member_id as current_accountant_member_id,
  accountant.display_name as current_accountant_display_name,
  accountant.photo_url as current_accountant_photo_url
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
  from public.v_demo_ministry_operational ministry
  where ministry.community_id = community.id
    and lower(ministry.operational_status) = 'active'
) ministry_count on true
left join lateral (
  select member.id as member_id, member.display_name, member.photo_url
  from public.member_community_assignments assignment
  join public.members member on member.id = assignment.member_id and member.active
  where assignment.community_id = community.id
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and lower(assignment.responsibility_code) in ('community_superior', 'superior')
  order by assignment.from_date desc
  limit 1
) superior on true
left join lateral (
  select member.id as member_id, member.display_name, member.photo_url
  from public.member_community_assignments assignment
  join public.members member on member.id = assignment.member_id and member.active
  where assignment.community_id = community.id
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and lower(assignment.responsibility_code) in (
      'community_accountant', 'community_bursar', 'accountant', 'bursar'
    )
  order by assignment.from_date desc
  limit 1
) accountant on true
where community.active
  and public.current_access_role() in ('member', 'provincial');

create or replace view public.v_member_ministries_safe
with (security_barrier = true)
as
select
  operational.ministry_id,
  operational.ministry_code,
  operational.ministry_name,
  operational.ministry_type,
  operational.operational_status,
  operational.location_city as city,
  operational.district,
  operational.state,
  to_jsonb(ministry)->>'country' as country,
  operational.community_id,
  operational.associated_community as community_name,
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
  to_jsonb(ministry)->'ministry_values' as ministry_values,
  to_jsonb(ministry)->>'cover_image_path' as cover_image_path,
  head.photo_url as head_photo_url
from public.v_demo_ministry_operational operational
join public.ministries ministry on ministry.id = operational.ministry_id
left join lateral (
  select member.id as member_id, member.display_name,
    assignment.responsibility_code, member.photo_url
  from public.member_ministry_assignments assignment
  join public.members member on member.id = assignment.member_id and member.active
  where assignment.ministry_id = operational.ministry_id
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

-- Enhanced data is caller-bound. Neither view accepts a community identifier.
create or replace view public.v_community_superior_community_safe
with (security_barrier = true)
as
select community.*
from public.v_member_communities_safe community
where community.community_id = public.current_managed_community_id()
  and public.current_application_access_role() = 'community_superior';

create or replace view public.v_community_superior_ministries_safe
with (security_barrier = true)
as
select ministry.*
from public.v_member_ministries_safe ministry
where ministry.community_id = public.current_managed_community_id()
  and public.current_application_access_role() = 'community_superior';

revoke all on public.v_member_communities_safe,
  public.v_member_ministries_safe,
  public.v_community_superior_community_safe,
  public.v_community_superior_ministries_safe
  from public, anon;
grant select on public.v_member_communities_safe,
  public.v_member_ministries_safe,
  public.v_community_superior_community_safe,
  public.v_community_superior_ministries_safe
  to authenticated;

comment on view public.v_community_superior_community_safe is
  'The authenticated Community Superior managed community, including safe cover and current leadership member photos.';
comment on view public.v_community_superior_ministries_safe is
  'Active ministries canonically linked to the authenticated Community Superior managed community.';
