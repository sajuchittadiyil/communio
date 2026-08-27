-- Correct the Ministry RPC to use the canonical operational view for the
-- Ministry-to-Community relationship; ministries has no direct community_id.
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
  select operational.ministry_id,
    operational.ministry_code::text,
    operational.ministry_name::text,
    operational.ministry_type::text,
    operational.community_id,
    operational.associated_community::text,
    head.member_id,
    head.display_name::text,
    head.title_code::text,
    head.responsibility_code::text
  from public.v_demo_ministry_operational operational
  left join lateral (
    select member.id member_id, member.display_name,
      member.ecclesiastical_title_code title_code,
      assignment.responsibility_code
    from public.member_ministry_assignments assignment
    join public.members member on member.id = assignment.member_id
    where assignment.ministry_id = operational.ministry_id
      and assignment.from_date <= current_date
      and (assignment.to_date is null or assignment.to_date >= current_date)
      and lower(assignment.responsibility_code) in (
        'principal','parish_priest','pastor','director','head',
        'novice_master','formation_director','vocation_promoter'
      )
    order by assignment.from_date desc
    limit 1
  ) head on true
  order by operational.ministry_name;
end;
$$;

revoke all on function public.get_provincial_ministries_safe() from public, anon;
grant execute on function public.get_provincial_ministries_safe() to authenticated;
