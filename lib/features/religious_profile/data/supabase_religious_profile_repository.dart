import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/responsibility_labels.dart';
import '../models/religious_profile.dart';
import 'family_contact_mapper.dart';
import 'religious_profile_repository.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class SupabaseReligiousProfileRepository implements ReligiousProfileRepository {
  const SupabaseReligiousProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    if (kDebugMode) {
      debugPrint('[ProvincialProfileRPC] member_id=$memberId');
    }
    try {
      final raw = await _client.rpc(
        'get_provincial_member_profile_safe',
        params: {'p_member_id': memberId},
      );
      if (raw is! Map) {
        throw const ReligiousProfileException(
          ReligiousProfileFailureKind.notFound,
        );
      }
      return _mapProvincialRpcProfile(Map<String, dynamic>.from(raw), memberId);
    } on ReligiousProfileException {
      rethrow;
    } on PostgrestException catch (error) {
      throw ReligiousProfileException(
        error.code == '42501'
            ? ReligiousProfileFailureKind.permission
            : error.code == 'P0002'
            ? ReligiousProfileFailureKind.notFound
            : ReligiousProfileFailureKind.unexpected,
        cause: error,
      );
    }
  }

  // Retained temporarily as a rollback reference while the server RPC is
  // deployed; it is never used by the active Provincial flow.
  // ignore: unused_element
  Future<ReligiousProfile> _fetchLegacyProfile(String memberId) async {
    try {
      final directoryMember = await _client
          .from('v_demo_member_directory')
          .select()
          .eq('member_id', memberId)
          .maybeSingle();
      if (directoryMember == null) {
        throw const ReligiousProfileException(
          ReligiousProfileFailureKind.notFound,
        );
      }
      Map<String, dynamic>? memberDetail;
      try {
        memberDetail = await _client
            .from('members')
            .select()
            .eq('id', memberId)
            .maybeSingle();
      } catch (_) {
        // The authorized reporting row is sufficient to identify and render
        // the profile; direct master-table detail is an optional enrichment.
      }
      final member = {...directoryMember, ...?memberDetail};

      final core = await Future.wait([
        _rows('member_community_assignments', memberId),
        _rows('member_ministry_assignments', memberId),
        _allRows('communities'),
        _allRows('ministries'),
      ]);
      final communities = _names(core[2]);
      final ministries = _names(core[3]);
      final communityAssignments =
          core[0]
              .map((row) => _assignment(row, 'Community', communities))
              .whereType<AssignmentRecord>()
              .toList()
            ..sort(_assignmentsNewestFirst);
      final ministryAssignments =
          core[1]
              .map((row) => _assignment(row, 'Ministry', ministries))
              .whereType<AssignmentRecord>()
              .toList()
            ..sort(_assignmentsNewestFirst);

      final optional = await Future.wait([
        _optional(
          ProfileSection.vocation,
          () => _rows('member_vocation_events', memberId),
        ),
        _optional(
          ProfileSection.qualifications,
          () => _qualificationRows(memberId),
        ),
        _optional(
          ProfileSection.governance,
          () => _rows('member_office_appointments', memberId),
        ),
        _optional(
          ProfileSection.origin,
          () => _rows('member_native_details', memberId),
        ),
        _optional(
          ProfileSection.family,
          () => _rows('member_home_contacts', memberId),
        ),
        _optional(
          ProfileSection.family,
          () => _rows('member_family', memberId),
        ),
        _optional(
          ProfileSection.family,
          () => _rows('v_demo_member_public_contacts', memberId),
        ),
        _optional(ProfileSection.documents, () => _rows('documents', memberId)),
        _optional(ProfileSection.leave, () => _leaveRows(memberId)),
        _optional(ProfileSection.governance, () => _allRows('office_types')),
        _optional(ProfileSection.governance, () => _allRows('provinces')),
        _optional(ProfileSection.governance, () => _allRows('congregations')),
      ]);
      final failures = optional
          .where((result) => result.failed)
          .map((result) => result.section)
          .toSet();

      final vocation = optional[0].rows.map(_vocation).toList()
        ..sort((a, b) => _compareDates(a.date, b.date));
      final qualifications = optional[1].rows.map(_qualification).toList()
        ..sort((a, b) => (b.year ?? -1).compareTo(a.year ?? -1));
      final officeTypes = _names(optional[9].rows);
      final provinces = _names(optional[10].rows);
      final congregations = _names(optional[11].rows);
      final offices =
          optional[2].rows
              .map(
                (row) => _office(
                  row,
                  officeTypes: officeTypes,
                  ministries: ministries,
                  communities: communities,
                  provinces: provinces,
                  congregations: congregations,
                ),
              )
              .toList()
            ..sort((a, b) {
              if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
              return _compareDates(b.fromDate, a.fromDate);
            });
      final currentCommunity = communityAssignments
          .where((assignment) => assignment.isCurrent)
          .firstOrNull;
      final currentMinistry = ministryAssignments
          .where((assignment) => assignment.isCurrent)
          .firstOrNull;
      final presentedPerson = DemoPersonaPresenter.presentPerson(
        memberId: memberId,
        canonicalDisplayName:
            _text(member, ['display_name', 'full_name']) ?? 'Unnamed member',
        canonicalTitle: _title(
          _text(member, ['ecclesiastical_title_code', 'title']),
        ),
        canonicalPhotoUrl: _text(member, ['photo_url']),
      );

      return ReligiousProfile(
        memberId: memberId,
        religiousId: _text(member, ['religious_id']) ?? '',
        displayName: presentedPerson.displayName,
        title: presentedPerson.title,
        photoUrl: presentedPerson.photoUrl,
        memberStatus:
            _label(_text(member, ['member_status_code', 'status'])) ?? 'Active',
        canonicalStatus: _label(
          _text(member, ['canonical_status_code', 'canonical_status']),
        ),
        dateOfBirth: _date(member, ['date_of_birth', 'birth_date', 'dob']),
        nationality: _text(member, ['nationality']),
        bloodGroup: _text(member, ['blood_group']),
        patronSaint: _text(member, ['patron_saint']),
        community: currentCommunity?.name,
        communityRole: currentCommunity?.role,
        communityFromDate: currentCommunity?.fromDate,
        ministry: currentCommunity?.role == 'Community Superior'
            ? null
            : currentMinistry?.name,
        ministryRole: currentCommunity?.role == 'Community Superior'
            ? null
            : currentMinistry?.role,
        ministryType: currentMinistry?.type,
        ministryFromDate: currentMinistry?.fromDate,
        origin: _origin(optional[3].rows.firstOrNull),
        sections: ReligiousProfileSections(
          vocationEvents: vocation,
          qualifications: qualifications,
          communityAssignments: communityAssignments,
          ministryAssignments: ministryAssignments,
          offices: offices,
          leaveHistory: optional[8].rows.map(_leave).toList()
            ..sort((a, b) => _compareDates(b.fromDate, a.fromDate)),
          homeContacts: _homeContacts(optional[4].rows),
          family: FamilyContactMapper.fromRows([
            ...optional[4].rows,
            ...optional[5].rows,
          ]),
          contacts: _contacts(optional[6].rows),
          documents: optional[7].rows.map(_document).toList(),
          failures: failures,
        ),
      );
    } on ReligiousProfileException {
      rethrow;
    } on AuthException catch (error) {
      throw ReligiousProfileException(
        ReligiousProfileFailureKind.authentication,
        cause: error,
      );
    } on PostgrestException catch (error) {
      final kind = error.code == '42501'
          ? ReligiousProfileFailureKind.permission
          : ReligiousProfileFailureKind.unexpected;
      throw ReligiousProfileException(kind, cause: error);
    } catch (error) {
      final type = error.runtimeType.toString().toLowerCase();
      throw ReligiousProfileException(
        type.contains('socket') || type.contains('fetch')
            ? ReligiousProfileFailureKind.network
            : ReligiousProfileFailureKind.unexpected,
        cause: error,
      );
    }
  }

  ReligiousProfile _mapProvincialRpcProfile(
    Map<String, dynamic> row,
    String memberId,
  ) {
    if (_text(row, ['member_id']) != memberId) {
      throw const ReligiousProfileException(
        ReligiousProfileFailureKind.notFound,
      );
    }
    final communityAssignments = _rpcAssignments(
      _mapRows(row['community_assignments']),
      'Community',
    );
    final ministryAssignments = _rpcAssignments(
      _mapRows(row['ministry_assignments']),
      'Ministry',
    );
    final currentCommunity = communityAssignments
        .where((assignment) => assignment.isCurrent)
        .firstOrNull;
    final currentMinistry = ministryAssignments
        .where((assignment) => assignment.isCurrent)
        .firstOrNull;
    final presented = DemoPersonaPresenter.presentPerson(
      memberId: memberId,
      canonicalDisplayName: _text(row, ['display_name']) ?? 'Religious',
      canonicalTitle: _title(_text(row, ['ecclesiastical_title_code'])),
      canonicalPhotoUrl: _text(row, ['photo_url']),
    );
    final contactRows = [
      {
        'mobile': row['mobile'],
        'whatsapp': row['whatsapp'],
        'official_email': row['official_email'],
      },
    ];
    return ReligiousProfile(
      memberId: memberId,
      religiousId: _text(row, ['religious_id']) ?? '',
      displayName: presented.displayName,
      title: presented.title,
      photoUrl: presented.photoUrl,
      memberStatus: _label(_text(row, ['member_status_code'])) ?? 'Active',
      canonicalStatus: _label(_text(row, ['canonical_status_code'])),
      dateOfBirth: _date(row, ['date_of_birth']),
      nationality: _text(row, ['nationality']),
      bloodGroup: _text(row, ['blood_group']),
      patronSaint: _text(row, ['patron_saint']),
      community: currentCommunity?.name,
      communityRole: currentCommunity?.role,
      communityFromDate: currentCommunity?.fromDate,
      ministry: currentMinistry?.name,
      ministryRole: currentMinistry?.role,
      ministryType: currentMinistry?.type,
      ministryFromDate: currentMinistry?.fromDate,
      origin: _origin(
        row['native_details'] is Map
            ? Map<String, dynamic>.from(row['native_details'] as Map)
            : null,
      ),
      sections: ReligiousProfileSections(
        vocationEvents: _mapRows(
          row['vocation_events'],
        ).map(_vocation).toList(),
        qualifications: _mapRows(
          row['qualifications'],
        ).map(_qualification).toList(),
        communityAssignments: communityAssignments,
        ministryAssignments: ministryAssignments,
        offices: _mapRows(row['office_appointments']).map(_rpcOffice).toList(),
        leaveHistory: _mapRows(row['attention_events']).map(_leave).toList(),
        homeContacts: _homeContacts(_mapRows(row['home_contacts'])),
        family: FamilyContactMapper.fromRows([
          ..._mapRows(row['home_contacts']),
          ..._mapRows(row['family']),
        ]),
        contacts: _contacts(contactRows),
        documents: _mapRows(row['documents']).map(_document).toList(),
      ),
    );
  }

  List<AssignmentRecord> _rpcAssignments(
    List<Map<String, dynamic>> rows,
    String kind,
  ) => rows
      .map(
        (row) => AssignmentRecord(
          kind: kind,
          name: _text(row, ['name']) ?? kind,
          sourceId: _text(row, ['id']),
          relatedEntityId: _text(row, [
            kind == 'Community' ? 'community_id' : 'ministry_id',
          ]),
          role: kind == 'Community'
              ? _communityRole(_text(row, ['responsibility_code']))
              : _label(_text(row, ['responsibility_code'])),
          fromDate: _date(row, ['from_date']),
          toDate: _date(row, ['to_date']),
        ),
      )
      .toList();

  OfficeAppointment _rpcOffice(Map<String, dynamic> row) => OfficeAppointment(
    sourceId: _text(row, ['id']),
    office:
        _label(_text(row, ['office_type_code', 'office_code'])) ??
        'Office appointment',
    fromDate: _date(row, ['from_date']),
    toDate: _date(row, ['to_date']),
  );

  static List<Map<String, dynamic>> _mapRows(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];

  Future<List<Map<String, dynamic>>> _rows(
    String table,
    String memberId,
  ) async => await _client.from(table).select().eq('member_id', memberId);

  Future<List<Map<String, dynamic>>> _allRows(String table) async =>
      await _client.from(table).select();

  Future<List<Map<String, dynamic>>> _qualificationRows(String memberId) async {
    try {
      return await _rows('v_member_qualifications_normalized', memberId);
    } catch (_) {
      return _rows('member_qualifications', memberId);
    }
  }

  Future<List<Map<String, dynamic>>> _leaveRows(String memberId) async {
    final rows = await _rows('v_demo_member_attention_events', memberId);
    const leaveTypes = {
      'sabbatical',
      'study_leave',
      'home_leave',
      'medical_leave',
      'ministry_break',
      'leave',
      'leave_from_active_ministry',
      'temporary_absence',
      'study',
      'medical',
      'absence',
    };
    return rows
        .where(
          (row) => leaveTypes.contains(
            _text(row, ['event_type', 'event_type_code'])?.toLowerCase(),
          ),
        )
        .toList();
  }

  Future<_OptionalRows> _optional(
    ProfileSection section,
    Future<List<Map<String, dynamic>>> Function() load,
  ) async {
    try {
      return _OptionalRows(section, await load());
    } catch (_) {
      return _OptionalRows(section, const [], failed: true);
    }
  }

  Map<String, Map<String, dynamic>> _names(List<Map<String, dynamic>> rows) {
    final names = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = _text(row, ['id']);
      if (id != null) names[id] = row;
    }
    return names;
  }

  AssignmentRecord? _assignment(
    Map<String, dynamic> row,
    String kind,
    Map<String, Map<String, dynamic>> lookup,
  ) {
    final foreignKey = kind == 'Community' ? 'community_id' : 'ministry_id';
    final target = lookup[_text(row, [foreignKey])];
    final name = target == null ? null : _text(target, ['name']);
    if (name == null) return null;
    return AssignmentRecord(
      kind: kind,
      name: name,
      sourceId: _text(row, ['id']),
      relatedEntityId: _text(row, [foreignKey]),
      role: kind == 'Community'
          ? _communityRole(_text(row, ['responsibility_code', 'role_code']))
          : _label(_text(row, ['responsibility_code', 'role_code'])),
      type: target == null
          ? null
          : _label(_text(target, ['ministry_type_code', 'type_code', 'type'])),
      fromDate: _date(row, ['from_date', 'start_date']),
      toDate: _date(row, ['to_date', 'end_date']),
    );
  }

  VocationEvent _vocation(Map<String, dynamic> row) => VocationEvent(
    sourceId: _text(row, ['id']),
    label:
        _label(_text(row, ['event_type_code', 'event_code', 'event_type'])) ??
        'Vocation event',
    date: _partialDate(row),
    datePrecision: _datePrecision(row),
    place: _text(row, ['place', 'location']),
    notes: _text(row, ['notes', 'remarks']),
  );

  QualificationRecord _qualification(
    Map<String, dynamic> row,
  ) => QualificationRecord(
    qualification:
        _text(row, ['qualification', 'degree', 'qualification_name']) ??
        'Qualification',
    specialization: _text(row, ['specialization', 'field_of_study']),
    category: _label(
      _text(row, [
        'qualification_category',
        'category',
        'category_code',
        'qualification_category_code',
        'qualification_type',
        'qualification_type_code',
        'theology_classification',
        'professional_classification',
        'certificate_diploma_classification',
      ]),
    ),
    level: _label(_text(row, ['qualification_level', 'degree_level', 'level'])),
    institution: _text(row, ['institution', 'institution_name']),
    universityBoard: _text(row, [
      'university_board',
      'university_or_board',
      'university',
      'university_name',
      'board',
      'board_name',
      'awarding_body',
    ]),
    subject: _text(row, ['subject', 'primary_subject']),
    teachingSubjects: _stringList(row, ['teaching_subjects', 'subject_names']),
    year: _integer(row, [
      'year_of_passing',
      'passing_year',
      'completion_year',
      'year',
    ]),
    startYear: _integer(row, ['start_year', 'from_year']),
    endYear: _integer(row, ['end_year', 'completion_year', 'to_year']),
    country: _text(row, ['country', 'country_name']),
    notes: _text(row, ['notes', 'remarks']),
  );

  OfficeAppointment _office(
    Map<String, dynamic> row, {
    required Map<String, Map<String, dynamic>> officeTypes,
    required Map<String, Map<String, dynamic>> ministries,
    required Map<String, Map<String, dynamic>> communities,
    required Map<String, Map<String, dynamic>> provinces,
    required Map<String, Map<String, dynamic>> congregations,
  }) {
    final officeType = officeTypes[_text(row, ['office_type_id'])];
    final ministry = ministries[_text(row, ['ministry_id'])];
    final community = communities[_text(row, ['community_id'])];
    final province = provinces[_text(row, ['province_id'])];
    final congregation = congregations[_text(row, ['congregation_id'])];
    final contextRecord = ministry ?? community ?? province ?? congregation;
    final contextKind = ministry != null
        ? OfficeContextKind.ministry
        : community != null
        ? OfficeContextKind.community
        : province != null
        ? OfficeContextKind.province
        : congregation != null
        ? OfficeContextKind.congregation
        : null;
    return OfficeAppointment(
      sourceId: _text(row, ['id', 'appointment_id']),
      office:
          _text(officeType ?? const {}, ['name', 'office_name', 'label']) ??
          _label(_text(row, ['office_type_code', 'office_code', 'office'])) ??
          'Office appointment',
      context: contextRecord == null
          ? null
          : _text(contextRecord, [
              'name',
              'province_name',
              'congregation_name',
            ]),
      contextKind: contextKind,
      relatedEntityId: _text(row, [
        if (contextKind == OfficeContextKind.ministry) 'ministry_id',
        if (contextKind == OfficeContextKind.community) 'community_id',
        if (contextKind == OfficeContextKind.province) 'province_id',
        if (contextKind == OfficeContextKind.congregation) 'congregation_id',
      ]),
      fromDate: _date(row, ['from_date', 'start_date']),
      toDate: _date(row, ['to_date', 'end_date']),
    );
  }

  LeaveRecord _leave(Map<String, dynamic> row) => LeaveRecord(
    sourceId: _text(row, ['id', 'event_id']),
    type:
        _label(_text(row, ['event_type', 'event_type_code', 'leave_type'])) ??
        'Leave',
    fromDate: _date(row, ['from_date', 'start_date']),
    toDate: _date(row, ['to_date', 'end_date']),
    location: _text(row, ['location', 'place']),
    reason: _text(row, ['purpose', 'reason', 'title']),
    notes: _text(row, ['notes', 'remarks']),
    timingStatus: _text(row, ['timing_status']),
  );

  MemberOriginDetails? _origin(Map<String, dynamic>? row) {
    if (row == null) return null;
    final origin = MemberOriginDetails(
      nativePlace: _text(row, ['native_place']),
      homeParish: _text(row, ['native_parish']),
      diocese: _text(row, ['native_diocese']),
      district: _text(row, ['district']),
      state: _text(row, ['state']),
      country: _text(row, ['country']),
    );
    return origin.isEmpty ? null : origin;
  }

  List<LabeledValue> _homeContacts(List<Map<String, dynamic>> rows) => rows
      .map(
        (row) => _text(row, ['address', 'home_address', 'formatted_address']),
      )
      .whereType<String>()
      .map((value) => LabeledValue('Home Address', value))
      .toList();

  List<LabeledValue> _contacts(List<Map<String, dynamic>> rows) => [
    for (final row in rows) ...[
      if (_text(row, ['mobile']) case final mobile?)
        LabeledValue('Mobile', mobile),
      if (_text(row, ['whatsapp']) case final whatsApp?)
        LabeledValue('WhatsApp', whatsApp),
      if (_text(row, ['official_email']) case final email?)
        LabeledValue('Official Email', email),
    ],
  ];

  DocumentRecord _document(Map<String, dynamic> row) => DocumentRecord(
    type:
        _label(_text(row, ['document_type_code', 'type_code', 'type'])) ??
        'Document',
    number: _text(row, ['document_number', 'number']),
    issueDate: _date(row, ['issue_date']),
    expiryDate: _date(row, ['expiry_date']),
    authority: _text(row, ['issuing_authority', 'authority']),
    verificationStatus: _label(
      _text(row, ['verification_status_code', 'verification_status']),
    ),
  );

  int _assignmentsNewestFirst(AssignmentRecord a, AssignmentRecord b) {
    if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
    return _compareDates(b.fromDate, a.fromDate);
  }

  int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static String? _title(String? value) => switch (value?.toUpperCase()) {
    'FR' || 'FATHER' || 'PRIEST' => 'Fr.',
    'BRO' || 'BROTHER' => 'Bro.',
    'DCN' || 'DEACON' => 'Dcn.',
    null || '' => null,
    final code => _label(code),
  };

  static String? _communityRole(String? value) =>
      communityResponsibilityLabel(value) ?? _label(value);

  static String? _label(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return switch (value.toLowerCase()) {
      'studies' || 'higher_studies' => 'Higher Studies',
      'on_leave' => 'On Leave',
      'perpetual_professed' => 'Perpetually Professed',
      _ =>
        value
            .toLowerCase()
            .split(RegExp(r'[_\-\s]+'))
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
    };
  }

  static String? _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static DateTime? _date(Map<String, dynamic> row, List<String> keys) =>
      DateTime.tryParse(_text(row, keys) ?? '');

  static int? _integer(Map<String, dynamic> row, List<String> keys) =>
      int.tryParse(_text(row, keys) ?? '');

  static List<String> _stringList(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is List) {
        return value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(RegExp(r'[,;]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static DateTime? _partialDate(Map<String, dynamic> row) {
    final exact = _date(row, ['event_date', 'date']);
    if (exact != null) return exact;
    final year = _integer(row, ['event_year', 'year']);
    if (year == null) return null;
    final month = _integer(row, ['event_month', 'month']);
    return DateTime(year, month ?? 1);
  }

  static TimelineDatePrecision _datePrecision(Map<String, dynamic> row) {
    if (_text(row, ['event_date', 'date']) != null) {
      return TimelineDatePrecision.day;
    }
    if (_integer(row, ['event_month', 'month']) != null) {
      return TimelineDatePrecision.month;
    }
    return TimelineDatePrecision.year;
  }
}

class _OptionalRows {
  const _OptionalRows(this.section, this.rows, {this.failed = false});
  final ProfileSection section;
  final List<Map<String, dynamic>> rows;
  final bool failed;
}
