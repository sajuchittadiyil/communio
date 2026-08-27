import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../religious_profile/data/religious_profile_repository.dart';
import '../../religious_profile/models/religious_profile.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class SupabaseMemberSelfProfileRepository
    implements ReligiousProfileRepository {
  const SupabaseMemberSelfProfileRepository(
    this._client, {
    required this.expectedMemberId,
    this.rpcName = 'get_member_self_profile_safe',
  });

  final SupabaseClient _client;
  final String expectedMemberId;
  final String rpcName;

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    if (memberId != expectedMemberId) {
      throw const ReligiousProfileException(
        ReligiousProfileFailureKind.notFound,
      );
    }
    try {
      final raw = await _client.rpc(rpcName);
      if (raw is! Map) {
        throw const ReligiousProfileException(
          ReligiousProfileFailureKind.notFound,
        );
      }
      final row = Map<String, dynamic>.from(raw);
      if (_text(row['member_id']) != expectedMemberId) {
        throw const ReligiousProfileException(
          ReligiousProfileFailureKind.notFound,
        );
      }
      return mapProfile(row, expectedMemberId: expectedMemberId);
    } on ReligiousProfileException {
      rethrow;
    } on AuthException catch (error) {
      _logError(error.message, error.statusCode);
      throw ReligiousProfileException(
        ReligiousProfileFailureKind.authentication,
        cause: error,
      );
    } on PostgrestException catch (error) {
      _logError(error.message, error.code);
      throw ReligiousProfileException(
        error.code == '42501'
            ? ReligiousProfileFailureKind.permission
            : ReligiousProfileFailureKind.unexpected,
        cause: error,
      );
    }
  }

  void _logError(String message, String? code) {
    if (!kDebugMode) return;
    debugPrint(
      'Self profile RPC $rpcName caller_member_id=$expectedMemberId '
      'error_code=${code ?? 'unknown'} message=$message',
    );
  }

  static ReligiousProfile mapProfile(
    Map<String, dynamic> row, {
    required String expectedMemberId,
  }) {
    if (_text(row['member_id']) != expectedMemberId) {
      throw const ReligiousProfileException(
        ReligiousProfileFailureKind.notFound,
      );
    }
    return ReligiousProfile(
      memberId: _text(row['member_id'])!,
      religiousId: _text(row['religious_id']) ?? '',
      displayName: DemoPersonaPresenter.memberName(
        expectedMemberId,
        _text(row['display_name']) ?? 'Religious',
      ),
      title: DemoPersonaPresenter.memberTitle(
        expectedMemberId,
        _title(_text(row['ecclesiastical_title_code'])) ?? '',
      ),
      photoUrl: DemoPersonaPresenter.memberPhoto(
        expectedMemberId,
        _text(row['photo_url']),
      ),
      memberStatus: _label(_text(row['member_status_code'])) ?? 'Active',
      canonicalStatus: _label(_text(row['canonical_status_code'])),
      community: _text(row['community_name']),
      communityRole: _label(_text(row['community_responsibility_code'])),
      communityFromDate: _date(row['community_from_date']),
      ministry: _text(row['ministry_name']),
      ministryRole: _label(_text(row['ministry_responsibility_code'])),
      ministryFromDate: _date(row['ministry_from_date']),
      sections: ReligiousProfileSections(
        contacts: [
          if (_text(row['mobile']) case final value?)
            LabeledValue('Mobile', value),
          if (_text(row['whatsapp']) case final value?)
            LabeledValue('WhatsApp', value),
          if (_text(row['official_email']) case final value?)
            LabeledValue('Official Email', value),
        ],
        vocationEvents: _rows(row['vocation_events'])
            .map(
              (item) => VocationEvent(
                sourceId: _text(item['id']),
                label:
                    _label(_text(item['event_type_code'])) ?? 'Vocation event',
                date: _date(item['event_date']),
              ),
            )
            .toList(growable: false),
        qualifications: _rows(row['qualifications'])
            .map(
              (item) => QualificationRecord(
                qualification: _text(item['qualification']) ?? 'Qualification',
                specialization: _text(item['specialization']),
                institution: _text(item['institution']),
                year: int.tryParse(_text(item['year_of_passing']) ?? ''),
              ),
            )
            .toList(growable: false),
        communityAssignments: _rows(
          row['community_assignments'],
        ).map((item) => _assignment(item, 'Community')).toList(growable: false),
        ministryAssignments: _rows(
          row['ministry_assignments'],
        ).map((item) => _assignment(item, 'Ministry')).toList(growable: false),
      ),
    );
  }

  static AssignmentRecord _assignment(Map<String, dynamic> row, String kind) =>
      AssignmentRecord(
        kind: kind,
        sourceId: _text(row['id']),
        relatedEntityId: _text(row['related_entity_id']),
        name: _text(row['name']) ?? kind,
        role: _label(_text(row['responsibility_code'])),
        fromDate: _date(row['from_date']),
        toDate: _date(row['to_date']),
      );

  static List<Map<String, dynamic>> _rows(dynamic value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _date(dynamic value) =>
      DateTime.tryParse(_text(value) ?? '');

  static String? _title(String? code) => switch (code?.toUpperCase()) {
    'FR' || 'FATHER' || 'PRIEST' => 'Fr.',
    'BRO' || 'BROTHER' => 'Bro.',
    'DCN' || 'DEACON' => 'Dcn.',
    _ => null,
  };

  static String? _label(String? value) {
    if (value == null) return null;
    return value
        .toLowerCase()
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
