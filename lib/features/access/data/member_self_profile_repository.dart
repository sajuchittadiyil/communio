import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../religious_profile/data/religious_profile_repository.dart';
import '../../religious_profile/data/family_contact_mapper.dart';
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
      final results = await Future.wait<dynamic>([
        Future<dynamic>.value(_client.rpc(rpcName)),
        Future<dynamic>.value(
          _client
              .from('v_member_languages')
              .select()
              .eq('member_id', memberId)
              .order('is_primary', ascending: false)
              .order('language_name'),
        ),
        Future<dynamic>.value(
          _client
              .from('v_member_transfers')
              .select()
              .eq('member_id', memberId)
              .eq('status_code', 'CONFIRMED')
              .lte('effective_date', DateTime.now().toIso8601String())
              .order('effective_date', ascending: false),
        ),
        Future<dynamic>.value(_client.rpc('get_member_self_origin_safe')),
      ]);
      final raw = results[0];
      if (raw is! Map) {
        throw const ReligiousProfileException(
          ReligiousProfileFailureKind.notFound,
        );
      }
      final row = Map<String, dynamic>.from(raw);
      row['languages'] = results[1];
      row['transfers'] = results[2];
      final home = results[3];
      row['native_details'] = home;
      if (home is Map) {
        row['home_contacts'] = home['home_contacts'];
        row['family'] = home['family'];
      }
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
      origin: _origin(row['native_details']),
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
        languages: _rows(
          row['languages'],
        ).map(_language).toList(growable: false),
        transfers: _rows(
          row['transfers'],
        ).map(_transfer).toList(growable: false),
        communityAssignments: _rows(
          row['community_assignments'],
        ).map((item) => _assignment(item, 'Community')).toList(growable: false),
        ministryAssignments: _rows(
          row['ministry_assignments'],
        ).map((item) => _assignment(item, 'Ministry')).toList(growable: false),
        homeContacts: _homeContacts(_rows(row['home_contacts'])),
        family: FamilyContactMapper.fromRows([
          ..._rows(row['home_contacts']),
          ..._rows(row['family']),
        ]),
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

  static MemberLanguage _language(Map<String, dynamic> row) => MemberLanguage(
    name: _text(row['language_name']) ?? 'Language',
    code: _text(row['language_code']),
    proficiencyLevelCode: _text(row['proficiency_level_code']),
    canSpeak: row['can_speak'] as bool?,
    canRead: row['can_read'] as bool?,
    canWrite: row['can_write'] as bool?,
    isPrimary: row['is_primary'] == true,
    isNative: row['is_native'] as bool?,
  );

  static MemberTransferRecord _transfer(Map<String, dynamic> row) =>
      MemberTransferRecord(
        id: _text(row['transfer_id']) ?? '',
        fromCommunityId: _text(row['from_community_id']),
        fromCommunityName: _text(row['from_community_name']),
        toCommunityId: _text(row['to_community_id']),
        toCommunityName: _text(row['to_community_name']),
        effectiveDate: _date(row['effective_date']) ?? DateTime(1),
        transferTypeCode: _text(row['transfer_type_code']) ?? 'TRANSFER',
      );

  static MemberOriginDetails? _origin(dynamic value) {
    if (value is! Map) return null;
    final row = Map<String, dynamic>.from(value);
    final origin = MemberOriginDetails(
      nativePlace: _text(row['native_place']),
      homeParish: _text(row['home_parish']),
      diocese: _text(row['diocese']),
      district: _text(row['district']),
      state: _text(row['state']),
      country: _text(row['country']),
    );
    return origin.isEmpty ? null : origin;
  }

  static List<LabeledValue> _homeContacts(List<Map<String, dynamic>> rows) =>
      rows
          .expand(
            (row) => [
              if (_text(
                    row['address'] ??
                        row['home_address'] ??
                        row['formatted_address'],
                  )
                  case final value?)
                LabeledValue('Home Address', value),
              if (_text(row['phone']) case final value?)
                LabeledValue('Home Phone', value),
              if (_text(row['whatsapp']) case final value?)
                LabeledValue('Home WhatsApp', value),
              if (_text(row['email']) case final value?)
                LabeledValue('Home Email', value),
            ],
          )
          .toList(growable: false);

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
