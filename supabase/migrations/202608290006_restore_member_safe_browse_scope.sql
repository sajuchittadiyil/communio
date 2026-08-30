-- Restore Province-wide member-safe browsing independently of a caller's
-- management scope. Anonymous legacy-view protection remains unchanged.

create or replace function public.get_member_ministries_safe()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  caller_role text := public.current_application_access_role();
begin
  if caller_role in ('member', 'community_superior') then
    return query
      select to_jsonb(ministry)
      from public.v_member_ministries_safe ministry
      order by ministry.ministry_name;
  end if;

  raise exception 'Member ministry access required' using errcode = '42501';
end
$$;

-- Keep the established safe profile payload, but replace the former postal
-- address projection with non-sensitive origin facts already modeled in
-- member_native_details.
create or replace function public.get_other_member_profile_browse_safe(
  target_member_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select (public.get_other_member_profile_safe(target_member_id)
      - 'address' - 'city')
    || jsonb_build_object(
      'native_place', coalesce(
        to_jsonb(origin)->>'native_place',
        to_jsonb(origin)->>'city'
      ),
      'home_parish', coalesce(
        to_jsonb(origin)->>'home_parish',
        to_jsonb(origin)->>'native_parish'
      ),
      'diocese', coalesce(
        to_jsonb(origin)->>'diocese',
        to_jsonb(origin)->>'native_diocese'
      ),
      'district', to_jsonb(origin)->>'district',
      'state', to_jsonb(origin)->>'state',
      'country', to_jsonb(origin)->>'country'
    )
  from public.members member
  left join public.member_native_details origin on origin.member_id = member.id
  where member.id = target_member_id
    and member.active
    and public.current_application_access_role()
      in ('member', 'community_superior', 'provincial')
  limit 1
$$;

create or replace function
  public.get_community_superior_resident_profile_browse_safe(
    target_member_id uuid
  )
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.get_community_superior_resident_profile_safe(target_member_id)
    || public.get_other_member_profile_browse_safe(target_member_id)
  where public.current_application_access_role() = 'community_superior'
    and exists (
      select 1
      from public.member_community_assignments assignment
      where assignment.member_id = target_member_id
        and assignment.community_id = public.current_managed_community_id()
        and assignment.from_date <= current_date
        and (assignment.to_date is null or assignment.to_date >= current_date)
    )
$$;

revoke all on function public.get_member_ministries_safe() from public, anon;
revoke all on function
  public.get_other_member_profile_browse_safe(uuid)
from public, anon;
revoke all on function
  public.get_community_superior_resident_profile_browse_safe(uuid)
from public, anon;
grant execute on function public.get_member_ministries_safe() to authenticated;
grant execute on function
  public.get_other_member_profile_browse_safe(uuid)
to authenticated;
grant execute on function
  public.get_community_superior_resident_profile_browse_safe(uuid)
to authenticated;

comment on function public.get_member_ministries_safe() is
  'Province-wide member-safe ministry browse source for Member and Community Superior callers; grants no management capability.';
comment on function public.get_other_member_profile_browse_safe(uuid) is
  'Member-safe Religious profile with non-sensitive origin facts and no private home or family address.';
comment on function
  public.get_community_superior_resident_profile_browse_safe(uuid) is
  'Managed-community resident profile enriched with member-safe origin facts; caller scope remains server-bound.';
