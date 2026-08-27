-- Column-explicit MEMBER directory profile for another active religious.
-- Authorization is caller-bound; no family, emergency, leave, document,
-- financial, eligibility, credential, note, will, or vault source is joined.
create or replace function public.get_other_member_profile_safe(target_member_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'member_id', member.id,
    'religious_id', member.religious_id,
    'display_name', member.display_name,
    'ecclesiastical_title_code', member.ecclesiastical_title_code,
    'photo_url', member.photo_url,
    'member_status_code', member.member_status_code,
    'canonical_status_code', member.canonical_status_code,
    'mobile', contact.mobile,
    'whatsapp', contact.whatsapp,
    'official_email', contact.official_email,
    'address', coalesce(to_jsonb(origin)->>'address', to_jsonb(origin)->>'home_address', to_jsonb(origin)->>'postal_address'),
    'city', coalesce(to_jsonb(origin)->>'city', to_jsonb(origin)->>'native_place'),
    'district', origin.district,
    'state', origin.state,
    'country', origin.country,
    'community_name', current_community.name,
    'community_responsibility_code', current_community.responsibility_code,
    'community_from_date', current_community.from_date,
    'ministry_name', current_ministry.name,
    'ministry_responsibility_code', current_ministry.responsibility_code,
    'ministry_from_date', current_ministry.from_date,
    'vocation_events', coalesce(vocation.items, '[]'::jsonb),
    'qualifications', coalesce(qualification.items, '[]'::jsonb),
    'community_assignments', coalesce(community_history.items, '[]'::jsonb),
    'ministry_assignments', coalesce(ministry_history.items, '[]'::jsonb),
    'normal_responsibilities', coalesce(responsibility.items, '[]'::jsonb)
  )
  from public.members member
  join lateral (
    select 1
    from public.app_user_access access
    where access.auth_user_id = auth.uid()
      and access.active
      and access.access_role in ('member', 'community_superior', 'provincial')
    limit 1
  ) authorized on true
  left join public.v_demo_member_public_contacts contact on contact.member_id = member.id
  left join public.member_native_details origin on origin.member_id = member.id
  left join lateral (
    select community.name, assignment.responsibility_code, assignment.from_date
    from public.member_community_assignments assignment
    join public.communities community on community.id = assignment.community_id
    where assignment.member_id = member.id and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
    order by assignment.from_date desc limit 1
  ) current_community on true
  left join lateral (
    select ministry.name, assignment.responsibility_code, assignment.from_date
    from public.member_ministry_assignments assignment
    join public.ministries ministry on ministry.id = assignment.ministry_id
    where assignment.member_id = member.id and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
    order by assignment.from_date desc limit 1
  ) current_ministry on true
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'id', event.id, 'event_type_code', event.event_type_code,
      'event_date', event.event_date, 'place', to_jsonb(event)->>'place'
    ) order by event.event_date desc) as items
    from public.member_vocation_events event where event.member_id = member.id
  ) vocation on true
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'qualification', coalesce(to_jsonb(item)->>'qualification', to_jsonb(item)->>'degree', to_jsonb(item)->>'qualification_name'),
      'specialization', coalesce(to_jsonb(item)->>'specialization', to_jsonb(item)->>'field_of_study'),
      'institution', coalesce(to_jsonb(item)->>'institution', to_jsonb(item)->>'institution_name'),
      'subject', coalesce(to_jsonb(item)->>'subject', to_jsonb(item)->>'primary_subject'),
      'year_of_passing', coalesce(to_jsonb(item)->>'year_of_passing', to_jsonb(item)->>'completion_year', to_jsonb(item)->>'year'),
      'country', to_jsonb(item)->>'country'
    )) as items from public.member_qualifications item where item.member_id = member.id
  ) qualification on true
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'id', assignment.id, 'related_entity_id', assignment.community_id,
      'name', community.name, 'responsibility_code', assignment.responsibility_code,
      'from_date', assignment.from_date, 'to_date', assignment.to_date
    ) order by assignment.from_date desc) as items
    from public.member_community_assignments assignment
    join public.communities community on community.id = assignment.community_id
    where assignment.member_id = member.id
  ) community_history on true
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'id', assignment.id, 'related_entity_id', assignment.ministry_id,
      'name', ministry.name, 'responsibility_code', assignment.responsibility_code,
      'from_date', assignment.from_date, 'to_date', assignment.to_date
    ) order by assignment.from_date desc) as items
    from public.member_ministry_assignments assignment
    join public.ministries ministry on ministry.id = assignment.ministry_id
    where assignment.member_id = member.id
  ) ministry_history on true
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'id', appointment.id,
      'office', coalesce(to_jsonb(appointment)->>'office_type_code', to_jsonb(appointment)->>'office_code'),
      'context', coalesce(ministry.name, community.name),
      'context_kind', case when ministry.id is not null then 'ministry' when community.id is not null then 'community' end,
      'related_entity_id', coalesce(ministry.id, community.id),
      'from_date', appointment.from_date, 'to_date', appointment.to_date
    ) order by appointment.from_date desc) as items
    from public.member_office_appointments appointment
    left join public.ministries ministry on ministry.id = nullif(to_jsonb(appointment)->>'ministry_id', '')::uuid
    left join public.communities community on community.id = nullif(to_jsonb(appointment)->>'community_id', '')::uuid
    where appointment.member_id = member.id
      and (ministry.id is not null or community.id is not null)
  ) responsibility on true
  where member.id = target_member_id and member.active
  limit 1
$$;

revoke all on function public.get_other_member_profile_safe(uuid) from public, anon;
grant execute on function public.get_other_member_profile_safe(uuid) to authenticated;
comment on function public.get_other_member_profile_safe(uuid) is
  'Ordinary directory profile facts for an active religious; excludes all family, emergency, leave, document, financial, eligibility, note, will, vault and credential data.';
