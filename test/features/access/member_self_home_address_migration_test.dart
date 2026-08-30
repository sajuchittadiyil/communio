import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608290005_restore_member_self_home_address.sql',
  ).readAsStringSync().toLowerCase();

  test('self home address remains caller-bound', () {
    expect(sql, contains('access.auth_user_id = auth.uid()'));
    expect(sql, contains('item.member_id = member.id'));
    expect(sql, isNot(contains('target_member_id')));
    expect(
      sql,
      contains("access.access_role in ('member', 'community_superior')"),
    );
  });

  test('home address variants are returned explicitly', () {
    expect(sql, contains("to_jsonb(item)->>'address'"));
    expect(sql, contains("to_jsonb(item)->>'home_address'"));
    expect(sql, contains("to_jsonb(item)->>'formatted_address'"));
  });

  test('anonymous execution remains revoked', () {
    expect(sql, contains('get_member_self_origin_safe() from public, anon'));
    expect(sql, isNot(contains('service_role')));
  });
}
