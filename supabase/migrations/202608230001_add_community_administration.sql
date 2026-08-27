create table if not exists public.community_events (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete restrict,
  title text not null check (length(btrim(title)) between 1 and 160),
  event_type text not null check (event_type in (
    'community_meeting', 'feast_celebration', 'recollection', 'retreat',
    'community_programme', 'visitor_guest_programme',
    'formation_spiritual_programme', 'other'
  )),
  description text,
  venue text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  responsible_member_id uuid references public.members(id) on delete set null,
  status text not null default 'confirmed'
    check (status in ('planned', 'confirmed', 'completed', 'cancelled')),
  visible_to_province boolean not null default false,
  created_by_auth_user_id uuid not null default auth.uid()
    references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at >= starts_at)
);

create table if not exists public.community_meetings (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete restrict,
  meeting_date date not null,
  title text not null check (length(btrim(title)) between 1 and 160),
  summary text not null,
  decisions text,
  action_items text,
  next_meeting_date date,
  visible_to_province boolean not null default true,
  created_by_auth_user_id uuid not null default auth.uid()
    references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end
$$;

drop trigger if exists community_events_set_updated_at on public.community_events;
create trigger community_events_set_updated_at before update on public.community_events
for each row execute function public.set_updated_at();
drop trigger if exists community_meetings_set_updated_at on public.community_meetings;
create trigger community_meetings_set_updated_at before update on public.community_meetings
for each row execute function public.set_updated_at();

create or replace function public.protect_community_record_scope()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.community_id <> old.community_id
    or new.created_by_auth_user_id <> old.created_by_auth_user_id then
    raise exception 'Community scope and author are immutable' using errcode = '42501';
  end if;
  return new;
end
$$;
drop trigger if exists community_events_protect_scope on public.community_events;
create trigger community_events_protect_scope before update on public.community_events
for each row execute function public.protect_community_record_scope();
drop trigger if exists community_meetings_protect_scope on public.community_meetings;
create trigger community_meetings_protect_scope before update on public.community_meetings
for each row execute function public.protect_community_record_scope();

alter table public.community_events enable row level security;
alter table public.community_meetings enable row level security;
revoke all on public.community_events, public.community_meetings from public, anon;
grant select, insert, update, delete on public.community_events, public.community_meetings to authenticated;

create policy community_events_read on public.community_events for select to authenticated using (
  (public.current_application_access_role() = 'community_superior'
    and community_id = public.current_managed_community_id())
  or (public.current_application_access_role() = 'provincial' and visible_to_province)
);
create policy community_events_superior_insert on public.community_events for insert to authenticated with check (
  public.current_application_access_role() = 'community_superior'
  and community_id = public.current_managed_community_id()
  and created_by_auth_user_id = auth.uid()
);
create policy community_events_superior_update on public.community_events for update to authenticated
using (public.current_application_access_role() = 'community_superior' and community_id = public.current_managed_community_id())
with check (public.current_application_access_role() = 'community_superior' and community_id = public.current_managed_community_id());
create policy community_events_superior_delete on public.community_events for delete to authenticated using (
  public.current_application_access_role() = 'community_superior'
  and community_id = public.current_managed_community_id()
);

create policy community_meetings_read on public.community_meetings for select to authenticated using (
  (public.current_application_access_role() = 'community_superior'
    and community_id = public.current_managed_community_id())
  or (public.current_application_access_role() = 'provincial' and visible_to_province)
);
create policy community_meetings_superior_insert on public.community_meetings for insert to authenticated with check (
  public.current_application_access_role() = 'community_superior'
  and community_id = public.current_managed_community_id()
  and created_by_auth_user_id = auth.uid()
);
create policy community_meetings_superior_update on public.community_meetings for update to authenticated
using (public.current_application_access_role() = 'community_superior' and community_id = public.current_managed_community_id())
with check (public.current_application_access_role() = 'community_superior' and community_id = public.current_managed_community_id());
create policy community_meetings_superior_delete on public.community_meetings for delete to authenticated using (
  public.current_application_access_role() = 'community_superior'
  and community_id = public.current_managed_community_id()
);

create or replace function public.create_community_event_safe(
  event_title text, event_type_code text, event_starts_at timestamptz,
  event_ends_at timestamptz default null, event_venue text default null,
  event_description text default null, event_responsible_member_id uuid default null,
  event_status text default 'confirmed', event_visible_to_province boolean default false
) returns uuid language plpgsql security invoker set search_path = public as $$
declare managed_id uuid; created_id uuid;
begin
  managed_id := public.current_managed_community_id();
  if public.current_application_access_role() <> 'community_superior' or managed_id is null then
    raise exception 'Community Superior scope is unavailable' using errcode = '42501';
  end if;
  insert into public.community_events (
    community_id, title, event_type, starts_at, ends_at, venue, description,
    responsible_member_id, status, visible_to_province, created_by_auth_user_id
  ) values (
    managed_id, event_title, event_type_code, event_starts_at, event_ends_at,
    event_venue, event_description, event_responsible_member_id, event_status,
    event_visible_to_province, auth.uid()
  ) returning id into created_id;
  return created_id;
end
$$;

create or replace function public.save_community_meeting_safe(
  meeting_title text, meeting_on date, meeting_summary text,
  meeting_decisions text default null, meeting_action_items text default null,
  meeting_next_date date default null, meeting_visible_to_province boolean default true
) returns uuid language plpgsql security invoker set search_path = public as $$
declare managed_id uuid; created_id uuid;
begin
  managed_id := public.current_managed_community_id();
  if public.current_application_access_role() <> 'community_superior' or managed_id is null then
    raise exception 'Community Superior scope is unavailable' using errcode = '42501';
  end if;
  insert into public.community_meetings (
    community_id, meeting_date, title, summary, decisions, action_items,
    next_meeting_date, visible_to_province, created_by_auth_user_id
  ) values (
    managed_id, meeting_on, meeting_title, meeting_summary, meeting_decisions,
    meeting_action_items, meeting_next_date, meeting_visible_to_province, auth.uid()
  ) returning id into created_id;
  return created_id;
end
$$;

revoke all on function public.create_community_event_safe(text,text,timestamptz,timestamptz,text,text,uuid,text,boolean) from public, anon;
revoke all on function public.save_community_meeting_safe(text,date,text,text,text,date,boolean) from public, anon;
grant execute on function public.create_community_event_safe(text,text,timestamptz,timestamptz,text,text,uuid,text,boolean) to authenticated;
grant execute on function public.save_community_meeting_safe(text,date,text,text,text,date,boolean) to authenticated;

-- Demo-safe Sacred Heart records; conflict checks prevent duplicate reseeding.
insert into public.community_events (
  community_id, title, event_type, starts_at, venue, description, status,
  visible_to_province, created_by_auth_user_id
)
select community.id, seed.title, seed.event_type, seed.starts_at, seed.venue,
  seed.description, seed.status, true, auth_user.id
from public.communities community
join auth.users auth_user on lower(auth_user.email) = 'superior@communio.com'
cross join (values
  ('Community Council Meeting','community_meeting','2026-08-23 18:00+05:30'::timestamptz,null::text,'Community council review and coordination.','confirmed'),
  ('Monthly Recollection','recollection','2026-08-29 08:00+05:30'::timestamptz,'Sacred Heart Community Chapel','Monthly prayer and recollection programme.','planned')
) seed(title,event_type,starts_at,venue,description,status)
where coalesce(to_jsonb(community)->>'code', to_jsonb(community)->>'community_code') = 'COM003'
  and not exists (select 1 from public.community_events event where event.community_id = community.id and event.title = seed.title);

insert into public.community_meetings (
  community_id, meeting_date, title, summary, decisions, action_items,
  visible_to_province, created_by_auth_user_id
)
select community.id, '2026-08-23'::date, 'Community Meeting Minutes – August 2026',
  'Review of community life, ministries, forthcoming programmes and pastoral commitments.',
  E'Confirm monthly recollection\nReview community responsibilities\nPrepare parish feast support',
  E'Finalise recollection programme\nCoordinate parish support', true, auth_user.id
from public.communities community
join auth.users auth_user on lower(auth_user.email) = 'superior@communio.com'
where coalesce(to_jsonb(community)->>'code', to_jsonb(community)->>'community_code') = 'COM003'
  and not exists (select 1 from public.community_meetings meeting where meeting.community_id = community.id and meeting.title = 'Community Meeting Minutes – August 2026');
