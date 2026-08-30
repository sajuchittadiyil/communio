import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608290007_remove_legacy_ministry_dependency.sql',
  ).readAsStringSync().toLowerCase();

  test('ministry browse uses explicit safe base-table projection', () {
    expect(sql, contains('from public.ministries ministry'));
    expect(sql, contains('public.member_ministry_assignments assignment'));
    expect(sql, isNot(contains('v_demo_')));
    expect(sql, isNot(contains('v_member_ministries_safe')));
  });

  test('Member and Superior are allowed while anonymous remains denied', () {
    expect(sql, contains("('member', 'community_superior')"));
    expect(sql, contains("using errcode = '42501'"));
    expect(sql, contains('from public, anon'));
    expect(sql, contains('to authenticated'));
    expect(sql, isNot(contains('service_role')));
  });

  test('other-member origin normalizes safe schema variants', () {
    for (final field in [
      'native_place',
      'place_of_origin',
      'home_town',
      'native_city',
      'native_parish',
      'native_diocese',
    ]) {
      expect(sql, contains("'$field'"), reason: field);
    }
    expect(sql, contains("- 'address' - 'city'"));
    expect(sql, isNot(contains('member_home_contacts')));
    expect(sql, isNot(contains('member_family')));
  });
}
