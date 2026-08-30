-- Replace the Member/Superior ministry browse RPC with an explicit,
-- column-limited base-table projection. This deliberately does not read any
-- legacy reporting view. Association fields remain null when no canonical
-- relationship exists on ministries; the directory and profile stay usable.

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
  if caller_role not in ('member', 'community_superior') then
    raise exception 'Member ministry access required' using errcode = '42501';
  end if;

  return query
    select jsonb_build_object(
      'ministry_id', ministry.id,
      'ministry_code', coalesce(
        to_jsonb(ministry)->>'code',
        to_jsonb(ministry)->>'ministry_code'
      ),
      'ministry_name', ministry.name,
      'ministry_type', coalesce(
        to_jsonb(ministry)->>'ministry_type_code',
        to_jsonb(ministry)->>'type_code',
        to_jsonb(ministry)->>'type'
      ),
      'operational_status', coalesce(
        to_jsonb(ministry)->>'operational_status',
        case when ministry.active then 'active' else 'inactive' end
      ),
      'city', coalesce(
        to_jsonb(ministry)->>'city',
        to_jsonb(ministry)->>'location_city'
      ),
      'district', to_jsonb(ministry)->>'district',
      'state', to_jsonb(ministry)->>'state',
      'country', to_jsonb(ministry)->>'country',
      'community_id', null,
      'community_name', null,
      'head_member_id', head.member_id,
      'head_display_name', head.display_name,
      'head_role', head.responsibility_code,
      'head_photo_url', head.photo_url,
      'student_count', to_jsonb(ministry)->>'student_count',
      'beneficiary_count', to_jsonb(ministry)->>'beneficiary_count',
      'staff_count', to_jsonb(ministry)->>'staff_count',
      'motto', to_jsonb(ministry)->>'motto',
      'mission_statement', to_jsonb(ministry)->>'mission_statement',
      'vision_statement', to_jsonb(ministry)->>'vision_statement',
      'patron_saint_name', to_jsonb(ministry)->>'patron_saint_name',
      'apostolic_focus', to_jsonb(ministry)->'apostolic_focus',
      'ministry_values', to_jsonb(ministry)->'ministry_values',
      'cover_image_path', to_jsonb(ministry)->>'cover_image_path'
    )
    from public.ministries ministry
    left join lateral (
      select member.id as member_id,
        member.display_name,
        assignment.responsibility_code,
        member.photo_url
      from public.member_ministry_assignments assignment
      join public.members member
        on member.id = assignment.member_id and member.active
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
    order by ministry.name;
end
$$;

revoke all on function public.get_member_ministries_safe() from public, anon;
grant execute on function public.get_member_ministries_safe() to authenticated;

comment on function public.get_member_ministries_safe() is
  'Caller-gated Member and Community Superior ministry browse projection using explicit base tables and no legacy reporting view.';

-- Normalize the schema variants already used by Communio's native-details
-- model. The base profile remains the single source for identity, vocation,
-- qualifications and assignment history.
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
        to_jsonb(origin)->>'place_of_origin',
        to_jsonb(origin)->>'home_town',
        to_jsonb(origin)->>'native_city',
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

revoke all on function
  public.get_other_member_profile_browse_safe(uuid)
from public, anon;
grant execute on function
  public.get_other_member_profile_browse_safe(uuid)
to authenticated;
