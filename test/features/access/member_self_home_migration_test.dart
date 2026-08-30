import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608290004_add_member_self_home_details.sql',
  ).readAsStringSync().toLowerCase();

  test('home details remain bound to the signed-in member', () {
    expect(sql, contains('access.auth_user_id = auth.uid()'));
    expect(sql, contains('item.member_id = member.id'));
    expect(sql, isNot(contains('target_member_id')));
    expect(
      sql,
      contains("access.access_role in ('member', 'community_superior')"),
    );
  });

  test('only origin, home contact and family sources are added', () {
    expect(sql, contains('public.member_native_details'));
    expect(sql, contains('public.member_home_contacts'));
    expect(sql, contains('public.member_family'));
    for (final restricted in [
      'documents',
      'will',
      'vault',
      'digital_safe',
      'confidential_notes',
      'member_leave',
    ]) {
      expect(sql, isNot(contains('public.$restricted')), reason: restricted);
    }
  });

  test('anonymous execution remains revoked', () {
    expect(sql, contains('get_member_self_origin_safe() from public, anon'));
    expect(sql, isNot(contains('service_role')));
  });
}
