import 'package:flutter/foundation.dart';

import '../models/demo_persona.dart';

class PresentedPerson {
  const PresentedPerson({
    required this.memberId,
    required this.displayName,
    required this.title,
    required this.photoUrl,
    required this.aliasFound,
  });

  final String memberId;
  final String displayName;
  final String? title;
  final String? photoUrl;
  final bool aliasFound;
}

class DemoPersonaPresenter {
  DemoPersonaPresenter._();

  static DemoPersona persona = DemoPersona.standard;
  static DemoPersonaIdentity? identity;
  static Map<String, DemoPersonaMemberAlias> aliases = const {};
  static Map<String, DemoPersonaLeaderAlias> leaderAliases = const {};
  static Map<String, DemoPersonaMemberAlias> _aliasesByCanonicalName = const {};

  static bool get isSisters => persona == DemoPersona.sisters;

  static void configure({
    required DemoPersona resolvedPersona,
    DemoPersonaIdentity? resolvedIdentity,
    Map<String, DemoPersonaMemberAlias> resolvedAliases = const {},
    Map<String, String> canonicalNames = const {},
    Map<String, DemoPersonaLeaderAlias> resolvedLeaderAliases = const {},
  }) {
    persona = resolvedPersona;
    identity = resolvedIdentity;
    aliases = Map.unmodifiable(resolvedAliases);
    leaderAliases = Map.unmodifiable(resolvedLeaderAliases);
    final aliasesByName = <String, DemoPersonaMemberAlias>{};
    for (final entry in canonicalNames.entries) {
      final alias = resolvedAliases[entry.key];
      if (alias != null) aliasesByName[entry.value] = alias;
    }
    _aliasesByCanonicalName = Map.unmodifiable(aliasesByName);
  }

  static DemoPersonaMemberAlias? member(String? memberId) =>
      memberId == null ? null : aliases[memberId];

  static PresentedPerson presentPerson({
    required String memberId,
    required String canonicalDisplayName,
    String? canonicalTitle,
    String? canonicalPhotoUrl,
  }) {
    final alias = member(memberId);
    final title = memberTitle(memberId, canonicalTitle ?? '').trim();
    final presented = PresentedPerson(
      memberId: memberId,
      displayName: memberName(memberId, canonicalDisplayName),
      title: title.isEmpty ? null : title,
      photoUrl: memberPhoto(memberId, canonicalPhotoUrl),
      aliasFound: alias != null,
    );
    if (kDebugMode && isSisters) {
      debugPrint(
        '[SistersPersona] member_id=$memberId alias_found=${presented.aliasFound} '
        'canonical_name="$canonicalDisplayName" presented_name="${presented.displayName}"',
      );
    }
    return presented;
  }

  static String memberName(String? memberId, String canonical) =>
      member(memberId)?.displayName ??
      (isSisters && memberId != null && memberId.trim().isNotEmpty
          ? 'Sister'
          : canonical);

  static String memberTitle(String? memberId, String canonical) =>
      member(memberId)?.title ??
      (isSisters && _isReligiousTitle(canonical) ? 'Sr.' : canonical);

  static String? memberPhoto(String? memberId, String? canonical) {
    if (!isSisters) return canonical;
    final path = member(memberId)?.photoPath;
    return path == null || path.trim().isEmpty ? null : path;
  }

  static String role(String canonical) {
    if (!isSisters) return canonical;
    if (canonical.trim() == 'Provincial') return 'Provincial Superior';
    return canonical
        .replaceAll('current Provincial is', 'current Provincial Superior is')
        .replaceAll('the Provincial is', 'the Provincial Superior is')
        .replaceAll('Novice Master', 'Novice Directress')
        .replaceAll('Scholastic Master', 'Scholasticate Directress')
        .replaceAll('Formation Director', 'Formation Directress');
  }

  static String translateText(String canonical) {
    if (!isSisters) return canonical;
    var translated = canonical;
    for (final entry in _aliasesByCanonicalName.entries) {
      translated = translated.replaceAll(
        RegExp('(?:Fr|Bro)\\.?\\s+${RegExp.escape(entry.key)}'),
        'Sr. ${entry.value.displayName}',
      );
      translated = translated.replaceAll(entry.key, entry.value.displayName);
    }
    return role(translated);
  }

  static String organizationText(String canonical) {
    if (!isSisters) return canonical;
    return translateText(canonical)
        .replaceAll(RegExp(r'\bFr\.?\s*'), 'Sr. ')
        .replaceAll(RegExp(r'\bBro\.?\s*'), 'Sr. ')
        .replaceAll(RegExp(r'\bMSA\b'), 'SOLC');
  }

  static DemoPersonaLeaderAlias? leader(String leaderId) =>
      leaderAliases[leaderId];

  static bool _isReligiousTitle(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('.', '');
    return normalized == 'fr' || normalized == 'bro' || normalized == 'brother';
  }
}
