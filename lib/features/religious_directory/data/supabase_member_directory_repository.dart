import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/responsibility_labels.dart';
import '../models/member_directory_entry.dart';
import 'member_directory_repository.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class SupabaseMemberDirectoryRepository implements MemberDirectoryRepository {
  const SupabaseMemberDirectoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async {
    final raw = await _client.rpc('get_provincial_member_directory_safe');
    final canonicalRows = List<Map<String, dynamic>>.from(raw as List);
    final results = <List<Map<String, dynamic>>>[
      canonicalRows,
      const [],
      const [],
      const [],
      const [],
      const [],
      const [],
    ];

    if (kDebugMode && DemoPersonaPresenter.isSisters) {
      debugPrint(
        '[ProvincialDirectoryRPC] canonical_rows=${results.first.length} '
        'persona=sisters '
        'source=get_provincial_member_directory_safe',
      );
    }

    return mapDirectoryResults(results);
  }

  @visibleForTesting
  List<MemberDirectoryEntry> mapDirectoryResults(
    List<List<Map<String, dynamic>>> results,
  ) {
    final communityNames = _lookupMap(results[2]);
    final communityAssignments = _communityAssignmentMap(
      results[1],
      communityNames,
    );
    final ministryNames = _lookupMap(results[4]);
    final ministries = _ministryMap(
      results[3],
      ministryNames,
      results[0],
      communityAssignments,
    );
    final states = <String, String>{};
    for (final row in results[5]) {
      final id = _string(row['member_id']);
      if (id != null) states[id] = _string(row['state']) ?? '';
    }
    final contacts = <String, Map<String, dynamic>>{};
    for (final row in results[6]) {
      final memberId = _string(row['member_id']);
      if (memberId != null) contacts[memberId] = row;
    }

    if (kDebugMode) {
      _debugDistribution(results[0], 'member_status_code');
      _debugDistribution(results[0], 'canonical_status_code');
      _debugDistribution(results[0], 'ecclesiastical_title_code');
      _debugDistribution(results[1], 'responsibility_code');
      _debugDistribution(results[3], 'responsibility_code');
      _verifyCommunitySuperiorIntegrity(results[1], results[3]);
    }

    final activeMemberRows = results[0].where(_isActiveMember).toList();
    final members = activeMemberRows.map((row) {
      final id = _string(row['member_id'] ?? row['id']) ?? '';
      final contact = contacts[id];
      final person = DemoPersonaPresenter.presentPerson(
        memberId: id,
        canonicalDisplayName: _string(row['display_name']) ?? 'Unnamed member',
        canonicalTitle: _title(_string(row['ecclesiastical_title_code'])),
        canonicalPhotoUrl: _string(row['photo_url']),
      );
      return MemberDirectoryEntry(
        id: id,
        religiousId: _string(row['religious_id']) ?? '',
        displayName: person.displayName,
        title: person.title,
        photoUrl: person.photoUrl,
        memberStatus:
            _label(
              _string(row['member_status'] ?? row['member_status_code']),
            ) ??
            'Active',
        canonicalStatus: _label(
          _string(row['canonical_status'] ?? row['canonical_status_code']),
        ),
        community:
            communityAssignments[id]?.name ?? _string(row['community_name']),
        communityId: _string(row['community_id']),
        communityRole:
            communityAssignments[id]?.role ??
            _label(_string(row['community_role'])),
        ministry: ministries[id]?.name ?? _string(row['ministry_name']),
        ministryId: _string(row['ministry_id']),
        ministryRole:
            ministries[id]?.role ?? _label(_string(row['ministry_role'])),
        nativeState: states[id],
        mobile: _string(contact?['mobile'] ?? row['mobile']),
        whatsApp: _string(contact?['whatsapp'] ?? row['whatsapp']),
        officialEmail: _string(
          contact?['official_email'] ?? row['official_email'],
        ),
      );
    }).toList();
    return members;
  }

  bool _isActiveMember(Map<String, dynamic> row) {
    final active = row['is_active'] ?? row['active'];
    if (active is bool) return active;
    final recordStatus = _string(
      row['record_status_code'] ?? row['status_code'],
    )?.toLowerCase();
    if (recordStatus != null) return recordStatus == 'active';
    return _string(row['member_status_code'])?.toLowerCase() != 'deceased';
  }

  Map<String, String> _lookupMap(List<dynamic> rows) {
    final values = <String, String>{};
    for (final row in rows) {
      final id = _string(row['member_id'] ?? row['id']);
      if (id != null) {
        values[id] = _string(row['name']) ?? '';
      }
    }
    return values;
  }

  Map<String, ({String? name, String? role})> _communityAssignmentMap(
    List<dynamic> rows,
    Map<String, String> names,
  ) {
    final values = <String, ({String? name, String? role})>{};
    for (final row in rows) {
      final memberId = _string(row['member_id']);
      final communityId = _string(row['community_id']);
      if (memberId != null) {
        values[memberId] = (
          name: communityId == null ? null : names[communityId],
          role: _communityRole(_string(row['responsibility_code'])),
        );
      }
    }
    return values;
  }

  Map<String, ({String? name, String? role})> _ministryMap(
    List<dynamic> rows,
    Map<String, String> names,
    List<dynamic> memberRows,
    Map<String, ({String? name, String? role})> communityAssignments,
  ) {
    final memberStatuses = <String, String?>{};
    for (final row in memberRows) {
      final id = _string(row['id']);
      if (id != null) {
        memberStatuses[id] = _string(row['member_status_code']);
      }
    }
    final values = <String, ({String? name, String? role})>{};
    for (final row in rows) {
      final id = _string(row['member_id']);
      final ministry = names[_string(row['ministry_id'])];
      final responsibility = _ministryResponsibility(
        _string(row['responsibility_code']),
      );
      final status = id == null ? null : memberStatuses[id];
      final normalizedStatus = status?.toLowerCase();
      final isFormation = const {
        'formation',
        'candidate',
        'novice',
        'postulant',
      }.contains(normalizedStatus);
      final isCommunitySuperior =
          id != null && communityAssignments[id]?.role == 'Community Superior';

      // Formation is represented by the current formation community and status.
      // A superior's community responsibility is likewise their sole assignment.
      if (id == null ||
          isCommunitySuperior ||
          (isFormation && responsibility == 'Student')) {
        continue;
      }
      if (ministry != null || responsibility != null) {
        values[id] = (name: ministry, role: responsibility);
      }
    }
    return values;
  }

  static String? _title(String? code) {
    return switch (code?.toUpperCase()) {
      'FR' || 'FATHER' || 'PRIEST' => 'Fr.',
      'BRO' || 'BROTHER' => 'Bro.',
      'DCN' || 'DEACON' => 'Dcn.',
      null || '' => null,
      final value => _label(value),
    };
  }

  static String? _communityRole(String? code) {
    final standard = communityResponsibilityLabel(code);
    if (standard != null) return standard;
    final normalized = code?.toLowerCase();
    if (normalized == null) return null;
    return switch (normalized) {
      'superior' || 'community_superior' => 'Community Superior',
      'member' || 'community_member' => 'Member',
      _ => _label(code),
    };
  }

  static String? _ministryResponsibility(String? code) {
    return switch (code?.toLowerCase()) {
      'teacher' => 'Teacher',
      'principal' => 'Principal',
      'administrator' => 'Administrator',
      'manager' => 'Manager',
      'bursar' => 'Bursar',
      'chaplain' => 'Chaplain',
      'parish_priest' => 'Parish Priest',
      'assistant_parish_priest' => 'Assistant Parish Priest',
      'social_worker' => 'Social Worker',
      'director' => 'Director',
      'coordinator' => 'Coordinator',
      'student' => 'Student',
      'novice_master' => 'Novice Master',
      'scholastic_master' => 'Scholastic Master',
      'vocation_promoter' => 'Vocation Promoter',
      null || '' => null,
      final value => _label(value),
    };
  }

  static String? _label(String? code) {
    if (code == null || code.isEmpty) return null;
    if (const {'studies', 'higher_studies'}.contains(code.toLowerCase())) {
      return 'Higher Studies';
    }
    if (code.toLowerCase() == 'on_leave') return 'On Leave';
    return code
        .toLowerCase()
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String? _string(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  // ignore: unused_element
  Future<List<Map<String, dynamic>>> _diagnosedQuery(
    String label,
    Future<List<Map<String, dynamic>>> Function() query,
  ) async {
    try {
      final rows = await query();
      if (kDebugMode) {
        debugPrint('[ReligiousDirectory] $label: ${rows.length} rows');
        if (rows.isNotEmpty) {
          debugPrint(
            '[ReligiousDirectory] $label columns: ${rows.first.keys.join(',')}',
          );
        }
      }
      return rows;
    } on PostgrestException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[ReligiousDirectory] FAILED $label\n'
          'code=${error.code}\nmessage=${error.message}\n'
          'details=${error.details}\nhint=${error.hint}',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      throw MemberDirectoryException(
        _postgrestFailureKind(error),
        cause: error,
      );
    } on AuthException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[ReligiousDirectory] FAILED $label: authentication: ${error.message}',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      throw MemberDirectoryException(
        MemberDirectoryFailureKind.authentication,
        cause: error,
      );
    } catch (error, stackTrace) {
      final type = error.runtimeType.toString().toLowerCase();
      final kind =
          type.contains('socket') ||
              type.contains('clientexception') ||
              type.contains('fetch')
          ? MemberDirectoryFailureKind.network
          : MemberDirectoryFailureKind.unexpected;
      if (kDebugMode) {
        debugPrint('[ReligiousDirectory] FAILED $label: ${kind.name}: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      throw MemberDirectoryException(kind, cause: error);
    }
  }

  MemberDirectoryFailureKind _postgrestFailureKind(PostgrestException error) {
    final code = error.code ?? '';
    if (code == 'PGRST301' || code == 'PGRST302' || code == 'PGRST303') {
      return MemberDirectoryFailureKind.authentication;
    }
    if (code == '42501') {
      return MemberDirectoryFailureKind.permission;
    }
    if (code.startsWith('PGRST') || code == '42703' || code == '42P01') {
      return MemberDirectoryFailureKind.schemaQuery;
    }
    return MemberDirectoryFailureKind.unexpected;
  }

  void _debugDistribution(List<Map<String, dynamic>> rows, String column) {
    final counts = <String, int>{};
    for (final row in rows) {
      final value = _string(row[column]) ?? '<null>';
      counts[value] = (counts[value] ?? 0) + 1;
    }
    debugPrint('[ReligiousDirectory] $column values: $counts');
  }

  void _verifyCommunitySuperiorIntegrity(
    List<Map<String, dynamic>> communityAssignments,
    List<Map<String, dynamic>> ministryAssignments,
  ) {
    final superiors = communityAssignments
        .where(
          (row) => const {
            'superior',
            'community_superior',
          }.contains(_string(row['responsibility_code'])?.toLowerCase()),
        )
        .map((row) => _string(row['member_id']))
        .whereType<String>()
        .toSet();
    final conflicts = ministryAssignments
        .map((row) => _string(row['member_id']))
        .whereType<String>()
        .where(superiors.contains)
        .toSet();
    if (conflicts.isNotEmpty) {
      debugPrint(
        '[ReligiousDirectory] DATA INTEGRITY: current Community Superior '
        'also has a current ministry assignment: ${conflicts.join(',')}',
      );
    }
  }
}
