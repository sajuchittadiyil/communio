-- Caller-bound self profile for an ordinary Member. The function accepts no
-- member identifier and can only resolve the active mapping for auth.uid().
create or replace function public.get_member_self_profile_safe()
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
    'community_name', current_community.name,
    'community_responsibility_code', current_community.responsibility_code,
    'community_from_date', current_community.from_date,
    'ministry_name', current_ministry.name,
    'ministry_responsibility_code', current_ministry.responsibility_code,
    'ministry_from_date', current_ministry.from_date,
    'vocation_events', coalesce(vocation.events, '[]'::jsonb),
    'qualifications', coalesce(qualification.items, '[]'::jsonb),
    'community_assignments', coalesce(community_history.items, '[]'::jsonb),
    'ministry_assignments', coalesce(ministry_history.items, '[]'::jsonb)
  )
  from public.app_user_access access
  join public.members member on member.id = access.member_id
  left join lateral (
    select
      community.name,
      assignment.responsibility_code,
      assignment.from_date
    from public.member_community_assignments assignment
    join public.communities community on community.id = assignment.community_id
    where assignment.member_id = member.id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
    order by assignment.from_date desc
    limit 1
  ) current_community on true
  left join lateral (
    select
      ministry.name,
      assignment.responsibility_code,
      assignment.from_date
    from public.member_ministry_assignments assignment
    join public.ministries ministry on ministry.id = assignment.ministry_id
    where assignment.member_id = member.id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
    order by assignment.from_date desc
    limit 1
  ) current_ministry on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'id', event.id,
        'event_type_code', event.event_type_code,
        'event_date', event.event_date
      ) order by event.event_date
    ) as events
    from public.member_vocation_events event
    where event.member_id = member.id
  ) vocation on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'qualification', coalesce(
          to_jsonb(item)->>'qualification',
          to_jsonb(item)->>'degree',
          to_jsonb(item)->>'qualification_name'
        ),
        'specialization', coalesce(
          to_jsonb(item)->>'specialization',
          to_jsonb(item)->>'field_of_study'
        ),
        'institution', coalesce(
          to_jsonb(item)->>'institution',
          to_jsonb(item)->>'institution_name'
        ),
        'year_of_passing', coalesce(
          to_jsonb(item)->>'year_of_passing',
          to_jsonb(item)->>'completion_year',
          to_jsonb(item)->>'year'
        )
      )
    ) as items
    from public.member_qualifications item
    where item.member_id = member.id
  ) qualification on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'id', assignment.id,
        'related_entity_id', assignment.community_id,
        'name', community.name,
        'responsibility_code', assignment.responsibility_code,
        'from_date', assignment.from_date,
        'to_date', assignment.to_date
      ) order by assignment.from_date desc
    ) as items
    from public.member_community_assignments assignment
    join public.communities community on community.id = assignment.community_id
    where assignment.member_id = member.id
  ) community_history on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'id', assignment.id,
        'related_entity_id', assignment.ministry_id,
        'name', ministry.name,
        'responsibility_code', assignment.responsibility_code,
        'from_date', assignment.from_date,
        'to_date', assignment.to_date
      ) order by assignment.from_date desc
    ) as items
    from public.member_ministry_assignments assignment
    join public.ministries ministry on ministry.id = assignment.ministry_id
    where assignment.member_id = member.id
  ) ministry_history on true
  where access.auth_user_id = auth.uid()
    and access.active
    and access.access_role = 'member'
    and member.active
  limit 1
$$;

revoke all on function public.get_member_self_profile_safe() from public, anon;
grant execute on function public.get_member_self_profile_safe() to authenticated;

comment on function public.get_member_self_profile_safe() is
  'Returns approved self-profile identity, vocation, qualification and assignment data for the current active Member mapping only.';
