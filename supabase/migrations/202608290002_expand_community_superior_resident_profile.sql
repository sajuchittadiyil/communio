-- A Community Superior may view pastoral profile facts for current residents
-- of the one community resolved from the caller's own active assignment.
-- Ordinary MEMBER profiles remain unchanged and restricted documents, notes,
-- credentials, wills, vault/safe data, leave and Province governance are absent.

create or replace function public.get_community_superior_resident_profile_safe(
  target_member_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.get_other_member_profile_safe(target_member_id)
    || jsonb_build_object(
      'date_of_birth', to_jsonb(member)->>'date_of_birth',
      'feast_day', to_jsonb(member)->>'feast_day',
      'feast_month', to_jsonb(member)->>'feast_month',
      'home_contacts', coalesce((
        select jsonb_agg(jsonb_build_object(
          'name', to_jsonb(item)->>'name',
          'relationship', to_jsonb(item)->>'relationship',
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
      ), '[]'::jsonb),
      'languages', coalesce((
        select jsonb_agg(jsonb_build_object(
          'member_id', language.member_id,
          'language_name', language.language_name,
          'language_code', language.language_code,
          'proficiency_level_code', language.proficiency_level_code,
          'can_speak', language.can_speak,
          'can_read', language.can_read,
          'can_write', language.can_write,
          'is_primary', language.is_primary,
          'is_native', language.is_native
        ) order by language.is_primary desc, language.language_name)
        from public.member_languages language
        where language.member_id = member.id
      ), '[]'::jsonb)
    )
  from public.members member
  join public.member_community_assignments assignment
    on assignment.member_id = member.id
  where member.id = target_member_id
    and member.active
    and assignment.community_id = public.current_managed_community_id()
    and assignment.from_date <= current_date
    and (assignment.to_date is null or assignment.to_date >= current_date)
    and public.current_application_access_role() = 'community_superior'
  limit 1
$$;

revoke all on function
  public.get_community_superior_resident_profile_safe(uuid)
from public, anon;
grant execute on function
  public.get_community_superior_resident_profile_safe(uuid)
to authenticated;

comment on function public.get_community_superior_resident_profile_safe(uuid)
is 'Caller-bound current-resident pastoral profile for the caller managed community; includes family, education and languages but excludes restricted documents and Province administration.';
