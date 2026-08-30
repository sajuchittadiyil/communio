import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608290002_expand_community_superior_resident_profile.sql',
  ).readAsStringSync().toLowerCase();

  test('resident enrichment remains caller and managed-community scoped', () {
    expect(sql, contains('public.current_managed_community_id()'));
    expect(
      sql,
      contains(
        "public.current_application_access_role() = 'community_superior'",
      ),
    );
    expect(sql, contains('assignment.from_date <= current_date'));
    expect(sql, contains('assignment.to_date >= current_date'));
  });

  test('pastoral sections are explicit and restricted sources stay absent', () {
    expect(sql, contains("'home_contacts'"));
    expect(sql, contains("'family'"));
    expect(sql, contains("'languages'"));
    expect(sql, contains('public.member_home_contacts'));
    expect(sql, contains('public.member_family'));
    expect(sql, contains('public.member_languages'));
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

  test('RPC remains unavailable to anonymous callers', () {
    expect(
      sql,
      contains(
        'public.get_community_superior_resident_profile_safe(uuid)\nfrom public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'public.get_community_superior_resident_profile_safe(uuid)\nto authenticated',
      ),
    );
  });
}
