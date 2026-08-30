-- Complete authenticated member-safe browse payloads after migration 007.
-- No private family/home-contact/document source is used.

create or replace function public.get_member_ministries_profile_safe()
returns setof jsonb
language sql
stable
security definer
set search_path = public
as $$
  select item || jsonb_build_object(
    'ministry_type', coalesce(
      item->>'ministry_type',
      to_jsonb(ministry)->>'ministry_type',
      to_jsonb(ministry)->>'ministry_type_code',
      to_jsonb(ministry)->>'type_code',
      to_jsonb(ministry)->>'type'
    )
  )
  from public.get_member_ministries_safe() item
  join public.ministries ministry
    on ministry.id = (item->>'ministry_id')::uuid
  order by item->>'ministry_name'
$$;

create or replace function public.get_member_communities_profile_safe()
returns setof jsonb
language sql
stable
security definer
set search_path = public
as $$
  select to_jsonb(directory) || jsonb_build_object(
    'description', coalesce(
      to_jsonb(community)->>'description',
      to_jsonb(community)->>'community_description',
      to_jsonb(community)->>'purpose'
    ),
    'patron_saint_name', to_jsonb(community)->>'patron_saint_name',
    'feast_day', to_jsonb(community)->>'feast_day',
    'feast_month', to_jsonb(community)->>'feast_month',
    'motto', to_jsonb(community)->>'motto',
    'mission_statement', coalesce(
      to_jsonb(community)->>'mission_statement',
      to_jsonb(community)->>'mission'
    ),
    'vision_statement', coalesce(
      to_jsonb(community)->>'vision_statement',
      to_jsonb(community)->>'vision'
    ),
    'apostolic_focus', coalesce(
      to_jsonb(community)->'apostolic_focus', '[]'::jsonb
    ),
    'community_values', coalesce(
      to_jsonb(community)->'community_values', '[]'::jsonb
    ),
    'founding_story', to_jsonb(community)->>'founding_story',
    'history_summary', to_jsonb(community)->>'history_summary',
    'phone', to_jsonb(community)->>'phone',
    'email', to_jsonb(community)->>'email'
  )
  from public.v_member_communities_safe directory
  join public.communities community on community.id = directory.community_id
  where public.current_application_access_role()
    in ('member', 'community_superior', 'provincial')
  order by directory.name
$$;

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
      'date_of_birth', to_jsonb(member)->>'date_of_birth',
      'birthplace', coalesce(
        to_jsonb(member)->>'birthplace',
        to_jsonb(origin)->>'birthplace',
        to_jsonb(origin)->>'place_of_birth'
      ),
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

revoke all on function public.get_member_ministries_profile_safe()
  from public, anon;
revoke all on function public.get_member_communities_profile_safe()
  from public, anon;
revoke all on function public.get_other_member_profile_browse_safe(uuid)
  from public, anon;
grant execute on function public.get_member_ministries_profile_safe()
  to authenticated;
grant execute on function public.get_member_communities_profile_safe()
  to authenticated;
grant execute on function public.get_other_member_profile_browse_safe(uuid)
  to authenticated;

