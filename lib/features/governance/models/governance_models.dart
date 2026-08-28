class GovernanceBody {
  const GovernanceBody({
    required this.id,
    required this.code,
    required this.name,
    required this.bodyTypeCode,
    required this.statusCode,
    required this.displayOrder,
    required this.memberships,
    this.shortName,
    this.description,
    this.purpose,
    this.establishedDate,
    this.dissolvedDate,
  });

  factory GovernanceBody.fromMap(Map<String, dynamic> map) {
    final membershipRows = map['memberships'];
    final memberships = membershipRows is List
        ? membershipRows
              .whereType<Map>()
              .map((row) => GovernanceMembership.fromMap(row.cast()))
              .toList(growable: false)
        : const <GovernanceMembership>[];
    return GovernanceBody(
      id: _text(map, 'governance_body_id') ?? _text(map, 'id') ?? '',
      code: _text(map, 'code') ?? '',
      name: _text(map, 'name') ?? 'Governance body',
      shortName: _text(map, 'short_name'),
      bodyTypeCode: _text(map, 'body_type_code') ?? 'BODY',
      description: _text(map, 'description'),
      purpose: _text(map, 'purpose'),
      statusCode: _text(map, 'status_code') ?? 'ACTIVE',
      establishedDate: _date(map['established_date']),
      dissolvedDate: _date(map['dissolved_date']),
      displayOrder: _integer(map['display_order']),
      memberships: memberships,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? shortName;
  final String bodyTypeCode;
  final String? description;
  final String? purpose;
  final String statusCode;
  final DateTime? establishedDate;
  final DateTime? dissolvedDate;
  final int displayOrder;
  final List<GovernanceMembership> memberships;

  List<GovernanceMembership> currentMemberships([DateTime? date]) {
    final result = memberships.where((item) => item.isCurrent(date)).toList();
    result.sort(GovernanceMembership.compareCurrent);
    return result;
  }

  List<GovernanceMembership> historicalMemberships([DateTime? date]) {
    final result = memberships.where((item) => !item.isCurrent(date)).toList();
    result.sort(GovernanceMembership.compareHistory);
    return result;
  }

  GovernanceMembership? currentLeader([DateTime? date]) {
    for (final membership in currentMemberships(date)) {
      if (membership.isLeadership) return membership;
    }
    return null;
  }

  String get typeLabel => governanceLabel(bodyTypeCode);
  String get statusLabel => governanceLabel(statusCode);
}

class GovernanceMembership {
  const GovernanceMembership({
    required this.id,
    required this.memberId,
    required this.displayName,
    required this.roleCode,
    required this.startDate,
    required this.statusCode,
    this.religiousId,
    this.ecclesiasticalTitleCode,
    this.photoUrl,
    this.roleTitle,
    this.endDate,
  });

  factory GovernanceMembership.fromMap(Map<String, dynamic> map) =>
      GovernanceMembership(
        id: _text(map, 'membership_id') ?? _text(map, 'id') ?? '',
        memberId: _text(map, 'member_id') ?? '',
        religiousId: _text(map, 'religious_id'),
        displayName: _text(map, 'display_name') ?? 'Religious',
        ecclesiasticalTitleCode: _text(map, 'ecclesiastical_title_code'),
        photoUrl: _text(map, 'photo_url'),
        roleCode: _text(map, 'role_code') ?? 'MEMBER',
        roleTitle: _text(map, 'role_title'),
        startDate: _date(map['start_date']) ?? DateTime(1),
        endDate: _date(map['end_date']),
        statusCode: _text(map, 'status_code') ?? 'ACTIVE',
      );

  final String id;
  final String memberId;
  final String? religiousId;
  final String displayName;
  final String? ecclesiasticalTitleCode;
  final String? photoUrl;
  final String roleCode;
  final String? roleTitle;
  final DateTime startDate;
  final DateTime? endDate;
  final String statusCode;

  String get roleLabel => roleTitle ?? governanceLabel(roleCode);
  bool get isLeadership => roleCode == 'CHAIR' || roleCode == 'PRESIDENT';

  bool isCurrent([DateTime? date]) {
    final value = date ?? DateTime.now();
    final today = DateTime(value.year, value.month, value.day);
    return statusCode == 'ACTIVE' &&
        !startDate.isAfter(today) &&
        (endDate == null || !endDate!.isBefore(today));
  }

  static int compareCurrent(
    GovernanceMembership first,
    GovernanceMembership second,
  ) {
    final role = _rolePriority(
      first.roleCode,
    ).compareTo(_rolePriority(second.roleCode));
    return role != 0 ? role : first.displayName.compareTo(second.displayName);
  }

  static int compareHistory(
    GovernanceMembership first,
    GovernanceMembership second,
  ) {
    final date = second.startDate.compareTo(first.startDate);
    return date != 0 ? date : compareCurrent(first, second);
  }
}

String governanceLabel(String code) {
  final words = code
      .trim()
      .toLowerCase()
      .split(RegExp(r'[_\s-]+'))
      .where((word) => word.isNotEmpty);
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

int _rolePriority(String role) => switch (role) {
  'PRESIDENT' => 0,
  'CHAIR' => 1,
  'SECRETARY' => 2,
  'TREASURER' => 3,
  'EX_OFFICIO' => 4,
  _ => 5,
};

String? _text(Map<String, dynamic> map, String key) {
  final value = map[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
