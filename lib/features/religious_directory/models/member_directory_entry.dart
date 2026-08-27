import '../../../core/utils/ecclesiastical_name.dart';

class MemberDirectoryEntry {
  const MemberDirectoryEntry({
    required this.id,
    required this.religiousId,
    required this.displayName,
    required this.memberStatus,
    this.title,
    this.photoUrl,
    this.canonicalStatus,
    this.community,
    this.communityId,
    this.communityRole,
    this.ministry,
    this.ministryId,
    this.ministryRole,
    this.nativeState,
    this.mobile,
    this.whatsApp,
    this.officialEmail,
  });

  final String id;
  final String religiousId;
  final String displayName;
  final String? title;
  final String? photoUrl;
  final String memberStatus;
  final String? canonicalStatus;
  final String? community;
  final String? communityId;
  final String? communityRole;
  final String? ministry;
  final String? ministryId;
  final String? ministryRole;
  final String? nativeState;
  final String? mobile;
  final String? whatsApp;
  final String? officialEmail;

  String get titledName =>
      composeEcclesiasticalName(displayName: displayName, title: title);

  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    return words
        .take(2)
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .join()
        .toUpperCase();
  }

  bool get isDeceased => memberStatus.toLowerCase().contains('deceased');

  String? get ministryAssignment {
    final values = [
      ministry,
      ministryRole,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return values.isEmpty ? null : values.join(' · ');
  }

  String get directoryStatus {
    if (memberStatus.toLowerCase() != 'formation') return memberStatus;
    if (title == 'Dcn.') return 'Deacon';
    final stage = canonicalStatus;
    if (stage == null || stage == 'Perpetual Professed') return memberStatus;
    return stage;
  }
}

enum MemberDirectorySort {
  nameAscending,
  nameDescending,
  community,
  memberStatus,
}

class MemberDirectoryFilters {
  const MemberDirectoryFilters({
    this.memberStatus,
    this.canonicalStatus,
    this.community,
    this.state,
    this.ministry,
  });

  final String? memberStatus;
  final String? canonicalStatus;
  final String? community;
  final String? state;
  final String? ministry;

  int get activeCount => [
    memberStatus,
    canonicalStatus,
    community,
    state,
    ministry,
  ].where((value) => value?.isNotEmpty ?? false).length;

  MemberDirectoryFilters copyWith({
    String? memberStatus,
    String? canonicalStatus,
    String? community,
    String? state,
    String? ministry,
  }) => MemberDirectoryFilters(
    memberStatus: memberStatus ?? this.memberStatus,
    canonicalStatus: canonicalStatus ?? this.canonicalStatus,
    community: community ?? this.community,
    state: state ?? this.state,
    ministry: ministry ?? this.ministry,
  );
}
