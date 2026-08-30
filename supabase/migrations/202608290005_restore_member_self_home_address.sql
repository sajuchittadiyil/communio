-- Restore the signed-in member's own home address fields omitted from the
-- caller-bound home-details response. No target member argument is accepted.

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
    'country', to_jsonb(origin)->>'country',
    'home_contacts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', to_jsonb(item)->>'name',
        'relationship', to_jsonb(item)->>'relationship',
        'address', coalesce(
          to_jsonb(item)->>'address',
          to_jsonb(item)->>'home_address',
          to_jsonb(item)->>'formatted_address'
        ),
        'phone', to_jsonb(item)->>'phone',
        'whatsapp', to_jsonb(item)->>'whatsapp',
        'email', to_jsonb(item)->>'email',
        'is_primary', to_jsonb(item)->>'is_primary',
        'is_next_of_kin', to_jsonb(item)->>'is_next_of_kin',
        'is_emergency_contact', to_jsonb(item)->>'is_emergency_contact'
      ))
      from public.member_home_contacts item
      where item.member_id = member.id
    ), '[]'::jsonb),
    'family', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', to_jsonb(item)->>'name',
        'relationship', to_jsonb(item)->>'relationship',
        'life_status', coalesce(
          to_jsonb(item)->>'life_status',
          to_jsonb(item)->>'life_status_code',
          to_jsonb(item)->>'status'
        ),
        'date_of_birth', to_jsonb(item)->>'date_of_birth',
        'date_of_death', to_jsonb(item)->>'date_of_death',
        'year_of_death', to_jsonb(item)->>'year_of_death',
        'phone', to_jsonb(item)->>'phone',
        'whatsapp', to_jsonb(item)->>'whatsapp',
        'email', to_jsonb(item)->>'email'
      ))
      from public.member_family item
      where item.member_id = member.id
    ), '[]'::jsonb)
  )
  from public.app_user_access access
  join public.members member on member.id = access.member_id and member.active
  left join public.member_native_details origin on origin.member_id = member.id
  where access.auth_user_id = auth.uid()
    and access.active
    and access.access_role in ('member', 'community_superior')
  limit 1
$$;

revoke all on function public.get_member_self_origin_safe() from public, anon;
grant execute on function public.get_member_self_origin_safe() to authenticated;

comment on function public.get_member_self_origin_safe() is
  'Caller-bound origin, home address/contact and family facts for the signed-in Member or Community Superior self profile.';
