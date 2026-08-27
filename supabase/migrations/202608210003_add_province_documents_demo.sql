-- Province institutional documents. Demo seed records are explicitly fictional.
create table if not exists public.province_documents (
  id uuid primary key default gen_random_uuid(),
  document_code text unique,
  title text not null,
  category_code text not null check (category_code in (
    'provincial_administration', 'governance_chapter', 'community',
    'ministry', 'formation', 'finance', 'personnel', 'meetings', 'policies',
    'property_compliance', 'strategy'
  )),
  document_type text not null,
  document_date date not null,
  description text,
  related_entity_type text,
  related_entity_id text,
  related_entity_name text,
  visibility_code text not null default 'provincial_team' check (
    visibility_code in ('provincial_team', 'council', 'community_leadership', 'province_members', 'restricted')
  ),
  file_name text,
  storage_path text,
  file_url text,
  file_extension text not null default 'pdf',
  file_size_bytes bigint,
  uploaded_by uuid references auth.users(id),
  is_demo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.province_documents enable row level security;

drop policy if exists province_documents_authenticated_read on public.province_documents;
create policy province_documents_authenticated_read on public.province_documents
  for select to authenticated using (true);

insert into storage.buckets (id, name, public, allowed_mime_types)
values ('province-documents', 'province-documents', false, array['application/pdf'])
on conflict (id) do update set public = false, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists province_documents_storage_authenticated_read on storage.objects;
create policy province_documents_storage_authenticated_read on storage.objects
  for select to authenticated using (bucket_id = 'province-documents');

insert into public.province_documents
  (document_code, title, category_code, document_type, document_date, description,
   related_entity_type, related_entity_id, related_entity_name, visibility_code, file_name)
values
('DOC-001','Annual Province Report 2025-26','provincial_administration','Annual Report','2026-06-30','DEMO: Province-wide institutional review.',null,null,null,'provincial_team','annual_province_report_2025_26.pdf'),
('DOC-002','Provincial Circular - August 2026','provincial_administration','Circular','2026-08-18','DEMO: Province message, meetings and reminders.',null,null,null,'province_members','provincial_circular_august_2026.pdf'),
('DOC-003','Province Directory 2026','provincial_administration','Directory','2026-01-15','DEMO: Province directory index.',null,null,null,'province_members',null),
('DOC-004','Provincial Administration Review 2025-26','provincial_administration','Review','2026-07-10','DEMO: Administrative coordination review.',null,null,null,'provincial_team',null),
('DOC-005','Provincial Chapter Acts 2024','governance_chapter','Chapter Acts','2024-11-30','DEMO: Fictional chapter acts.',null,null,null,'province_members',null),
('DOC-006','Chapter Implementation Review 2025','governance_chapter','Implementation Review','2025-12-10','DEMO: Chapter implementation milestones.',null,null,null,'council',null),
('DOC-007','Provincial Council Decisions - July 2026','governance_chapter','Council Decisions','2026-07-28','DEMO: Fictional Council decision register.',null,null,null,'council',null),
('DOC-008','Budakata Mission Community Annual Report 2025-26','community','Community Report','2026-06-25','DEMO: Community life and mission report.','community','COM013','Budakata Mission Community','community_leadership','budakata_community_report_2025_26.pdf'),
('DOC-009','Morning Star Community Annual Report 2025-26','community','Community Report','2026-06-22','DEMO: Community annual report.','community','COM006','Morning Star Community','community_leadership',null),
('DOC-010','Mary Immaculate Novitiate Community Report 2025-26','community','Community Report','2026-06-20','DEMO: Novitiate community report.','community',null,'Mary Immaculate Novitiate','community_leadership',null),
('DOC-011','Budakata School Annual Report 2025-26','ministry','Ministry Report','2026-06-28','DEMO: Education ministry report.','ministry','MIN015','Budakata School','provincial_team','budakata_school_report_2025_26.pdf'),
('DOC-012','Sacred Heart Parish Pastoral Report 2025','ministry','Pastoral Report','2025-12-31','DEMO: Parish pastoral report.','ministry',null,'Sacred Heart Parish','provincial_team',null),
('DOC-013','St. Joseph Health Centre Activity Report 2025-26','ministry','Activity Report','2026-06-26','DEMO: Health ministry activities.','ministry',null,'St. Joseph Health Centre','provincial_team',null),
('DOC-014','Morning Star School Academic Report 2025-26','ministry','Academic Report','2026-06-24','DEMO: Academic programme report.','ministry','MIN007','Morning Star School','provincial_team',null),
('DOC-015','Province Formation Annual Report 2025-26','formation','Formation Report','2026-07-05','DEMO: Province formation overview.','formation',null,'Province Formation','provincial_team','province_formation_report_2025_26.pdf'),
('DOC-016','Novitiate Formation Report 2025-26','formation','Formation Report','2026-06-18','DEMO: Novitiate formation review.','formation',null,'Mary Immaculate Novitiate','provincial_team',null),
('DOC-017','Scholasticate Formation Evaluation 2025-26','formation','Evaluation','2026-06-17','DEMO: Scholasticate evaluation.','formation',null,'St. Antony Scholasticate','provincial_team',null),
('DOC-018','Vocation Promotion Annual Report 2025-26','formation','Annual Report','2026-06-16','DEMO: Vocation promotion report.','formation',null,'Province Vocation Promotion','provincial_team',null),
('DOC-019','Province Financial Summary 2025-26','finance','Financial Summary','2026-07-31','DEMO FIGURES: Not an audited statement.',null,null,null,'provincial_team','province_financial_summary_2025_26.pdf'),
('DOC-020','Ministry Audit Summary 2025-26','finance','Audit Summary','2026-07-20','DEMO: Not an audit opinion.',null,null,null,'provincial_team',null),
('DOC-021','Personnel & Appointment Circular - August 2026','personnel','Personnel Circular','2026-08-19','DEMO: Benign fictional movements.',null,null,null,'province_members','personnel_appointment_circular_august_2026.pdf'),
('DOC-022','Annual Personnel Movement Report 2025-26','personnel','Personnel Report','2026-07-08','DEMO: Ordinary fictional movements.',null,null,null,'provincial_team',null),
('DOC-023','Provincial Council Minutes - 20 August 2026','meetings','Meeting Minutes','2026-08-20','DEMO: Agenda, decisions and actions.',null,null,null,'council','provincial_council_minutes_2026_08_20.pdf'),
('DOC-024','Education Commission Minutes - July 2026','meetings','Meeting Minutes','2026-07-14','DEMO: Commission discussion and actions.',null,null,null,'provincial_team',null),
('DOC-025','Child Safeguarding Policy 2026','policies','Policy','2026-08-01','DEMO policy: Not legal certification.',null,null,null,'province_members','child_safeguarding_policy_2026.pdf'),
('DOC-026','Community Administration Guidelines','policies','Guidelines','2026-05-12','DEMO: Local administration guidance.',null,null,null,'community_leadership',null),
('DOC-027','Province Property Register Summary 2026','property_compliance','Register Summary','2026-04-30','DEMO: Restricted property summary.',null,null,null,'restricted',null),
('DOC-028','Province Strategic Plan 2026-2030','strategy','Strategic Plan','2026-08-10','DEMO: Province strategic priorities.',null,null,null,'province_members','province_strategic_plan_2026_2030.pdf')
on conflict (document_code) do update set
  title = excluded.title,
  category_code = excluded.category_code,
  document_type = excluded.document_type,
  document_date = excluded.document_date,
  description = excluded.description,
  related_entity_type = excluded.related_entity_type,
  related_entity_id = excluded.related_entity_id,
  related_entity_name = excluded.related_entity_name,
  visibility_code = excluded.visibility_code,
  file_name = excluded.file_name,
  updated_at = now();

comment on table public.province_documents is
  'Structured Province document metadata. Seeded rows are fictional Communio demonstration data.';
