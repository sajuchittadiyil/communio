-- Restore caller-safe Member product reads after legacy reporting views became
-- security-invoker. Both functions retain the authenticated caller's identity
-- for role/scope predicates and expose only existing safe profile fields.

create or replace function public.get_member_self_origin_safe()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'native_place', coalesce(
      to_jsonb(origin)->>'native_place',
      to_jsonb(origin)->>'city'
    ),
    'home_parish', to_jsonb(origin)->>'home_parish',
    'diocese', to_jsonb(origin)->>'diocese',
    'district', to_jsonb(origin)->>'district',
    'state', to_jsonb(origin)->>'state',
    'country', to_jsonb(origin)->>'country'
  )
  from public.app_user_access access
  join public.member_native_details origin on origin.member_id = access.member_id
  join public.members member on member.id = access.member_id and member.active
  where access.auth_user_id = auth.uid()
    and access.active
    and access.access_role in ('member', 'community_superior')
  limit 1
$$;

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
  if caller_role = 'community_superior' then
    return query
      select to_jsonb(ministry)
      from public.v_community_superior_ministries_safe ministry
      order by ministry.ministry_name;
  elsif caller_role = 'member' then
    return query
      select to_jsonb(ministry)
      from public.v_member_ministries_safe ministry
      order by ministry.ministry_name;
  end if;

  raise exception 'Member ministry access required' using errcode = '42501';
end
$$;

revoke all on function public.get_member_self_origin_safe() from public, anon;
revoke all on function public.get_member_ministries_safe() from public, anon;
grant execute on function public.get_member_self_origin_safe() to authenticated;
grant execute on function public.get_member_ministries_safe() to authenticated;

comment on function public.get_member_self_origin_safe() is
  'Caller-bound origin facts for the signed-in Member or Community Superior self profile.';
comment on function public.get_member_ministries_safe() is
  'Role-gated safe ministry directory; Member receives Province-safe listings and Community Superior remains managed-community scoped.';

