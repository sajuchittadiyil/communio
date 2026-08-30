import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608290008_complete_member_safe_profiles.sql',
  ).readAsStringSync().toLowerCase();

  test('ministry profile payload restores the canonical type alias', () {
    expect(sql, contains("to_jsonb(ministry)->>'ministry_type'"));
    expect(sql, contains('public.get_member_ministries_safe() item'));
    expect(sql, isNot(contains('v_demo_')));
  });

  test('community payload exposes modeled safe identity fields', () {
    for (final field in [
      'description',
      'patron_saint_name',
      'motto',
      'mission_statement',
      'vision_statement',
      'apostolic_focus',
      'community_values',
      'founding_story',
      'history_summary',
    ]) {
      expect(sql, contains("'$field'"), reason: field);
    }
  });

  test(
    'other-member payload adds safe DOB and origin without private joins',
    () {
      expect(sql, contains("'date_of_birth'"));
      expect(sql, contains("'birthplace'"));
      expect(sql, contains("- 'address' - 'city'"));
      for (final restricted in [
        'member_home_contacts',
        'member_family',
        'province_documents',
        'will',
        'vault',
      ]) {
        expect(sql, isNot(contains(restricted)), reason: restricted);
      }
    },
  );

  test('all completion RPCs remain authenticated-only', () {
    expect(RegExp('from public, anon').allMatches(sql), hasLength(3));
    expect(RegExp('to authenticated').allMatches(sql), hasLength(3));
    expect(sql, isNot(contains('service_role')));
  });
}
