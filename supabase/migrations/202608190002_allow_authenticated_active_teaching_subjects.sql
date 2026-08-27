-- Eligibility calculations join this non-sensitive reference taxonomy. Once
-- the reporting views run as security invokers, authenticated callers need an
-- RLS path to the active lookup rows. Keep anonymous access unchanged.

do $migration$
begin
  if not exists (
    select 1
      from pg_policies
     where schemaname = 'public'
       and tablename = 'teaching_subjects'
       and policyname = 'authenticated_can_read_active_teaching_subjects'
  ) then
    create policy authenticated_can_read_active_teaching_subjects
      on public.teaching_subjects
      for select
      to authenticated
      using (active = true);
  end if;
end
$migration$;

grant select on table public.teaching_subjects to authenticated;
