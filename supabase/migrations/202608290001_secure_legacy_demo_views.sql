-- Close legacy reporting-view owner bypass and anonymous access.
--
-- The views remain read-only interfaces for authenticated callers. With
-- security_invoker enabled, base-table privileges and RLS are evaluated as the
-- signed-in caller instead of the view owner. This migration changes no data.

alter view public.v_demo_current_communities
  set (security_invoker = true);
alter view public.v_demo_current_office_holders
  set (security_invoker = true);
alter view public.v_demo_formation_pipeline
  set (security_invoker = true);
alter view public.v_demo_member_attention_events
  set (security_invoker = true);
alter view public.v_demo_member_directory
  set (security_invoker = true);
alter view public.v_demo_member_public_contacts
  set (security_invoker = true);
alter view public.v_demo_ministry_operational
  set (security_invoker = true);
alter view public.v_demo_province_pulse
  set (security_invoker = true);
alter view public.v_demo_recent_appointments
  set (security_invoker = true);
alter view public.v_demo_upcoming_birthdays
  set (security_invoker = true);
alter view public.v_demo_upcoming_feast_days
  set (security_invoker = true);

revoke all privileges on table
  public.v_demo_current_communities,
  public.v_demo_current_office_holders,
  public.v_demo_formation_pipeline,
  public.v_demo_member_attention_events,
  public.v_demo_member_directory,
  public.v_demo_member_public_contacts,
  public.v_demo_ministry_operational,
  public.v_demo_province_pulse,
  public.v_demo_recent_appointments,
  public.v_demo_upcoming_birthdays,
  public.v_demo_upcoming_feast_days
from anon, public;

-- Reporting views must expose SELECT only. Caller-specific row visibility is
-- enforced by the underlying relations and their RLS policies.
revoke all privileges on table
  public.v_demo_current_communities,
  public.v_demo_current_office_holders,
  public.v_demo_formation_pipeline,
  public.v_demo_member_attention_events,
  public.v_demo_member_directory,
  public.v_demo_member_public_contacts,
  public.v_demo_ministry_operational,
  public.v_demo_province_pulse,
  public.v_demo_recent_appointments,
  public.v_demo_upcoming_birthdays,
  public.v_demo_upcoming_feast_days
from authenticated;

grant select on table
  public.v_demo_current_communities,
  public.v_demo_current_office_holders,
  public.v_demo_formation_pipeline,
  public.v_demo_member_attention_events,
  public.v_demo_member_directory,
  public.v_demo_member_public_contacts,
  public.v_demo_ministry_operational,
  public.v_demo_province_pulse,
  public.v_demo_recent_appointments,
  public.v_demo_upcoming_birthdays,
  public.v_demo_upcoming_feast_days
to authenticated;

do $$
declare
  view_name text;
  expected_views constant text[] := array[
    'v_demo_current_communities',
    'v_demo_current_office_holders',
    'v_demo_formation_pipeline',
    'v_demo_member_attention_events',
    'v_demo_member_directory',
    'v_demo_member_public_contacts',
    'v_demo_ministry_operational',
    'v_demo_province_pulse',
    'v_demo_recent_appointments',
    'v_demo_upcoming_birthdays',
    'v_demo_upcoming_feast_days'
  ];
begin
  foreach view_name in array expected_views loop
    if not exists (
      select 1
      from pg_class relation
      join pg_namespace namespace on namespace.oid = relation.relnamespace
      where namespace.nspname = 'public'
        and relation.relname = view_name
        and relation.relkind = 'v'
        and coalesce(relation.reloptions, array[]::text[])
          @> array['security_invoker=true']
    ) then
      raise exception 'Legacy reporting view %.% is absent or not security_invoker',
        'public', view_name;
    end if;

    if has_table_privilege('anon', format('public.%I', view_name), 'select') then
      raise exception 'Anonymous SELECT remains on public.%', view_name;
    end if;

    if not has_table_privilege(
      'authenticated', format('public.%I', view_name), 'select'
    ) then
      raise exception 'Authenticated SELECT missing on public.%', view_name;
    end if;
  end loop;
end;
$$;

