import '../../documents/data/documents_repository.dart';
import '../../documents/models/province_document.dart';
import '../../province_modules/data/province_repository.dart';
import '../../province_modules/data/storage_image_url.dart';
import '../../province_modules/models/province_models.dart';
import '../../religious_profile/data/religious_profile_repository.dart';
import '../../religious_profile/models/religious_profile.dart';
import '../../organization_identity/data/organization_identity_repository.dart';
import '../../organization_identity/models/organization_identity_models.dart';
import '../../religious_directory/data/member_directory_repository.dart';
import '../../religious_directory/models/member_directory_entry.dart';
import 'member_community_residents_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/app_access_context.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class SupabaseMemberSafeDirectoryRepository
    implements MemberDirectoryRepository {
  const SupabaseMemberSafeDirectoryRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async {
    final rows = await _client
        .from('v_member_directory_safe')
        .select()
        .order('display_name');
    return rows
        .map(
          (row) => MemberDirectoryEntry(
            id: row['member_id'].toString(),
            religiousId: row['religious_id']?.toString() ?? '',
            displayName: DemoPersonaPresenter.memberName(
              row['member_id']?.toString(),
              row['display_name']?.toString() ?? 'Religious',
            ),
            title: DemoPersonaPresenter.memberTitle(
              row['member_id']?.toString(),
              _title(row['ecclesiastical_title_code']?.toString()) ?? '',
            ),
            photoUrl: DemoPersonaPresenter.memberPhoto(
              row['member_id']?.toString(),
              row['photo_url']?.toString(),
            ),
            memberStatus:
                _label(row['member_status_code']?.toString()) ?? 'Active',
            canonicalStatus: _label(row['canonical_status_code']?.toString()),
            community: row['community_name']?.toString(),
            communityId: row['community_id']?.toString(),
            communityRole: _label(
              row['community_responsibility_code']?.toString(),
            ),
            ministry: row['ministry_name']?.toString(),
            ministryId: row['ministry_id']?.toString(),
            ministryRole: _label(
              row['ministry_responsibility_code']?.toString(),
            ),
          ),
        )
        .toList(growable: false);
  }

  static String? _title(String? code) => switch (code?.toUpperCase()) {
    'FR' || 'FATHER' || 'PRIEST' => 'Fr.',
    'BRO' || 'BROTHER' => 'Bro.',
    'DCN' || 'DEACON' => 'Dcn.',
    _ => null,
  };

  static String? _label(String? code) {
    if (code == null || code.isEmpty) return null;
    return code
        .toLowerCase()
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class MemberSafeOrganizationIdentityRepository
    implements OrganizationIdentityRepository {
  const MemberSafeOrganizationIdentityRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<OrganizationIdentitySnapshot> fetchIdentity() async {
    final results = await Future.wait([
      _client.from('congregations').select().eq('active', true).limit(1),
      _client.from('provinces').select().eq('active', true).limit(1),
      _client
          .from('congregation_leadership')
          .select()
          .eq('active', true)
          .order('display_order'),
      _client.from('v_member_province_snapshot').select().single(),
    ]);
    final congregationRows = results[0] as List<dynamic>;
    final provinceRows = results[1] as List<dynamic>;
    if (congregationRows.isEmpty || provinceRows.isEmpty) {
      throw const OrganizationIdentityException();
    }
    final congregation = congregationRows.single as Map<String, dynamic>;
    final province = provinceRows.single as Map<String, dynamic>;
    final leadership = results[2] as List<dynamic>;
    final counts = results[3] as Map<String, dynamic>;
    final personaIdentity = DemoPersonaPresenter.identity;
    return OrganizationIdentitySnapshot(
      congregation: CongregationProfile(
        id: congregation['id'].toString(),
        name:
            personaIdentity?.congregationName ??
            congregation['name']?.toString() ??
            'Congregation',
        abbreviation:
            personaIdentity?.abbreviation ??
            congregation['abbreviation']?.toString(),
        motto: personaIdentity?.motto ?? congregation['motto']?.toString(),
        charism: congregation['charism']?.toString(),
        founder:
            personaIdentity?.founderName ?? congregation['founder']?.toString(),
        founderImageUrl: congregation['founder_image_url']?.toString(),
        patronSaintName:
            personaIdentity?.patronSaintName ??
            congregation['patron_saint_name']?.toString(),
        patronSaintImageUrl: congregation['patron_saint_image_url']?.toString(),
        foundedYear: congregation['founded_year'] as int?,
        generalateCity: congregation['generalate_city']?.toString(),
        generalateAddress: congregation['generalate_address']?.toString(),
        country: congregation['country']?.toString(),
        email: congregation['email']?.toString(),
        phone: congregation['phone']?.toString(),
        website: congregation['website']?.toString(),
      ),
      leaders: leadership
          .map((raw) {
            final row = raw as Map<String, dynamic>;
            final leaderId = row['id'].toString();
            final leaderAlias = DemoPersonaPresenter.leader(leaderId);
            return CongregationLeader(
              id: leaderId,
              displayName:
                  leaderAlias?.displayName ??
                  (DemoPersonaPresenter.isSisters
                      ? 'Sister'
                      : row['display_name']?.toString() ?? 'Religious'),
              roleName: DemoPersonaPresenter.role(
                row['role_name']?.toString() ?? 'Leadership',
              ),
              displayOrder: row['display_order'] as int? ?? 0,
              title: leaderAlias?.title ?? row['title']?.toString(),
              postNominal:
                  leaderAlias?.postNominal ?? row['post_nominal']?.toString(),
              countryOfOrigin: row['country_of_origin']?.toString(),
              administrationCity: row['administration_city']?.toString(),
              email: row['email']?.toString(),
              phone: row['phone']?.toString(),
              photoUrl: DemoPersonaPresenter.isSisters
                  ? null
                  : row['photo_url']?.toString(),
            );
          })
          .toList(growable: false),
      province: ProvinceProfile(
        id: province['id'].toString(),
        congregationName:
            personaIdentity?.congregationName ??
            congregation['name']?.toString() ??
            'Congregation',
        name:
            personaIdentity?.provinceName ??
            province['name']?.toString() ??
            'Province',
        motto: personaIdentity?.motto ?? province['motto']?.toString(),
        headquarters: province['headquarters']?.toString(),
        address: province['address']?.toString(),
        country: province['country']?.toString(),
        email: province['email']?.toString(),
        phone: province['phone']?.toString(),
        website: province['website']?.toString(),
        establishedDate: DateTime.tryParse(
          province['established_date']?.toString() ?? '',
        ),
        activeMembers: counts['active_members'] as int? ?? 0,
        activeCommunities: counts['active_communities'] as int? ?? 0,
        activeMinistries: counts['active_ministries'] as int? ?? 0,
      ),
    );
  }
}

class MemberDocumentsRepository implements DocumentsRepository {
  const MemberDocumentsRepository(this._source);
  final DocumentsRepository _source;

  @override
  Future<List<ProvinceDocument>> fetchDocuments() async =>
      (await _source.fetchDocuments())
          .where((document) => document.visibility == 'Province Members')
          .toList(growable: false);
}

class CommunitySuperiorDocumentsRepository implements DocumentsRepository {
  const CommunitySuperiorDocumentsRepository(
    this._source, {
    required this.managedCommunityId,
  });
  final DocumentsRepository _source;
  final String managedCommunityId;

  @override
  Future<List<ProvinceDocument>> fetchDocuments() async =>
      (await _source.fetchDocuments())
          .where((document) {
            if (document.visibility == 'Province Members') return true;
            return document.visibility == 'Community Leadership' &&
                document.relatedEntityType == 'community' &&
                document.relatedEntityId == managedCommunityId;
          })
          .toList(growable: false);
}

class MemberCalendarRepository implements ProvinceRepository {
  const MemberCalendarRepository(this._source, {this.residentsRepository});
  final ProvinceRepository _source;
  final MemberCommunityResidentsRepository? residentsRepository;

  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async {
    final communities = await _source.fetchCommunities();
    final managedEvents =
        _source is SupabaseMemberSafeProvinceRepository &&
            _source.managedCommunityOnly
        ? await _source.fetchCalendarEntries()
        : const <CalendarEntry>[];
    final year = DateTime.now().year;
    final entries = <CalendarEntry>[
      for (final community in communities)
        if (community.feastMonth case final month?)
          if (community.feastDay case final day?)
            for (final eventYear in [year - 1, year, year + 1])
              CalendarEntry(
                id: 'member-community-feast-${community.id}-$eventYear',
                title: '${community.name} feast',
                date: DateTime(eventYear, month, day),
                category: 'Community',
                eventType: 'community_feast',
                relatedEntityType: 'community',
                relatedEntityId: community.id,
                location: community.location,
              ),
      ...managedEvents,
    ]..sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  @override
  Future<List<CommunityRecord>> fetchCommunities() async {
    final communities = await _source.fetchCommunities();
    final safeResidents = residentsRepository == null
        ? null
        : await residentsRepository!.fetchCurrentResidents();
    return communities
        .map((community) {
          final residents = safeResidents == null
              ? community.residents
              : safeResidents
                    .where((item) => item.communityId == community.id)
                    .map((item) => item.person)
                    .toList(growable: false);
          return _safeCommunity(community, residents);
        })
        .toList(growable: false);
  }

  @override
  Future<List<MinistryRecord>> fetchMinistries() => _source.fetchMinistries();
  @override
  Future<List<FormationMember>> fetchFormation() =>
      throw const ProvinceDataException();
  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() =>
      throw const ProvinceDataException();
  @override
  Future<List<EligibilityRole>> fetchEligibilityRoles() =>
      throw const ProvinceDataException();
  @override
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  }) => throw const ProvinceDataException();
  @override
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance() =>
      throw const ProvinceDataException();

  static CommunityRecord _safeCommunity(
    CommunityRecord community,
    List<ProvincePerson> residents,
  ) => CommunityRecord(
    id: community.id,
    name: community.name,
    residentCount: residents.length,
    code: community.code,
    superior: community.superior,
    accountant: community.accountant,
    superiorPerson: community.superiorPerson,
    accountantPerson: community.accountantPerson,
    establishedYear: community.establishedYear,
    phone: community.phone,
    email: community.email,
    type: community.type,
    recordStatus: community.recordStatus,
    communityCategory: community.communityCategory,
    patronSaintName: community.patronSaintName,
    feastMonth: community.feastMonth,
    feastDay: community.feastDay,
    motto: community.motto,
    missionStatement: community.missionStatement,
    visionStatement: community.visionStatement,
    apostolicFocus: community.apostolicFocus,
    communityValues: community.communityValues,
    foundingStory: community.foundingStory,
    historySummary: community.historySummary,
    coverImagePath: community.coverImagePath,
    coverImageUrl: community.coverImageUrl,
    location: community.location,
    residents: residents,
    ministries: community.ministries,
    ministryRecords: community.ministryRecords,
  );
}

/// Province-module adapter backed only by the column-limited MEMBER views.
class SupabaseMemberSafeProvinceRepository implements ProvinceRepository {
  const SupabaseMemberSafeProvinceRepository(
    this._client, {
    this.managedCommunityOnly = false,
  });

  final SupabaseClient _client;
  final bool managedCommunityOnly;

  @override
  Future<List<CommunityRecord>> fetchCommunities() async {
    try {
      final results = await Future.wait([
        _client
            .from(
              managedCommunityOnly
                  ? 'v_community_superior_community_safe'
                  : 'v_member_communities_safe',
            )
            .select()
            .order('name'),
        _client
            .from(
              managedCommunityOnly
                  ? 'v_community_superior_residents_safe'
                  : 'v_member_community_residents_safe',
            )
            .select(),
        _client
            .from(
              managedCommunityOnly
                  ? 'v_community_superior_ministries_safe'
                  : 'v_member_ministries_safe',
            )
            .select()
            .order('ministry_name'),
      ]);
      return mapCommunities(
        List<Map<String, dynamic>>.from(results[0]),
        residentRows: List<Map<String, dynamic>>.from(results[1]),
        ministryRows: List<Map<String, dynamic>>.from(results[2]),
        publicUrl: _publicCoverUrl,
      );
    } catch (error, stackTrace) {
      // Preserve the original Supabase failure in debug logs instead of
      // silently misclassifying every failure as a network problem.
      // ignore: avoid_print
      print('MEMBER community directory query failed: $error\n$stackTrace');
      throw const ProvinceDataException();
    }
  }

  static List<CommunityRecord> mapCommunities(
    List<Map<String, dynamic>> rows, {
    List<Map<String, dynamic>> residentRows = const [],
    List<Map<String, dynamic>> ministryRows = const [],
    String? Function(String bucket, String? path)? publicUrl,
  }) => rows
      .map((row) {
        final id = row['community_id'].toString();
        final residents = MemberCommunityResidentMapper.fromRows(residentRows)
            .where((resident) => resident.communityId == id)
            .map((resident) => resident.person)
            .toList(growable: false);
        final ministries = ministryRows
            .where((ministry) => ministry['community_id']?.toString() == id)
            .map((ministry) => ministry['ministry_name']?.toString())
            .whereType<String>()
            .toList(growable: false);
        final ministryRecords = ministryRows
            .where((ministry) => ministry['community_id']?.toString() == id)
            .map((ministry) => _mapMinistry(ministry, publicUrl: publicUrl))
            .toList(growable: false);
        final location =
            [row['city'], row['district'], row['state'], row['country']]
                .map((value) => value?.toString().trim())
                .whereType<String>()
                .where((value) => value.isNotEmpty)
                .toSet()
                .join(', ');
        final opened = DateTime.tryParse(row['opened_on']?.toString() ?? '');
        return CommunityRecord(
          id: id,
          code: row['code']?.toString(),
          name: row['name']?.toString() ?? 'Community',
          type: row['community_type']?.toString(),
          communityCategory: row['community_category']?.toString(),
          recordStatus: row['active'] == false ? 'Inactive' : 'Active',
          establishedYear: opened?.year,
          coverImagePath: row['cover_image_path']?.toString(),
          coverImageUrl: publicUrl?.call(
            'community-covers',
            row['cover_image_path']?.toString(),
          ),
          location: location.isEmpty ? null : location,
          superior: row['current_superior_member_id'] == null
              ? null
              : DemoPersonaPresenter.memberName(
                  row['current_superior_member_id'].toString(),
                  row['current_superior_display_name']?.toString() ??
                      'Religious',
                ),
          superiorPerson: row['current_superior_member_id'] == null
              ? null
              : ProvincePerson(
                  id: row['current_superior_member_id'].toString(),
                  name: DemoPersonaPresenter.memberName(
                    row['current_superior_member_id'].toString(),
                    row['current_superior_display_name']?.toString() ??
                        'Religious',
                  ),
                  role: 'Community Superior',
                  photoUrl: DemoPersonaPresenter.memberPhoto(
                    row['current_superior_member_id'].toString(),
                    row['current_superior_photo_url']?.toString(),
                  ),
                ),
          accountant: row['current_accountant_member_id'] == null
              ? null
              : DemoPersonaPresenter.memberName(
                  row['current_accountant_member_id'].toString(),
                  row['current_accountant_display_name']?.toString() ??
                      'Religious',
                ),
          accountantPerson: row['current_accountant_member_id'] == null
              ? null
              : ProvincePerson(
                  id: row['current_accountant_member_id'].toString(),
                  name: DemoPersonaPresenter.memberName(
                    row['current_accountant_member_id'].toString(),
                    row['current_accountant_display_name']?.toString() ??
                        'Religious',
                  ),
                  role: 'Community Accountant',
                  photoUrl: DemoPersonaPresenter.memberPhoto(
                    row['current_accountant_member_id'].toString(),
                    row['current_accountant_photo_url']?.toString(),
                  ),
                ),
          residentCount:
              (row['current_resident_count'] as num?)?.toInt() ??
              residents.length,
          residents: residents,
          ministries: ministries,
          ministryRecords: ministryRecords,
        );
      })
      .toList(growable: false);

  @override
  Future<List<MinistryRecord>> fetchMinistries() async {
    try {
      final rows = await _client
          .from('v_member_ministries_safe')
          .select()
          .order('ministry_name');
      return List<Map<String, dynamic>>.from(rows)
          .map((row) => _mapMinistry(row, publicUrl: _publicCoverUrl))
          .toList(growable: false);
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('MEMBER ministry directory query failed: $error\n$stackTrace');
      throw const ProvinceDataException();
    }
  }

  static MinistryRecord _mapMinistry(
    Map<String, dynamic> row, {
    String? Function(String bucket, String? path)? publicUrl,
  }) {
    String? text(String key) => row[key]?.toString();
    int? count(String key) => int.tryParse(text(key) ?? '');
    List<String> values(String key) => row[key] is List
        ? List<String>.from((row[key] as List).map((value) => '$value'))
        : const [];
    final location = [
      text('city'),
      text('district'),
      text('state'),
      text('country'),
    ].whereType<String>().where((value) => value.isNotEmpty).toSet().join(', ');
    final headId = text('head_member_id');
    final canonicalHeadName = text('head_display_name');
    final headName = canonicalHeadName == null
        ? null
        : DemoPersonaPresenter.memberName(headId, canonicalHeadName);
    final coverImagePath = text('cover_image_path');
    return MinistryRecord(
      id: text('ministry_id') ?? '',
      name: text('ministry_name') ?? 'Ministry',
      type: text('ministry_type'),
      community: text('community_name'),
      status: text('operational_status'),
      location: location.isEmpty ? null : location,
      headName: headName,
      headRole: text('head_role'),
      headPerson: headId == null
          ? null
          : ProvincePerson(
              id: headId,
              name: headName ?? 'Religious',
              role: text('head_role'),
              photoUrl: DemoPersonaPresenter.memberPhoto(
                headId,
                text('head_photo_url'),
              ),
            ),
      totalStaff: count('staff_count'),
      totalStudents: count('student_count'),
      totalBeneficiaries: count('beneficiary_count'),
      motto: text('motto'),
      missionStatement: text('mission_statement'),
      visionStatement: text('vision_statement'),
      patronSaintName: text('patron_saint_name'),
      apostolicFocus: values('apostolic_focus'),
      ministryValues: values('ministry_values'),
      coverImagePath: coverImagePath,
      coverImageUrl: publicUrl?.call('ministry-covers', coverImagePath),
    );
  }

  String? _publicCoverUrl(String bucket, String? path) {
    return publicStorageImageUrl(_client, bucket, path);
  }

  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async {
    if (!managedCommunityOnly) return const [];
    final rows = await _client
        .from('community_events')
        .select()
        .neq('status', 'cancelled')
        .order('starts_at');
    return rows.map(_communityEvent).toList(growable: false);
  }

  static CalendarEntry _communityEvent(Map<String, dynamic> row) =>
      CalendarEntry(
        id: row['id']?.toString(),
        title: row['title']?.toString() ?? 'Community event',
        date: DateTime.parse(row['starts_at'].toString()).toLocal(),
        endDate: DateTime.tryParse(row['ends_at']?.toString() ?? '')?.toLocal(),
        category: 'Community',
        eventType: row['event_type']?.toString(),
        relatedEntityType: 'community',
        relatedEntityId: row['community_id']?.toString(),
        location: row['venue']?.toString(),
        priority: row['status']?.toString(),
      );
  @override
  Future<List<FormationMember>> fetchFormation() =>
      throw const ProvinceDataException();
  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() =>
      throw const ProvinceDataException();
  @override
  Future<List<EligibilityRole>> fetchEligibilityRoles() =>
      throw const ProvinceDataException();
  @override
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  }) => throw const ProvinceDataException();
  @override
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance() =>
      throw const ProvinceDataException();
}

class MemberSafeReligiousProfileRepository
    implements ReligiousProfileRepository {
  const MemberSafeReligiousProfileRepository({
    required this.currentMemberId,
    required this.directoryRepository,
    required this.selfProfileRepository,
    this.otherProfileRepository,
    this.ownCommunityProfileRepository,
    this.accessRole = AccessRole.member,
  });
  final String currentMemberId;
  final MemberDirectoryRepository directoryRepository;
  final ReligiousProfileRepository selfProfileRepository;
  final ReligiousProfileRepository? otherProfileRepository;
  final ReligiousProfileRepository? ownCommunityProfileRepository;
  final AccessRole accessRole;

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    if (memberId == currentMemberId) {
      _logSelection(memberId, 'self-profile');
      return selfProfileRepository.fetchProfile(currentMemberId);
    }
    if (accessRole == AccessRole.communitySuperior) {
      final repository = ownCommunityProfileRepository;
      if (repository != null) {
        _logSelection(memberId, 'community-superior-resident-profile');
        try {
          return await repository.fetchProfile(memberId);
        } on ReligiousProfileException catch (error) {
          if (error.kind != ReligiousProfileFailureKind.notFound) rethrow;
          _logSelection(memberId, 'member-safe-profile-fallback');
        }
      }
    }
    if (otherProfileRepository case final repository?) {
      _logSelection(memberId, 'member-safe-profile');
      return repository.fetchProfile(memberId);
    }
    final entries = await directoryRepository.fetchMembers();
    final entry = entries.where((item) => item.id == memberId).firstOrNull;
    if (entry == null) {
      throw const ReligiousProfileException(
        ReligiousProfileFailureKind.notFound,
      );
    }
    return ReligiousProfile(
      memberId: entry.id,
      religiousId: entry.religiousId,
      displayName: entry.displayName,
      title: entry.title,
      photoUrl: entry.photoUrl,
      memberStatus: entry.memberStatus,
      canonicalStatus: entry.canonicalStatus,
      community: entry.community,
      communityRole: entry.communityRole,
      ministry: entry.ministry,
      ministryRole: entry.ministryRole,
      sections: const ReligiousProfileSections(),
    );
  }

  void _logSelection(String targetMemberId, String resolver) {
    if (!kDebugMode) return;
    debugPrint(
      'Profile resolver role=${accessRole.name} '
      'caller_member_id=$currentMemberId target_member_id=$targetMemberId '
      'repository=$resolver',
    );
  }
}

class SupabaseOtherMemberProfileRepository
    implements ReligiousProfileRepository {
  const SupabaseOtherMemberProfileRepository(
    this._client, {
    this.rpcName = 'get_other_member_profile_safe',
  });
  final SupabaseClient _client;
  final String rpcName;

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    try {
      final raw = await _client.rpc(
        rpcName,
        params: {'target_member_id': memberId},
      );
      if (raw is! Map) {
        throw const ReligiousProfileException(
          ReligiousProfileFailureKind.notFound,
        );
      }
      return mapProfile(Map<String, dynamic>.from(raw), memberId: memberId);
    } on ReligiousProfileException {
      rethrow;
    } on AuthException catch (error) {
      _logError(memberId, error.message, error.statusCode);
      throw ReligiousProfileException(
        ReligiousProfileFailureKind.authentication,
        cause: error,
      );
    } on PostgrestException catch (error) {
      _logError(memberId, error.message, error.code);
      throw ReligiousProfileException(
        error.code == '42501'
            ? ReligiousProfileFailureKind.permission
            : ReligiousProfileFailureKind.unexpected,
        cause: error,
      );
    }
  }

  void _logError(String targetMemberId, String message, String? code) {
    if (!kDebugMode) return;
    debugPrint(
      'Profile RPC $rpcName target_member_id=$targetMemberId '
      'error_code=${code ?? 'unknown'} message=$message',
    );
  }

  static ReligiousProfile mapProfile(
    Map<String, dynamic> row, {
    required String memberId,
  }) {
    if (_text(row['member_id']) != memberId) {
      throw const ReligiousProfileException(
        ReligiousProfileFailureKind.notFound,
      );
    }
    final address = [
      row['address'],
      row['city'],
      row['district'],
      row['state'],
      row['country'],
    ].map(_text).whereType<String>().toSet().join(', ');
    return ReligiousProfile(
      memberId: memberId,
      religiousId: _text(row['religious_id']) ?? '',
      displayName: DemoPersonaPresenter.memberName(
        memberId,
        _text(row['display_name']) ?? 'Religious',
      ),
      title: DemoPersonaPresenter.memberTitle(
        memberId,
        _title(_text(row['ecclesiastical_title_code'])) ?? '',
      ),
      photoUrl: DemoPersonaPresenter.memberPhoto(
        memberId,
        _text(row['photo_url']),
      ),
      memberStatus: _label(_text(row['member_status_code'])) ?? 'Active',
      canonicalStatus: _label(_text(row['canonical_status_code'])),
      dateOfBirth: _date(row['date_of_birth']),
      community: _text(row['community_name']),
      communityRole: _label(_text(row['community_responsibility_code'])),
      communityFromDate: _date(row['community_from_date']),
      ministry: _text(row['ministry_name']),
      ministryRole: _label(_text(row['ministry_responsibility_code'])),
      ministryFromDate: _date(row['ministry_from_date']),
      origin: MemberOriginDetails(
        nativePlace: _text(row['city']),
        district: _text(row['district']),
        state: _text(row['state']),
        country: _text(row['country']),
      ),
      sections: ReligiousProfileSections(
        contacts: [
          if (_text(row['mobile']) case final value?)
            LabeledValue('Mobile', value),
          if (_text(row['whatsapp']) case final value?)
            LabeledValue('WhatsApp', value),
          if (_text(row['official_email']) case final value?)
            LabeledValue('Official Email', value),
          if (address.isNotEmpty) LabeledValue('Postal Address', address),
        ],
        vocationEvents: _rows(row['vocation_events'])
            .map(
              (item) => VocationEvent(
                sourceId: _text(item['id']),
                label:
                    _label(_text(item['event_type_code'])) ?? 'Vocation event',
                date: _date(item['event_date']),
                place: _text(item['place']),
              ),
            )
            .toList(growable: false),
        qualifications: _rows(row['qualifications'])
            .map(
              (item) => QualificationRecord(
                qualification: _text(item['qualification']) ?? 'Qualification',
                specialization: _text(item['specialization']),
                institution: _text(item['institution']),
                subject: _text(item['subject']),
                year: int.tryParse(_text(item['year_of_passing']) ?? ''),
                country: _text(item['country']),
              ),
            )
            .toList(growable: false),
        communityAssignments: _rows(
          row['community_assignments'],
        ).map((item) => _assignment(item, 'Community')).toList(growable: false),
        ministryAssignments: _rows(
          row['ministry_assignments'],
        ).map((item) => _assignment(item, 'Ministry')).toList(growable: false),
        offices: _rows(row['normal_responsibilities'])
            .map(
              (item) => OfficeAppointment(
                sourceId: _text(item['id']),
                office: _label(_text(item['office'])) ?? 'Responsibility',
                context: _text(item['context']),
                contextKind: switch (_text(item['context_kind'])) {
                  'ministry' => OfficeContextKind.ministry,
                  'community' => OfficeContextKind.community,
                  _ => null,
                },
                relatedEntityId: _text(item['related_entity_id']),
                fromDate: _date(item['from_date']),
                toDate: _date(item['to_date']),
              ),
            )
            .toList(growable: false),
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
  static String? _label(String? value) => value
      ?.toLowerCase()
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
