-- Application access roles are independent of canonical religious status.
create table if not exists public.app_user_access (
  auth_user_id uuid primary key references auth.users(id) on delete cascade,
  member_id uuid references public.members(id) on delete restrict,
  access_role text not null check (access_role in ('provincial', 'member')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_role_requires_member check (
    access_role <> 'member' or member_id is not null
  )
);

create unique index if not exists app_user_access_one_active_member
  on public.app_user_access(member_id)
  where active and member_id is not null;

alter table public.app_user_access enable row level security;
grant select on public.app_user_access to authenticated;
grant all on public.app_user_access to service_role;

drop policy if exists app_user_access_read_self on public.app_user_access;
create policy app_user_access_read_self on public.app_user_access
  for select to authenticated using (auth_user_id = auth.uid());

-- Preserve the access level of accounts that existed before role-aware access.
insert into public.app_user_access (auth_user_id, access_role)
select id, 'provincial' from auth.users
on conflict (auth_user_id) do nothing;

create or replace function public.current_access_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select access_role
  from public.app_user_access
  where auth_user_id = auth.uid() and active
$$;

create or replace function public.current_member_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select member_id
  from public.app_user_access
  where auth_user_id = auth.uid() and active
$$;

revoke all on function public.current_access_role() from public, anon;
revoke all on function public.current_member_id() from public, anon;
grant execute on function public.current_access_role() to authenticated;
grant execute on function public.current_member_id() to authenticated;

-- Replace the original broad document policy with access-aware metadata RLS.
drop policy if exists province_documents_authenticated_read on public.province_documents;
drop policy if exists province_documents_provincial_read on public.province_documents;
drop policy if exists province_documents_member_read on public.province_documents;
create policy province_documents_provincial_read on public.province_documents
  for select to authenticated
  using (public.current_access_role() = 'provincial');
create policy province_documents_member_read on public.province_documents
  for select to authenticated
  using (
    public.current_access_role() = 'member'
    and visibility_code = 'province_members'
  );

-- Storage objects are readable only when their metadata row is visible to the
-- caller. The bucket remains private.
drop policy if exists province_documents_storage_authenticated_read on storage.objects;
drop policy if exists province_documents_storage_role_read on storage.objects;
create policy province_documents_storage_role_read on storage.objects
  for select to authenticated using (
    bucket_id = 'province-documents'
    and exists (
      select 1
      from public.province_documents document
      where document.storage_path = storage.objects.name
    )
  );

comment on table public.app_user_access is
  'UUID-based auth user to religious member mapping and application persona. Canonical status is stored separately.';
