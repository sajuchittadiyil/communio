-- Institution cover images are public presentation metadata. Store portable
-- object paths only; Flutter constructs the public URL from the bucket.

alter table public.communities
  add column if not exists cover_image_path text;

alter table public.ministries
  add column if not exists cover_image_path text;

insert into storage.buckets (id, name, public, allowed_mime_types)
values
  ('community-covers', 'community-covers', true,
   array['image/webp', 'image/jpeg', 'image/png']),
  ('ministry-covers', 'ministry-covers', true,
   array['image/webp', 'image/jpeg', 'image/png'])
on conflict (id) do update
set public = excluded.public,
    allowed_mime_types = excluded.allowed_mime_types;

-- Community mappings verified against v_demo_current_communities on
-- 2026-08-18.
update public.communities set cover_image_path = 'COM001_provincial_house.webp'
where id = 'e691925c-e3f2-46a4-8b7a-0e2e90fd046a';
update public.communities set cover_image_path = 'COM002_st_thomas_community.webp'
where id = '17711b76-b306-495b-adb3-855b71163d97';
update public.communities set cover_image_path = 'COM003_sacred_heart_community.webp'
where id = '5fdf8d6f-15fe-4292-8792-ac8307bb1dca';
update public.communities set cover_image_path = 'COM004_marianist_community.webp'
where id = '4aaa588c-d204-4d2c-9f57-3a310d9e2ddc';
update public.communities set cover_image_path = 'COM005_chaminade_community.webp'
where id = '1bf32746-92cd-42a5-8002-15590c6394a7';
update public.communities set cover_image_path = 'COM006_morning_star_community.webp'
where id = '4c46b712-6376-419f-82d8-d18275c45c68';
update public.communities set cover_image_path = 'COM007_nazareth_community.webp'
where id = '3b78c7ec-925a-418a-a0c3-ad7fc7fb63c1';
update public.communities set cover_image_path = 'COM008_st_anne_community.webp'
where id = 'd555d7ee-f4fe-4845-b569-89799bdfa287';
update public.communities set cover_image_path = 'COM009_st_francis_xavier_community.webp'
where id = '7b2433d6-2774-4746-878f-cb997534d92e';
update public.communities set cover_image_path = 'COM010_chaminade_vocation_house.webp'
where id = '9f51dc2f-1631-4987-8b0e-1c7f6b1ed64c';
update public.communities set cover_image_path = 'COM011_mary_immaculate_novitiate.webp'
where id = 'fa17728e-84e6-4c05-a2dd-76ccefda61ef';
update public.communities set cover_image_path = 'COM012_chaminade_scholasticate.webp'
where id = '7fe2f76c-2a23-46c6-b522-c2ef6fa1f54a';
update public.communities set cover_image_path = 'COM013_budakata_mission_community.webp'
where id = 'ff1fc6d3-51e4-4fb2-a359-6cde267f2d92';
update public.communities set cover_image_path = 'COM014_st_alphonsa_community.webp'
where id = 'ec2a5963-cb15-4a12-ac87-be2c4d7687d4';
update public.communities set cover_image_path = 'COM015_st_joachim_senior_community.webp'
where id = 'fd227b7c-2190-43e5-97ac-dc9a79d0d001';
update public.communities set cover_image_path = 'COM016_vidhya_deep_theologate.webp'
where id = 'cc8d0550-dc93-4848-88e9-c64343eae5b6';

-- Ministry mappings verified against v_demo_ministry_operational on
-- 2026-08-18.
update public.ministries set cover_image_path = 'MIN001_provincial_house.webp'
where id = '95addf95-0ee5-44df-b09a-bb7cb64b6d25';
update public.ministries set cover_image_path = 'MIN002_st_joseph_school.webp'
where id = 'a03222bc-511a-4c76-942c-0dc151bb30d0';
update public.ministries set cover_image_path = 'MIN003_chaminade_college.webp'
where id = '9bd6f336-6701-4bf7-b999-e441946247c6';
update public.ministries set cover_image_path = 'MIN004_sacred_heart_parish.webp'
where id = '6dc2a844-1db9-47ea-a32e-e74efcb0bd2a';
update public.ministries set cover_image_path = 'MIN005_marianist_high_school.webp'
where id = '10e1e115-aea5-46d2-89fc-329545addf7d';
update public.ministries set cover_image_path = 'MIN006_st_joseph_school_rourkela.webp'
where id = '32554b10-e542-4748-98e8-af570eb03185';
update public.ministries set cover_image_path = 'MIN007_morning_star_school.webp'
where id = '8a6e8a83-c954-426d-993e-5e1d83579ab0';
update public.ministries set cover_image_path = 'MIN008_nazareth_technical_institute.webp'
where id = '4e07214f-e7ab-4aa1-b0fe-b5c3f689095e';
update public.ministries set cover_image_path = 'MIN009_st_anne_school.webp'
where id = 'd06f85f1-b85b-488f-aae6-2d1dfc203973';
update public.ministries set cover_image_path = 'MIN010_st_joseph_academy_kolkata.webp'
where id = 'd7cb2e79-44b5-4a25-a9c9-af112cb9dd27';
update public.ministries set cover_image_path = 'MIN011_vocation_office.webp'
where id = 'de1322c1-2867-4ab6-acc4-032f8cfc8e53';
update public.ministries set cover_image_path = 'MIN012_aspirancy_postulancy_program.webp'
where id = 'f78041f9-6938-42bf-93fe-bf1e19aa4ead';
update public.ministries set cover_image_path = 'MIN013_novitiate_program.webp'
where id = 'c348e938-274f-4a0a-a213-5be0fb0f9aac';
update public.ministries set cover_image_path = 'MIN014_scholasticate_program.webp'
where id = '3d4a3820-592f-43a9-b98a-00feedcd90b9';
update public.ministries set cover_image_path = 'MIN015_budakata_school.webp'
where id = 'b881baf7-4a3a-4251-87d2-e840375b79b2';
update public.ministries set cover_image_path = 'MIN016_st_alphonsa_retreat_centre.webp'
where id = '99b97d51-8fcf-4012-a85a-decdd9a3e260';
update public.ministries set cover_image_path = 'MIN017_chaminade_social_service_centre.webp'
where id = 'b3541e98-255e-4be0-8167-0a6e3d6b04ec';
update public.ministries set cover_image_path = 'MIN018_st_joseph_health_centre.webp'
where id = '05ac8667-9bee-4e3b-8bac-4b18e16d0217';
update public.ministries set cover_image_path = 'MIN019_our_lady_of_peace_parish.webp'
where id = '1228afac-64d4-48b6-bfdb-d2e3c3569c2e';
update public.ministries set cover_image_path = 'MIN020_st_marys_parish.webp'
where id = 'd27ce6a4-bf70-4470-94e6-0332e090cabd';
update public.ministries set cover_image_path = 'MIN021_marianist_youth_ministry.webp'
where id = '78d5d361-4761-429f-9952-73b08a1253e2';
update public.ministries set cover_image_path = 'MIN022_chaminade_hostel.webp'
where id = 'bc2b9cde-62e7-4c4e-b6ff-e0331385856b';
update public.ministries set cover_image_path = 'MIN023_st_joseph_skill_centre.webp'
where id = 'c6a1de47-049d-4d25-ba27-7828a287a02e';
update public.ministries set cover_image_path = 'MIN024_province_communications_office.webp'
where id = '566df733-f9f5-4d6c-8501-0b85d5c49ba8';
