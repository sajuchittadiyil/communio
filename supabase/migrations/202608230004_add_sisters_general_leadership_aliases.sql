-- Presentation-only aliases for General Administration records, keyed by the
-- canonical leadership UUID. Canonical leadership rows remain unchanged.

create table if not exists public.demo_persona_leader_aliases (
  persona_code text not null references public.demo_persona_identities(persona_code) on delete cascade,
  leader_id uuid not null references public.congregation_leadership(id) on delete cascade,
  display_name text not null,
  title text not null default 'Sr.',
  post_nominal text not null default 'SOLC',
  active boolean not null default true,
  primary key (persona_code, leader_id)
);

insert into public.demo_persona_leader_aliases (
  persona_code, leader_id, display_name, title, post_nominal, active
) values
  ('sisters', '30000000-0000-4000-8000-000000000001', 'Helena D’Souza', 'Sr.', 'SOLC', true),
  ('sisters', '30000000-0000-4000-8000-000000000002', 'Lucia Bianchi', 'Sr.', 'SOLC', true),
  ('sisters', '30000000-0000-4000-8000-000000000003', 'Maria Okafor', 'Sr.', 'SOLC', true),
  ('sisters', '30000000-0000-4000-8000-000000000004', 'Teresa Mendoza', 'Sr.', 'SOLC', true),
  ('sisters', '30000000-0000-4000-8000-000000000005', 'Claire Moreau', 'Sr.', 'SOLC', true)
on conflict (persona_code, leader_id) do update set
  display_name = excluded.display_name,
  title = excluded.title,
  post_nominal = excluded.post_nominal,
  active = excluded.active;

alter table public.demo_persona_leader_aliases enable row level security;
drop policy if exists persona_leader_alias_read_own on public.demo_persona_leader_aliases;
create policy persona_leader_alias_read_own on public.demo_persona_leader_aliases
for select to authenticated
using (active and persona_code = public.current_demo_persona());

revoke all on public.demo_persona_leader_aliases from public, anon;
grant select on public.demo_persona_leader_aliases to authenticated;
