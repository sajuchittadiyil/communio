-- Complete presentation aliases without changing canonical identity records.

alter table public.demo_persona_identities
  add column if not exists founder_name text,
  add column if not exists patron_saint_name text;

update public.demo_persona_identities
set founder_name = 'Mother Teresa of Communion',
    patron_saint_name = 'Our Lady of Communion'
where persona_code = 'sisters';

with approved(canonical_name) as (
  values
    ('Thomas Mathew'), ('John Kuriakose'), ('Dominic Kurian'),
    ('Paul Sebastian'), ('Francis Thomas'), ('Sebastian Fernandes'),
    ('Felix Xalxo'), ('Roy Noronha'), ('Anthony Minz'),
    ('Joseph Kochuparambil'), ('Augustine Palackal'), ('Joseph Vadakkel'),
    ('Thomas Kottaram'), ('Paul Thekkekara'), ('George Mundackal'),
    ('Albert Kindo'), ('Thomas Kochupurackal'), ('George Nedumkallel')
), candidates as (
  select alias.member_id,
         coalesce(nullif(regexp_replace(member.display_name, '^.*\s+', ''), ''), member.display_name) as surname,
         row_number() over (order by member.religious_id, member.id) as position
  from public.demo_persona_member_aliases alias
  join public.members member on member.id = alias.member_id
  left join approved on approved.canonical_name = member.display_name
  where alias.persona_code = 'sisters' and approved.canonical_name is null
), names as (
  select array[
    'Agnes','Aileen','Alphonsa','Amala','Ancy','Anita','Anne','Beena',
    'Bernadette','Catherine','Celestine','Clara','Deepa','Elsa','Emma',
    'Evelyn','Fabiola','Grace','Irene','Jacintha','Jessy','Joan','Jyothi',
    'Karuna','Lilly','Lucy','Mercy','Nancy','Nirmala','Philomena','Prabha',
    'Rani','Reena','Rosalia','Sally','Shalini','Sheela','Sophia','Susan',
    'Vimala','Vincy'
  ]::text[] as values
)
update public.demo_persona_member_aliases alias
set display_name = names.values[
  1 + ((candidates.position - 1) % array_length(names.values, 1))::integer
] || ' ' || candidates.surname
from candidates, names
where alias.persona_code = 'sisters'
  and alias.member_id = candidates.member_id;

-- Reassert the mapping for installations where the Auth user was created after
-- the initial persona migration. Authorization remains the Provincial role.
insert into public.app_user_access (
  auth_user_id, access_role, member_id, persona_code, active
)
select auth_user.id, 'provincial', null, 'sisters', true
from auth.users auth_user
where lower(auth_user.email) = 'sister@communio.com'
on conflict (auth_user_id) do update set
  access_role = 'provincial', member_id = null,
  persona_code = 'sisters', active = true;
