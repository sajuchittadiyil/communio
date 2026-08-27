-- Presentation-only photo overlay for the eight exact alias matches in the
-- first Sisters headshot batch. Canonical members.photo_url remains untouched.
with verified(member_id, display_name, photo_path) as (
  values
    ('f6890db9-b7d9-4bb0-bfa8-a07bb67c7185'::uuid, 'Agnes Kurisingal', 'sisters-demo/sr_agnes_kurisingal.webp'),
    ('1604a147-3179-4468-ac14-9d32d95053b1'::uuid, 'Agnes Stephenraj', 'sisters-demo/sr_agnes_stephenraj.webp'),
    ('b7acd1fe-f3d9-40e0-97bf-5ca2a90c3c00'::uuid, 'Agnes Varghese', 'sisters-demo/sr_agnes_varghese.webp'),
    ('cc419d5e-ee57-4dff-80e7-b335f0e80b18'::uuid, 'Aileen Gomes', 'sisters-demo/sr_aileen_gomes.webp'),
    ('2eddd18b-1689-4414-9763-7964fc52ff59'::uuid, 'Alphonsa Rozario', 'sisters-demo/sr_alphonsa_rozario.webp'),
    ('7f20b0f7-3c57-4b29-beb5-11136c7b2078'::uuid, 'Amala Costa', 'sisters-demo/sr_amala_costa.webp'),
    ('b1e441ac-8982-4bc0-bd74-9f83426e53f9'::uuid, 'Ancy Dutta', 'sisters-demo/sr_ancy_dutta.webp'),
    ('08059a79-324b-41ac-a8bd-a438173be5e0'::uuid, 'Anita Bose', 'sisters-demo/sr_anita_bose.webp')
)
update public.demo_persona_member_aliases alias
set photo_path = verified.photo_path
from verified
where alias.persona_code = 'sisters'
  and alias.member_id = verified.member_id
  and alias.display_name = verified.display_name
  and alias.active;

do $$
begin
  if (
    select count(*) from public.demo_persona_member_aliases
    where persona_code = 'sisters'
      and photo_path in (
        'sisters-demo/sr_agnes_kurisingal.webp',
        'sisters-demo/sr_agnes_stephenraj.webp',
        'sisters-demo/sr_agnes_varghese.webp',
        'sisters-demo/sr_aileen_gomes.webp',
        'sisters-demo/sr_alphonsa_rozario.webp',
        'sisters-demo/sr_amala_costa.webp',
        'sisters-demo/sr_ancy_dutta.webp',
        'sisters-demo/sr_anita_bose.webp'
      )
  ) <> 8 then
    raise exception 'Expected exactly eight verified Sisters photo mappings';
  end if;
end $$;
