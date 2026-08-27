enum DemoPersona { standard, sisters }

extension DemoPersonaCode on DemoPersona {
  String get code => switch (this) {
    DemoPersona.standard => 'standard',
    DemoPersona.sisters => 'sisters',
  };

  static DemoPersona fromCode(Object? value) => value?.toString() == 'sisters'
      ? DemoPersona.sisters
      : DemoPersona.standard;
}

class DemoPersonaIdentity {
  const DemoPersonaIdentity({
    required this.congregationName,
    required this.abbreviation,
    required this.provinceName,
    required this.motto,
    this.founderName,
    this.patronSaintName,
  });

  final String congregationName;
  final String abbreviation;
  final String provinceName;
  final String motto;
  final String? founderName;
  final String? patronSaintName;
}

class DemoPersonaMemberAlias {
  const DemoPersonaMemberAlias({
    required this.memberId,
    required this.displayName,
    required this.title,
    this.photoPath,
    this.roleDisplayOverride,
  });

  final String memberId;
  final String displayName;
  final String title;
  final String? photoPath;
  final String? roleDisplayOverride;
}

class DemoPersonaLeaderAlias {
  const DemoPersonaLeaderAlias({
    required this.leaderId,
    required this.displayName,
    this.title = 'Sr.',
    this.postNominal = 'SOLC',
  });

  final String leaderId;
  final String displayName;
  final String title;
  final String postNominal;
}
