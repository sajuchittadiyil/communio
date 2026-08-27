-- Admit Community Superior callers to the existing column-limited MEMBER-safe
-- other-profile function without changing its returned fields or base tables.
do $$
declare
  definition text;
begin
  select pg_get_functiondef(
    'public.get_other_member_profile_safe(uuid)'::regprocedure
  ) into definition;
  if position(
    'access.access_role in (''member'', ''community_superior'', ''provincial'')'
    in definition
  ) = 0 then
    definition := regexp_replace(
      definition,
      'access\.access_role\s+in\s+\(''member'',\s*''provincial''\)',
      'access.access_role in (''member'', ''community_superior'', ''provincial'')'
    );
  end if;
  if position(
    'access.access_role in (''member'', ''community_superior'', ''provincial'')'
    in definition
  ) = 0 then
    raise exception 'Unable to update get_other_member_profile_safe role predicate safely';
  end if;
  execute definition;
end
$$;

-- One caller-bound entry point preserves the established MEMBER self RPC and
-- uses the server-authorized resident resolver for a Community Superior's self.
create or replace function public.get_current_user_profile_safe()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case public.current_application_access_role()
    when 'member' then public.get_member_self_profile_safe()
    when 'community_superior' then
      public.get_community_superior_resident_profile_safe(public.current_member_id())
    else null
  end
$$;

revoke all on function public.get_current_user_profile_safe() from public, anon;
grant execute on function public.get_current_user_profile_safe() to authenticated;

comment on function public.get_current_user_profile_safe() is
  'Caller-bound self profile for MEMBER and COMMUNITY SUPERIOR; returns no privileged Provincial, family, vault, document, or governance data.';
