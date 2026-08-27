import 'package:supabase_flutter/supabase_flutter.dart';

import '../../province_modules/models/province_models.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class MemberCommunityResident {
  const MemberCommunityResident({
    required this.communityId,
    required this.person,
  });

  final String communityId;
  final ProvincePerson person;
}

abstract interface class MemberCommunityResidentsRepository {
  Future<List<MemberCommunityResident>> fetchCurrentResidents();
}

class SupabaseMemberCommunityResidentsRepository
    implements MemberCommunityResidentsRepository {
  const SupabaseMemberCommunityResidentsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MemberCommunityResident>> fetchCurrentResidents() async {
    final rows = await _client
        .from('v_member_community_residents_safe')
        .select()
        .order('display_name');
    return MemberCommunityResidentMapper.fromRows(rows);
  }
}

class MemberCommunityResidentMapper {
  MemberCommunityResidentMapper._();

  static List<MemberCommunityResident> fromRows(
    Iterable<Map<String, dynamic>> rows, {
    DateTime? today,
  }) {
    final date = _dateOnly(today ?? DateTime.now());
    return rows
        .where((row) => _isCurrentIfDated(row, date))
        .map(_fromRow)
        .whereType<MemberCommunityResident>()
        .toList();
  }

  static bool _isCurrentIfDated(Map<String, dynamic> row, DateTime today) {
    if (!row.containsKey('from_date') && !row.containsKey('to_date')) {
      return true;
    }
    final from = DateTime.tryParse(_text(row['from_date']) ?? '');
    final to = DateTime.tryParse(_text(row['to_date']) ?? '');
    return (from == null || !_dateOnly(from).isAfter(today)) &&
        (to == null || !_dateOnly(to).isBefore(today));
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static MemberCommunityResident? _fromRow(Map<String, dynamic> row) {
    final communityId = _text(row['community_id']);
    final memberId = _text(row['member_id']);
    final displayName = _text(row['display_name']);
    if (communityId == null || memberId == null || displayName == null) {
      return null;
    }
    final aliasName = DemoPersonaPresenter.memberName(memberId, displayName);
    final title = DemoPersonaPresenter.memberTitle(
      memberId,
      _title(_text(row['ecclesiastical_title_code'])) ?? '',
    ).nullIfEmpty;
    final ministry = _label(_text(row['ministry_name']));
    final ministryRole = _label(_text(row['ministry_responsibility_code']));
    return MemberCommunityResident(
      communityId: communityId,
      person: ProvincePerson(
        id: memberId,
        name: title == null || aliasName.startsWith('$title ')
            ? aliasName
            : '$title $aliasName',
        role: _label(_text(row['community_responsibility_code'])),
        photoUrl: DemoPersonaPresenter.memberPhoto(
          memberId,
          _text(row['photo_url']),
        ),
        memberStatus: _label(_text(row['member_status_code'])),
        ministryAssignment: [
          ministryRole,
          ministry,
        ].whereType<String>().join(' · ').trim().nullIfEmpty,
      ),
    );
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _title(String? code) => switch (code?.toUpperCase()) {
    'FR' || 'FATHER' || 'PRIEST' => 'Fr.',
    'BRO' || 'BROTHER' => 'Bro.',
    'DCN' || 'DEACON' => 'Dcn.',
    _ => null,
  };

  static String? _label(String? value) {
    if (value == null) return null;
    if (value.contains(' ') && !value.contains('_')) return value;
    return value
        .toLowerCase()
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
