import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608290003_restore_member_origin_and_ministries.sql',
  ).readAsStringSync().toLowerCase();

  test('self origin accepts no target member identifier', () {
    expect(sql, contains('get_member_self_origin_safe()'));
    expect(sql, contains('access.auth_user_id = auth.uid()'));
    expect(sql, contains('origin.member_id = access.member_id'));
    expect(sql, isNot(contains('target_member_id')));
  });

  test('initial ministry RPC distinguishes Member and Superior scopes', () {
    expect(sql, contains("caller_role = 'member'"));
    expect(sql, contains('public.v_member_ministries_safe'));
    expect(sql, contains("caller_role = 'community_superior'"));
    expect(sql, contains('public.v_community_superior_ministries_safe'));
    expect(sql, contains("using errcode = '42501'"));
  });

  test('both RPCs deny anonymous execution', () {
    expect(sql, contains('get_member_self_origin_safe() from public, anon'));
    expect(sql, contains('get_member_ministries_safe() from public, anon'));
    expect(sql, isNot(contains('service_role')));
  });
}
