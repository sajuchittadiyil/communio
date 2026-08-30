import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/202608290001_secure_legacy_demo_views.sql',
  ).readAsStringSync().toLowerCase();

  const views = <String>[
    'v_demo_current_communities',
    'v_demo_current_office_holders',
    'v_demo_formation_pipeline',
    'v_demo_member_attention_events',
    'v_demo_member_directory',
    'v_demo_member_public_contacts',
    'v_demo_ministry_operational',
    'v_demo_province_pulse',
    'v_demo_recent_appointments',
    'v_demo_upcoming_birthdays',
    'v_demo_upcoming_feast_days',
  ];

  test('every legacy demo view becomes caller-invoker', () {
    for (final view in views) {
      expect(
        migration,
        contains('alter view public.$view\n  set (security_invoker = true)'),
        reason: view,
      );
    }
  });

  test(
    'anonymous and PUBLIC access are revoked before authenticated SELECT',
    () {
      expect(migration, contains('from anon, public;'));
      expect(migration, contains('from authenticated;'));
      expect(migration, contains('to authenticated;'));
      expect(migration, isNot(contains('service_role')));
    },
  );

  test('migration changes authorization only', () {
    for (final statement in ['insert ', 'update ', 'delete ', 'drop view']) {
      expect(migration, isNot(contains(statement)), reason: statement);
    }
  });
}
