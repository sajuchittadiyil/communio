-- Complete the canonical Provincial read boundary. All authorization is based
-- exclusively on the authenticated user's active Provincial access record.

drop function if exists public.get_provincial_communities_safe();
create function public.get_provincial_communities_safe()
returns setof jsonb language plpgsql stable security definer set search_path = public
as $$
begin
  perform public.require_current_provincial_access();
  return query
  select to_jsonb(c) || jsonb_build_object(
    'community_id', c.id, 'community_code', c.code, 'community_name', c.name,
    'location_city', c.city,
    'resident_count', (select count(*) from public.member_community_assignments a where a.community_id=c.id and a.from_date<=current_date and (a.to_date is null or a.to_date>=current_date)),
    'linked_ministry_count', (select count(*) from public.v_demo_ministry_operational o where o.community_id=c.id),
    'superior_member_id', superior.member_id, 'superior_display_name', superior.display_name, 'superior_title_code', superior.title_code,
    'accountant_member_id', accountant.member_id, 'accountant_display_name', accountant.display_name, 'accountant_title_code', accountant.title_code,
    'residents', coalesce((select jsonb_agg(jsonb_build_object(
      'member_id', m.id, 'religious_id', m.religious_id, 'display_name', m.display_name,
      'ecclesiastical_title_code', m.ecclesiastical_title_code, 'photo_url', m.photo_url,
      'member_status', m.member_status_code, 'canonical_status', m.canonical_status_code,
      'community_role', a.responsibility_code, 'from_date', a.from_date, 'to_date', a.to_date,
      'ministry_id', ministry.ministry_id, 'ministry_name', ministry.ministry_name,
      'ministry_role', ministry.responsibility_code
    ) order by m.display_name) from public.member_community_assignments a join public.members m on m.id=a.member_id
      left join lateral (select ma.ministry_id, mi.name ministry_name, ma.responsibility_code from public.member_ministry_assignments ma join public.ministries mi on mi.id=ma.ministry_id where ma.member_id=m.id and ma.from_date<=current_date and (ma.to_date is null or ma.to_date>=current_date) order by ma.from_date desc limit 1) ministry on true
      where a.community_id=c.id and a.from_date<=current_date and (a.to_date is null or a.to_date>=current_date)), '[]'::jsonb),
    'community_history', coalesce((select jsonb_agg(jsonb_build_object('member_id',m.id,'religious_id',m.religious_id,'display_name',m.display_name,'ecclesiastical_title_code',m.ecclesiastical_title_code,'photo_url',m.photo_url,'responsibility_code',a.responsibility_code,'from_date',a.from_date,'to_date',a.to_date) order by a.from_date desc) from public.member_community_assignments a join public.members m on m.id=a.member_id where a.community_id=c.id), '[]'::jsonb),
    'linked_ministries', coalesce((select jsonb_agg(to_jsonb(o) order by o.ministry_name) from public.v_demo_ministry_operational o where o.community_id=c.id), '[]'::jsonb)
  )
  from public.communities c
  left join lateral (select m.id member_id,m.display_name,m.ecclesiastical_title_code title_code from public.member_community_assignments a join public.members m on m.id=a.member_id where a.community_id=c.id and a.from_date<=current_date and (a.to_date is null or a.to_date>=current_date) and lower(a.responsibility_code) in ('superior','community_superior') order by a.from_date desc limit 1) superior on true
  left join lateral (select m.id member_id,m.display_name,m.ecclesiastical_title_code title_code from public.member_community_assignments a join public.members m on m.id=a.member_id where a.community_id=c.id and a.from_date<=current_date and (a.to_date is null or a.to_date>=current_date) and lower(a.responsibility_code) in ('accountant','bursar','community_accountant','community_bursar') order by a.from_date desc limit 1) accountant on true
  where c.active order by c.name;
end; $$;

drop function if exists public.get_provincial_ministries_safe();
create function public.get_provincial_ministries_safe()
returns setof jsonb language plpgsql stable security definer set search_path = public
as $$
begin
  perform public.require_current_provincial_access();
  return query select to_jsonb(o) || to_jsonb(m) || jsonb_build_object(
    'ministry_id',o.ministry_id,'ministry_code',o.ministry_code,'ministry_name',o.ministry_name,
    'head_member_id',head.member_id,'head_display_name',head.display_name,'head_title_code',head.title_code,'head_role',head.responsibility_code,
    'assignments',coalesce((select jsonb_agg(jsonb_build_object('member_id',p.id,'religious_id',p.religious_id,'display_name',p.display_name,'ecclesiastical_title_code',p.ecclesiastical_title_code,'photo_url',p.photo_url,'member_status',p.member_status_code,'responsibility_code',a.responsibility_code,'from_date',a.from_date,'to_date',a.to_date) order by a.from_date desc) from public.member_ministry_assignments a join public.members p on p.id=a.member_id where a.ministry_id=o.ministry_id),'[]'::jsonb)
  ) from public.v_demo_ministry_operational o join public.ministries m on m.id=o.ministry_id
  left join lateral (select p.id member_id,p.display_name,p.ecclesiastical_title_code title_code,a.responsibility_code from public.member_ministry_assignments a join public.members p on p.id=a.member_id where a.ministry_id=o.ministry_id and a.from_date<=current_date and (a.to_date is null or a.to_date>=current_date) and lower(a.responsibility_code) in ('principal','parish_priest','pastor','director','head','novice_master','formation_director','vocation_promoter') order by a.from_date desc limit 1) head on true
  order by o.ministry_name;
end; $$;

create or replace function public.get_provincial_formation_safe()
returns setof jsonb language plpgsql stable security definer set search_path = public
as $$ begin perform public.require_current_provincial_access(); return query
  select to_jsonb(f) || jsonb_build_object('photo_url',m.photo_url,'ecclesiastical_title_code',m.ecclesiastical_title_code)
  from public.v_demo_formation_pipeline f join public.members m on m.id=f.member_id order by f.formation_house,f.display_name; end; $$;

create or replace function public.get_provincial_leadership_safe()
returns setof jsonb language plpgsql stable security definer set search_path = public
as $$ begin perform public.require_current_provincial_access(); return query
  select to_jsonb(a) || jsonb_build_object('appointment_id',a.id,'religious_id',m.religious_id,'display_name',m.display_name,'canonical_title',m.ecclesiastical_title_code,'office_name',coalesce(t.name,a.office_type_code),'current',(a.from_date<=current_date and (a.to_date is null or a.to_date>=current_date)),'photo_url',m.photo_url)
  from public.member_office_appointments a join public.members m on m.id=a.member_id left join public.office_types t on t.code=a.office_type_code order by a.from_date desc; end; $$;

create or replace function public.get_provincial_profile_counts_safe()
returns jsonb language plpgsql stable security definer set search_path = public
as $$ begin perform public.require_current_provincial_access(); return jsonb_build_object(
  'active_members',(select count(*) from public.members where active),
  'communities',(select count(*) from public.communities where active),
  'ministries',(select count(*) from public.ministries where active),
  'formation_members',(select count(*) from public.v_demo_formation_pipeline),
  'current_provincial_offices',(select count(*) from public.member_office_appointments where from_date<=current_date and (to_date is null or to_date>=current_date))
); end; $$;

revoke all on function public.get_provincial_communities_safe() from public, anon;
revoke all on function public.get_provincial_ministries_safe() from public, anon;
revoke all on function public.get_provincial_formation_safe() from public, anon;
revoke all on function public.get_provincial_leadership_safe() from public, anon;
revoke all on function public.get_provincial_profile_counts_safe() from public, anon;
grant execute on function public.get_provincial_communities_safe() to authenticated;
grant execute on function public.get_provincial_ministries_safe() to authenticated;
grant execute on function public.get_provincial_formation_safe() to authenticated;
grant execute on function public.get_provincial_leadership_safe() to authenticated;
grant execute on function public.get_provincial_profile_counts_safe() to authenticated;
