import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608290006_restore_member_safe_browse_scope.sql',
  ).readAsStringSync().toLowerCase();

  test(
    'Member and Superior share Province-wide safe ministry browse source',
    () {
      expect(sql, contains("caller_role in ('member', 'community_superior')"));
      expect(sql, contains('from public.v_member_ministries_safe ministry'));
      expect(sql, isNot(contains('v_community_superior_ministries_safe')));
    },
  );

  test('safe other profile includes origin and strips postal address', () {
    expect(sql, contains("- 'address' - 'city'"));
    expect(sql, contains("'native_place'"));
    expect(sql, contains("'home_parish'"));
    expect(sql, contains("'diocese'"));
    expect(sql, isNot(contains("'home_contacts'")));
    expect(sql, isNot(contains("'family'")));
  });

  test('new browse RPCs remain anonymous-denied', () {
    expect(sql, contains('get_member_ministries_safe() from public, anon'));
    expect(
      sql,
      contains('get_other_member_profile_browse_safe(uuid)\nfrom public, anon'),
    );
    expect(sql, isNot(contains('service_role')));
  });

  test('Superior resident enrichment remains managed-community scoped', () {
    expect(
      sql,
      contains('get_community_superior_resident_profile_browse_safe'),
    );
    expect(sql, contains('public.current_managed_community_id()'));
    expect(sql, contains("= 'community_superior'"));
  });
}
