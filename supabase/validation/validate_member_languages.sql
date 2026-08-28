begin;

do $$
declare sample public.member_languages%rowtype;
begin
  if not exists (select 1 from public.member_languages) then
    raise exception 'member_languages has no demo records';
  end if;
  if exists (
    select member_id, lower(btrim(language_name))
    from public.member_languages
    group by member_id, lower(btrim(language_name)) having count(*) > 1
  ) then
    raise exception 'duplicate member/language records found';
  end if;
  if exists (
    select member_id from public.member_languages where is_primary
    group by member_id having count(*) > 1
  ) then
    raise exception 'multiple primary languages found';
  end if;
  if exists (
    select 1 from public.member_languages language
    left join public.members member on member.id = language.member_id
    where member.id is null
  ) then
    raise exception 'orphan language member reference found';
  end if;
  if exists (
    select 1 from public.v_member_languages
    where to_jsonb(v_member_languages) ?| array[
      'mobile', 'whatsapp', 'official_email', 'address', 'family', 'notes'
    ]
  ) then
    raise exception 'reporting view exposes a private field';
  end if;

  select * into sample from public.member_languages limit 1;
  begin
    insert into public.member_languages (
      congregation_id, province_id, member_id, language_name, is_primary
    ) values (
      sample.congregation_id, sample.province_id, sample.member_id,
      sample.language_name, false
    );
    raise exception 'duplicate member/language constraint did not reject';
  exception when unique_violation then null;
  end;

  if exists (select 1 from public.member_languages where member_id = sample.member_id and is_primary) then
    begin
      insert into public.member_languages (
        congregation_id, province_id, member_id, language_name, is_primary
      ) values (
        sample.congregation_id, sample.province_id, sample.member_id,
        'Validation Primary', true
      );
      raise exception 'one-primary constraint did not reject';
    exception when unique_violation then null;
    end;
  end if;

  begin
    insert into public.member_languages (
      congregation_id, province_id, member_id, language_name, proficiency_level_code
    ) values (
      sample.congregation_id, sample.province_id, sample.member_id,
      'Validation Proficiency', 'EXPERT'
    );
    raise exception 'proficiency constraint did not reject';
  exception when check_violation then null;
  end;

  begin
    insert into public.member_languages (
      congregation_id, province_id, member_id, language_name
    ) values (
      sample.congregation_id, sample.province_id, gen_random_uuid(),
      'Validation Foreign Key'
    );
    raise exception 'member foreign key did not reject';
  exception when foreign_key_violation then null;
  end;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'member_languages'
      and policyname = 'member_languages_scoped_read'
      and roles @> array['authenticated']::name[]
      and qual like '%congregation_id%'
      and qual like '%province_id%'
      and qual like '%auth.uid()%'
  ) then
    raise exception 'caller-bound province-scoped read policy is missing';
  end if;

  if coalesce((
    select c.reloptions @> array['security_invoker=true']
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'v_member_languages'
  ), false) is not true then
    raise exception 'reporting view is not security-invoker';
  end if;
end $$;

rollback;
