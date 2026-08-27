import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/app_access_context.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';
import '../../demo_persona/models/demo_persona.dart';

abstract interface class AccessRepository {
  Future<AppAccessContext> resolveCurrentAccess();
}

class AccessResolutionException implements Exception {
  const AccessResolutionException();
}

class SupabaseAccessRepository implements AccessRepository {
  const SupabaseAccessRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<AppAccessContext> resolveCurrentAccess() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AccessResolutionException();
    final rows = await _client
        .from('app_user_access')
        .select('member_id,access_role,persona_code')
        .eq('auth_user_id', userId)
        .eq('active', true)
        .limit(2);
    if (rows.length != 1) throw const AccessResolutionException();
    final row = rows.single;
    final persona = DemoPersonaCode.fromCode(row['persona_code']);
    if (kDebugMode && persona == DemoPersona.sisters) {
      debugPrint(
        '[SistersPersona] access_role=${row['access_role']} '
        'persona_code=${persona.code}',
      );
    }
    await _configurePersona(persona);
    return switch (row['access_role']?.toString()) {
      'provincial' => AppAccessContext.provincial(persona: persona),
      'member' when row['member_id'] != null => AppAccessContext(
        role: AccessRole.member,
        memberId: row['member_id'].toString(),
        persona: persona,
      ),
      'community_superior' when row['member_id'] != null =>
        await _resolveCommunitySuperior(row['member_id'].toString(), persona),
      _ => throw const AccessResolutionException(),
    };
  }

  Future<AppAccessContext> _resolveCommunitySuperior(
    String memberId,
    DemoPersona persona,
  ) async {
    final raw = await _client.rpc('get_community_superior_context');
    if (raw is! Map) throw const AccessResolutionException();
    final context = Map<String, dynamic>.from(raw);
    if (context['member_id']?.toString() != memberId ||
        context['community_id'] == null) {
      throw const AccessResolutionException();
    }
    return AppAccessContext(
      role: AccessRole.communitySuperior,
      memberId: memberId,
      managedCommunityId: context['community_id'].toString(),
      managedCommunityName: context['community_name']?.toString(),
      communityResponsibilityCode: context['responsibility_code']?.toString(),
      persona: persona,
    );
  }

  Future<void> _configurePersona(DemoPersona persona) async {
    if (persona == DemoPersona.standard) {
      DemoPersonaPresenter.configure(resolvedPersona: persona);
      return;
    }
    final identityRow = await _client
        .from('demo_persona_identities')
        .select()
        .eq('persona_code', persona.code)
        .maybeSingle();
    final aliasRows = await _client
        .from('demo_persona_member_aliases')
        .select()
        .eq('persona_code', persona.code)
        .eq('active', true);
    final memberRowsRaw = await _client.rpc(
      'get_provincial_member_directory_safe',
    );
    final memberRows = List<Map<String, dynamic>>.from(memberRowsRaw as List);
    final leaderRows = await _client
        .from('demo_persona_leader_aliases')
        .select()
        .eq('persona_code', persona.code)
        .eq('active', true);
    if (identityRow == null) throw const AccessResolutionException();
    final aliases = <String, DemoPersonaMemberAlias>{};
    for (final raw in aliasRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['member_id']?.toString();
      final name = row['display_name']?.toString();
      if (id == null || name == null) continue;
      aliases[id] = DemoPersonaMemberAlias(
        memberId: id,
        displayName: name,
        title: row['ecclesiastical_title']?.toString() ?? 'Sr.',
        photoPath: _personaPhotoUrl(row['photo_path']?.toString()),
        roleDisplayOverride: row['role_display_override']?.toString(),
      );
    }
    final canonicalNames = <String, String>{};
    for (final raw in memberRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['member_id']?.toString();
      final name = row['display_name']?.toString();
      if (id != null && name != null) canonicalNames[id] = name;
    }
    final leaderAliases = <String, DemoPersonaLeaderAlias>{};
    for (final row in leaderRows) {
      final id = row['leader_id']?.toString();
      final name = row['display_name']?.toString();
      if (id == null || name == null) continue;
      leaderAliases[id] = DemoPersonaLeaderAlias(
        leaderId: id,
        displayName: name,
        title: row['title']?.toString() ?? 'Sr.',
        postNominal: row['post_nominal']?.toString() ?? 'SOLC',
      );
    }
    DemoPersonaPresenter.configure(
      resolvedPersona: persona,
      resolvedIdentity: DemoPersonaIdentity(
        congregationName: identityRow['congregation_name'].toString(),
        abbreviation: identityRow['abbreviation'].toString(),
        provinceName: identityRow['province_name'].toString(),
        motto: identityRow['motto'].toString(),
        founderName: identityRow['founder_name']?.toString(),
        patronSaintName: identityRow['patron_saint_name']?.toString(),
      ),
      resolvedAliases: aliases,
      canonicalNames: canonicalNames,
      resolvedLeaderAliases: leaderAliases,
    );
  }

  String? _personaPhotoUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (Uri.tryParse(path)?.hasScheme ?? false) return path;
    final normalized = path.startsWith('member-photos/')
        ? path.substring('member-photos/'.length)
        : path;
    return _client.storage.from('member-photos').getPublicUrl(normalized);
  }
}
