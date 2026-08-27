import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608230005_add_provincial_safe_read_api.sql',
  ).readAsStringSync();
  final moduleSql = File(
    'supabase/migrations/202608240002_complete_provincial_safe_module_reads.sql',
  ).readAsStringSync();
  final sistersPhotoSql = File(
    'supabase/migrations/202608240003_map_verified_sisters_demo_photos.sql',
  ).readAsStringSync();

  test('Provincial RPCs use explicit caller-bound role authorization', () {
    expect(sql, contains('access.auth_user_id = auth.uid()'));
    expect(sql, contains('access.active'));
    expect(sql, contains("access.access_role = 'provincial'"));
    expect(sql, contains("errcode = '42501'"));
    expect(RegExp(r'persona_code\s*=').hasMatch(sql), isFalse);
  });

  test('directory RPC is canonical, security definer and authenticated-only', () {
    expect(sql, contains('get_provincial_member_directory_safe()'));
    expect(sql, contains('security definer set search_path = public'));
    expect(sql, contains('from public.members member'));
    expect(sql, contains('member.id'));
    expect(
      sql,
      contains(
        'revoke all on function public.get_provincial_member_directory_safe() from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.get_provincial_member_directory_safe() to authenticated',
      ),
    );
  });

  test('profile RPC accepts only canonical UUID and is role gated', () {
    expect(
      sql,
      contains('get_provincial_member_profile_safe(\n  p_member_id uuid'),
    );
    expect(sql, contains('where member.id = p_member_id'));
    expect(sql, isNot(contains("where member.display_name =")));
    expect(
      sql,
      contains(
        'revoke all on function public.get_provincial_member_profile_safe(uuid) from public, anon',
      ),
    );
  });

  test('leadership RPCs expose canonical member UUIDs', () {
    expect(sql, contains('superior_member_id uuid'));
    expect(sql, contains('accountant_member_id uuid'));
    expect(sql, contains('head_member_id uuid'));
    expect(sql, contains('get_provincial_communities_safe()'));
    expect(sql, contains('get_provincial_ministries_safe()'));
  });

  test(
    'all Provincial modules use the shared role gate and canonical UUIDs',
    () {
      for (final function in [
        'get_provincial_communities_safe',
        'get_provincial_ministries_safe',
        'get_provincial_formation_safe',
        'get_provincial_leadership_safe',
        'get_provincial_profile_counts_safe',
      ]) {
        expect(moduleSql, contains(function));
      }
      expect(
        'perform public.require_current_provincial_access()'.allMatches(
          moduleSql,
        ),
        hasLength(5),
      );
      expect(moduleSql, contains('security definer set search_path = public'));
      expect(RegExp(r'persona_code\s*=').hasMatch(moduleSql), isFalse);
      expect(moduleSql, contains("'member_id',m.id"));
      expect(moduleSql, contains("'head_member_id',head.member_id"));
      expect(moduleSql, contains('from public.v_demo_formation_pipeline f'));
    },
  );

  test('module RPCs reject anonymous callers', () {
    for (final function in [
      'get_provincial_communities_safe',
      'get_provincial_ministries_safe',
      'get_provincial_formation_safe',
      'get_provincial_leadership_safe',
      'get_provincial_profile_counts_safe',
    ]) {
      expect(
        moduleSql,
        contains('revoke all on function public.$function() from public, anon'),
      );
      expect(
        moduleSql,
        contains(
          'grant execute on function public.$function() to authenticated',
        ),
      );
    }
  });

  test('Sisters photo overlay updates aliases only by canonical UUID', () {
    expect(sistersPhotoSql, contains('demo_persona_member_aliases alias'));
    expect(sistersPhotoSql, contains("alias.persona_code = 'sisters'"));
    expect(sistersPhotoSql, contains('alias.member_id = verified.member_id'));
    expect(sistersPhotoSql, contains('set photo_path = verified.photo_path'));
    expect(sistersPhotoSql, isNot(contains('update public.members')));
    expect(
      RegExp(r"sisters-demo/sr_[a-z_]+\.webp").allMatches(sistersPhotoSql),
      hasLength(16),
    );
  });
}
