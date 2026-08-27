-- COMMUNITY SUPERIOR = MEMBER-safe Province access plus server-resolved
-- management visibility for the one community currently led by the caller.

alter table public.app_user_access drop constraint if exists app_user_access_access_role_check;
alter table public.app_user_access add constraint app_user_access_access_role_check
  check (access_role in ('provincial', 'community_superior', 'member'));
alter table public.app_user_access drop constraint if exists member_role_requires_member;
alter table public.app_user_access add constraint member_role_requires_member check (
  access_role not in ('member', 'community_superior') or member_id is not null
);

create or replace function public.current_application_access_role()
returns text language sql stable security definer set search_path = public as $$
  select access_role from public.app_user_access
  where auth_user_id = auth.uid() and active
$$;

-- Existing MEMBER-safe views continue to work without broadening their shape.
-- Enhanced policies use current_application_access_role() instead.
create or replace function public.current_access_role()
returns text language sql stable security definer set search_path = public as $$
  select case when access_role = 'community_superior' then 'member' else access_role end
  from public.app_user_access where auth_user_id = auth.uid() and active
$$;

create or replace function public.current_managed_community_id()
returns uuid language sql stable security definer set search_path = public as $$
  select assignment.community_id
  from public.app_user_access access
  join public.member_community_assignments assignment on assignment.member_id = access.member_id
  where access.auth_user_id = auth.uid() and access.active
    and access.access_role = 'community_superior'
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and lower(assignment.responsibility_code) in ('community_superior', 'superior')
  order by assignment.from_date desc limit 1
$$;

create or replace function public.get_community_superior_context()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'member_id', member.id, 'religious_id', member.religious_id,
    'display_name', member.display_name, 'community_id', community.id,
    'community_code', coalesce(to_jsonb(community)->>'code', to_jsonb(community)->>'community_code'),
    'community_name', community.name, 'responsibility_code', assignment.responsibility_code,
    'from_date', assignment.from_date
  )
  from public.app_user_access access
  join public.members member on member.id = access.member_id and member.active
  join public.member_community_assignments assignment on assignment.member_id = member.id
  join public.communities community on community.id = assignment.community_id and community.active
  where access.auth_user_id = auth.uid() and access.active
    and access.access_role = 'community_superior'
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and lower(assignment.responsibility_code) in ('community_superior', 'superior')
  order by assignment.from_date desc limit 1
$$;

create or replace view public.v_community_superior_residents_safe
with (security_barrier = true) as
select resident.community_id, resident.member_id, resident.religious_id,
  resident.display_name, resident.ecclesiastical_title_code, resident.photo_url,
  resident.member_status_code, resident.community_responsibility_code,
  resident.ministry_name, resident.ministry_responsibility_code,
  contact.mobile, contact.whatsapp, contact.official_email,
  to_jsonb(member)->>'date_of_birth' as date_of_birth,
  to_jsonb(member)->>'feast_day' as feast_day,
  to_jsonb(member)->>'feast_month' as feast_month
from public.v_member_community_residents_safe resident
join public.members member on member.id = resident.member_id
left join public.v_demo_member_public_contacts contact on contact.member_id = resident.member_id
where resident.community_id = public.current_managed_community_id()
  and public.current_application_access_role() = 'community_superior';

revoke all on function public.current_application_access_role(), public.current_managed_community_id(), public.get_community_superior_context() from public, anon;
grant execute on function public.current_application_access_role(), public.current_managed_community_id(), public.get_community_superior_context() to authenticated;
revoke all on public.v_community_superior_residents_safe from public, anon;
grant select on public.v_community_superior_residents_safe to authenticated;

create or replace function public.get_community_superior_resident_profile_safe(target_member_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select public.get_other_member_profile_safe(target_member_id) || jsonb_build_object(
    'date_of_birth', to_jsonb(member)->>'date_of_birth',
    'feast_day', to_jsonb(member)->>'feast_day',
    'feast_month', to_jsonb(member)->>'feast_month'
  )
  from public.members member
  join public.member_community_assignments assignment on assignment.member_id = member.id
  where member.id = target_member_id
    and assignment.community_id = public.current_managed_community_id()
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and public.current_application_access_role() = 'community_superior'
  limit 1
$$;

revoke all on function public.get_community_superior_resident_profile_safe(uuid) from public, anon;
grant execute on function public.get_community_superior_resident_profile_safe(uuid) to authenticated;

drop policy if exists province_documents_community_superior_read on public.province_documents;
create policy province_documents_community_superior_read on public.province_documents
  for select to authenticated using (
    public.current_application_access_role() = 'community_superior'
    and (
      visibility_code = 'province_members'
      or (
        visibility_code = 'community_leadership'
        and related_entity_type = 'community'
        and related_entity_id in (
          public.current_managed_community_id()::text,
          (select coalesce(to_jsonb(c)->>'code', to_jsonb(c)->>'community_code')
           from public.communities c where c.id = public.current_managed_community_id())
        )
      )
    )
  );

comment on function public.current_managed_community_id() is
  'Returns one community only after validating the caller current Superior assignment; accepts no client community ID.';

-- Manual demo setup after verifying the auth UUID. This migration deliberately
-- does not create an Auth user or guess Felix Xalxo identity values:
-- update public.app_user_access set access_role = 'community_superior'
-- where auth_user_id = '<approved superior@communio.com auth UUID>'
--   and member_id = '<verified Felix Xalxo member UUID>';
