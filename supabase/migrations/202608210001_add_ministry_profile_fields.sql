-- Nullable institutional identity and history fields for Ministry Profile.
-- List values follow the established Community Profile text[] convention.

alter table public.ministries
  add column if not exists motto text,
  add column if not exists mission_statement text,
  add column if not exists vision_statement text,
  add column if not exists patron_saint_name text,
  add column if not exists feast_day smallint check (feast_day between 1 and 31),
  add column if not exists feast_month smallint check (feast_month between 1 and 12),
  add column if not exists apostolic_focus text[],
  add column if not exists ministry_values text[],
  add column if not exists founding_story text,
  add column if not exists history_summary text;

comment on column public.ministries.apostolic_focus is
  'Structured apostolic focus labels displayed on Ministry Profile.';
comment on column public.ministries.ministry_values is
  'Structured ministry value labels displayed on Ministry Profile.';

-- Communio demo dataset: seed the first structured Ministry Profile only.
-- The Sacred Heart solemnity is movable, so no fixed feast day/month is stored.
update public.ministries
set patron_saint_name = 'Sacred Heart of Jesus',
    feast_day = null,
    feast_month = null,
    motto = 'Called to Love · Sent to Serve',
    mission_statement = 'To nurture a worshipping parish community through liturgy, pastoral care, catechesis, and accompaniment of families and young people.',
    vision_statement = 'A faith-filled, welcoming parish united in communion and sent in compassionate service.',
    apostolic_focus = array[
      'Liturgy',
      'Pastoral Care',
      'Catechesis',
      'Family Ministry',
      'Youth Ministry'
    ]::text[],
    ministry_values = array[
      'Faith',
      'Communion',
      'Service',
      'Compassion',
      'Mission'
    ]::text[],
    founding_story = 'Established in 1988, Sacred Heart Parish serves the Catholic community in Ranchi through a shared life of worship, pastoral accompaniment, and outreach.',
    history_summary = 'Across the years, the parish has continued to develop its liturgical, catechetical, family, and youth ministries in response to the pastoral needs of the local community.'
where id = '6dc2a844-1db9-47ea-a32e-e74efcb0bd2a';
