import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608280001_add_governance_bodies.sql',
  ).readAsStringSync();

  test('governance tables are normalized, scoped, and effective-dated', () {
    expect(
      sql,
      contains('create table if not exists public.governance_bodies'),
    );
    expect(
      sql,
      contains('create table if not exists public.governance_body_memberships'),
    );
    expect(sql, contains('congregation_id uuid not null'));
    expect(sql, contains('province_id uuid not null'));
    expect(
      sql,
      contains('member_id uuid not null references public.members(id)'),
    );
    expect(sql, contains('start_date date not null'));
    expect(sql, contains('end_date date'));
    expect(sql, isNot(contains('current_member boolean')));
  });

  test('RLS is caller, role, and Province scoped', () {
    expect(
      sql,
      contains(
        'alter table public.governance_bodies enable row level security',
      ),
    );
    expect(sql, contains('access.auth_user_id = auth.uid()'));
    expect(sql, contains("access.access_role = 'provincial'"));
    expect(
      sql,
      contains('access.congregation_id = governance_bodies.congregation_id'),
    );
    expect(sql, contains('access.province_id = governance_bodies.province_id'));
    expect(sql, isNot(contains('service_role execution')));
  });

  test('reporting views are security invokers and expose safe fields', () {
    for (final view in [
      'v_governance_body_directory',
      'v_governance_body_current_members',
      'v_governance_body_membership_history',
    ]) {
      expect(sql, contains('view public.$view'));
    }
    expect('security_invoker = true'.allMatches(sql), hasLength(3));
    expect(sql, contains('religious_id'));
    expect(sql, isNot(contains('date_of_birth')));
    expect(sql, isNot(contains('member_home_contacts')));
  });

  test('safe RPC is authenticated-only and explicitly scope gated', () {
    expect(sql, contains('get_provincial_governance_bodies_safe()'));
    expect(sql, contains("errcode = '42501'"));
    expect(
      sql,
      contains(
        'revoke all on function public.get_provincial_governance_bodies_safe() from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.get_provincial_governance_bodies_safe() to authenticated',
      ),
    );
  });

  test('demo includes required bodies, current terms, and chair history', () {
    for (final body in [
      'Provincial Council',
      'Education Commission',
      'Finance Commission',
      'Sustainability Commission',
      'Formation Commission',
    ]) {
      expect(sql, contains(body));
    }
    expect(sql, contains('prevent_overlapping_governance_membership_terms'));
    expect(sql, contains('Demo Education Commission term 2021–2024'));
    expect(sql, contains('Demo Education Commission term 2024–2027'));
  });
}
