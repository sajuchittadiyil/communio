-- Close anonymous and view-owner bypass paths used by Ask Communio reporting.
--
-- These views were created with PostgreSQL's default security-definer behavior,
-- which evaluated their base-table reads as the view owner (postgres). Setting
-- security_invoker makes each query use the caller's privileges and RLS context.

alter view public.v_member_qualifications_normalized
  set (security_invoker = true);
alter view public.v_member_teaching_qualification_profile
  set (security_invoker = true);
alter view public.v_demo_member_directory
  set (security_invoker = true);
alter view public.v_demo_current_office_holders
  set (security_invoker = true);
alter view public.v_responsibility_eligibility
  set (security_invoker = true);
alter view public.v_office_eligibility
  set (security_invoker = true);

revoke all privileges on table
  public.v_member_qualifications_normalized,
  public.v_member_teaching_qualification_profile,
  public.v_demo_member_directory,
  public.v_demo_current_office_holders,
  public.v_responsibility_eligibility,
  public.v_office_eligibility
from anon;

-- Reporting views are read-only application interfaces. Remove the broad
-- generated grants and restore only the privilege signed-in users require.
revoke all privileges on table
  public.v_member_qualifications_normalized,
  public.v_member_teaching_qualification_profile,
  public.v_demo_member_directory,
  public.v_demo_current_office_holders,
  public.v_responsibility_eligibility,
  public.v_office_eligibility
from authenticated;

grant select on table
  public.v_member_qualifications_normalized,
  public.v_member_teaching_qualification_profile,
  public.v_demo_member_directory,
  public.v_demo_current_office_holders,
  public.v_responsibility_eligibility,
  public.v_office_eligibility
to authenticated;

-- service_role privileges are intentionally left unchanged.
