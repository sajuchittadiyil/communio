-- Canonical Provincial read API. Persona is deliberately absent from every
-- authorization predicate and returned record.

create or replace function public.require_current_provincial_access()
returns void language plpgsql stable security definer set search_path = public
as $$
begin
  if not exists (
    select 1 from public.app_user_access access
    where access.auth_user_id = auth.uid()
      and access.active
      and access.access_role = 'provincial'
  ) then
    raise exception 'Provincial access required' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.get_provincial_member_directory_safe()
returns table (
  member_id uuid, religious_id text, display_name text,
  ecclesiastical_title_code text, photo_url text,
  member_status text, canonical_status text,
  community_id uuid, community_name text, community_role text,
  ministry_id uuid, ministry_name text, ministry_role text,
  responsibility_code text, mobile text, whatsapp text, official_email text
) language plpgsql stable security definer set search_path = public
as $$
begin
  perform public.require_current_provincial_access();
  return query
  select
    member.id,
    member.religious_id::text,
    member.display_name::text,
    member.ecclesiastical_title_code::text,
    member.photo_url::text,
    member.member_status_code::text,
    member.canonical_status_code::text,
    current_community.community_id,
    current_community.community_name::text,
    current_community.responsibility_code::text,
    current_ministry.ministry_id,
    current_ministry.ministry_name::text,
    current_ministry.responsibility_code::text,
    coalesce(
      current_community.responsibility_code,
      current_ministry.responsibility_code
    )::text,
    contact.mobile::text,
    contact.whatsapp::text,
    contact.official_email::text
  from public.members member
  left join lateral (
    select assignment.community_id, community.name as community_name,
      assignment.responsibility_code
    from public.member_community_assignments assignment
    join public.communities community on community.id = assignment.community_id
    where assignment.member_id = member.id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
    order by assignment.from_date desc
    limit 1
  ) current_community on true
  left join lateral (
    select assignment.ministry_id, ministry.name as ministry_name,
      assignment.responsibility_code
    from public.member_ministry_assignments assignment
    join public.ministries ministry on ministry.id = assignment.ministry_id
    where assignment.member_id = member.id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
    order by assignment.from_date desc
    limit 1
  ) current_ministry on true
  left join public.v_demo_member_public_contacts contact
    on contact.member_id = member.id
  where member.active
  order by member.display_name, member.id;
end;
$$;

create or replace function public.get_provincial_member_profile_safe(
  p_member_id uuid
) returns jsonb language plpgsql stable security definer set search_path = public
as $$
declare result jsonb;
begin
  perform public.require_current_provincial_access();
  select jsonb_build_object(
    'member_id', member.id,
    'religious_id', member.religious_id,
    'display_name', member.display_name,
    'ecclesiastical_title_code', member.ecclesiastical_title_code,
    'photo_url', member.photo_url,
    'member_status_code', member.member_status_code,
    'canonical_status_code', member.canonical_status_code,
    'date_of_birth', member.date_of_birth,
    'nationality', to_jsonb(member)->>'nationality',
    'blood_group', to_jsonb(member)->>'blood_group',
    'patron_saint', to_jsonb(member)->>'patron_saint',
    'mobile', contact.mobile,
    'whatsapp', contact.whatsapp,
    'official_email', contact.official_email,
    'vocation_events', coalesce((select jsonb_agg(to_jsonb(item) order by item.event_date) from public.member_vocation_events item where item.member_id = member.id), '[]'::jsonb),
    'qualifications', coalesce((select jsonb_agg(to_jsonb(item)) from public.member_qualifications item where item.member_id = member.id), '[]'::jsonb),
    'community_assignments', coalesce((select jsonb_agg(to_jsonb(item) || jsonb_build_object('name', community.name) order by item.from_date desc) from public.member_community_assignments item join public.communities community on community.id = item.community_id where item.member_id = member.id), '[]'::jsonb),
    'ministry_assignments', coalesce((select jsonb_agg(to_jsonb(item) || jsonb_build_object('name', ministry.name) order by item.from_date desc) from public.member_ministry_assignments item join public.ministries ministry on ministry.id = item.ministry_id where item.member_id = member.id), '[]'::jsonb),
    'office_appointments', coalesce((select jsonb_agg(to_jsonb(item) order by item.from_date desc) from public.member_office_appointments item where item.member_id = member.id), '[]'::jsonb),
    'native_details', (select to_jsonb(item) from public.member_native_details item where item.member_id = member.id limit 1),
    'home_contacts', coalesce((select jsonb_agg(to_jsonb(item)) from public.member_home_contacts item where item.member_id = member.id), '[]'::jsonb),
    'family', coalesce((select jsonb_agg(to_jsonb(item)) from public.member_family item where item.member_id = member.id), '[]'::jsonb),
    'documents', coalesce((select jsonb_agg(to_jsonb(item)) from public.documents item where item.member_id = member.id), '[]'::jsonb),
    'attention_events', coalesce((select jsonb_agg(to_jsonb(item)) from public.v_demo_member_attention_events item where item.member_id = member.id), '[]'::jsonb)
  ) into result
  from public.members member
  left join public.v_demo_member_public_contacts contact on contact.member_id = member.id
  where member.id = p_member_id;
  if result is null then
    raise exception 'Member profile not found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

create or replace function public.get_provincial_communities_safe()
returns table (
  community_id uuid, community_code text, community_name text,
  superior_member_id uuid, superior_display_name text,
  superior_title_code text, accountant_member_id uuid,
  accountant_display_name text, accountant_title_code text,
  current_resident_count bigint
) language plpgsql stable security definer set search_path = public
as $$
begin
  perform public.require_current_provincial_access();
  return query
  select community.id, community.code::text, community.name::text,
    superior.member_id, superior.display_name::text, superior.title_code::text,
    accountant.member_id, accountant.display_name::text, accountant.title_code::text,
    (select count(*) from public.member_community_assignments resident
      where resident.community_id = community.id
        and resident.from_date <= current_date
        and (resident.to_date is null or resident.to_date >= current_date))
  from public.communities community
  left join lateral (
    select member.id member_id, member.display_name,
      member.ecclesiastical_title_code title_code
    from public.member_community_assignments assignment
    join public.members member on member.id = assignment.member_id
    where assignment.community_id = community.id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
      and lower(assignment.responsibility_code) in ('superior','community_superior')
    order by assignment.from_date desc limit 1
  ) superior on true
  left join lateral (
    select member.id member_id, member.display_name,
      member.ecclesiastical_title_code title_code
    from public.member_community_assignments assignment
    join public.members member on member.id = assignment.member_id
    where assignment.community_id = community.id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
      and lower(assignment.responsibility_code) in ('accountant','bursar','community_accountant','community_bursar')
    order by assignment.from_date desc limit 1
  ) accountant on true
  where community.active
  order by community.name;
end;
$$;

create or replace function public.get_provincial_ministries_safe()
returns table (
  ministry_id uuid, ministry_code text, ministry_name text,
  ministry_type text, community_id uuid, community_name text,
  head_member_id uuid, head_display_name text, head_title_code text,
  head_role text
) language plpgsql stable security definer set search_path = public
as $$
begin
  perform public.require_current_provincial_access();
  return query
  select ministry.id, ministry.code::text, ministry.name::text,
    ministry.ministry_type_code::text, ministry.community_id,
    community.name::text, head.member_id, head.display_name::text,
    head.title_code::text, head.responsibility_code::text
  from public.ministries ministry
  left join public.communities community on community.id = ministry.community_id
  left join lateral (
    select member.id member_id, member.display_name,
      member.ecclesiastical_title_code title_code,
      assignment.responsibility_code
    from public.member_ministry_assignments assignment
    join public.members member on member.id = assignment.member_id
    where assignment.ministry_id = ministry.id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
      and lower(assignment.responsibility_code) in ('principal','parish_priest','pastor','director','head','novice_master','formation_director','vocation_promoter')
    order by assignment.from_date desc limit 1
  ) head on true
  where ministry.active
  order by ministry.name;
end;
$$;

revoke all on function public.require_current_provincial_access() from public, anon;
revoke all on function public.get_provincial_member_directory_safe() from public, anon;
revoke all on function public.get_provincial_member_profile_safe(uuid) from public, anon;
revoke all on function public.get_provincial_communities_safe() from public, anon;
revoke all on function public.get_provincial_ministries_safe() from public, anon;
grant execute on function public.get_provincial_member_directory_safe() to authenticated;
grant execute on function public.get_provincial_member_profile_safe(uuid) to authenticated;
grant execute on function public.get_provincial_communities_safe() to authenticated;
grant execute on function public.get_provincial_ministries_safe() to authenticated;
