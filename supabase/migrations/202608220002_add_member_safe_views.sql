-- Purpose-built, column-limited MEMBER read models. These views deliberately
-- expose no birth, origin, family, contact, leave, document, or governance data.
create or replace view public.v_member_directory_safe
with (security_barrier = true)
as
select
  member.id as member_id,
  member.religious_id,
  member.display_name,
  member.ecclesiastical_title_code,
  member.photo_url,
  member.member_status_code,
  member.canonical_status_code,
  community.name as community_name,
  community_assignment.responsibility_code as community_responsibility_code,
  ministry.name as ministry_name,
  ministry_assignment.responsibility_code as ministry_responsibility_code
from public.members member
left join lateral (
  select assignment.community_id, assignment.responsibility_code
  from public.member_community_assignments assignment
  where assignment.member_id = member.id
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
  order by assignment.from_date desc
  limit 1
) community_assignment on true
left join public.communities community
  on community.id = community_assignment.community_id
left join lateral (
  select assignment.ministry_id, assignment.responsibility_code
  from public.member_ministry_assignments assignment
  where assignment.member_id = member.id
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
  order by assignment.from_date desc
  limit 1
) ministry_assignment on true
left join public.ministries ministry
  on ministry.id = ministry_assignment.ministry_id
where member.active
  and public.current_access_role() in ('member', 'provincial');

revoke all on public.v_member_directory_safe from public, anon;
grant select on public.v_member_directory_safe to authenticated;

create or replace view public.v_member_province_snapshot
with (security_barrier = true)
as
select
  (select count(*)::integer from public.members where active) as active_members,
  (select count(*)::integer from public.communities where active) as active_communities,
  (select count(*)::integer from public.ministries where active) as active_ministries
where public.current_access_role() in ('member', 'provincial');

revoke all on public.v_member_province_snapshot from public, anon;
grant select on public.v_member_province_snapshot to authenticated;

comment on view public.v_member_directory_safe is
  'Column-limited MEMBER directory. Excludes private personal, family, contact, leave, document, and governance fields.';
comment on view public.v_member_province_snapshot is
  'Member-safe institutional aggregates. Formation and Provincial office metrics are intentionally absent.';
