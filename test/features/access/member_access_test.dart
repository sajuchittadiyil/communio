import 'package:communio/app/shell/models/app_navigation.dart';
import 'package:communio/app/shell/widgets/provincial_mobile_navigation.dart';
import 'package:communio/features/access/data/member_safe_repositories.dart';
import 'package:communio/features/access/models/app_access_context.dart';
import 'package:communio/features/access/screens/member_home_screen.dart';
import 'package:communio/features/documents/data/documents_repository.dart';
import 'package:communio/features/documents/models/province_document.dart';
import 'package:communio/features/province_modules/data/province_repository.dart';
import 'package:communio/features/province_modules/models/province_models.dart';
import 'package:communio/features/religious_profile/data/religious_profile_repository.dart';
import 'package:communio/features/religious_profile/models/religious_profile.dart';
import 'package:communio/features/religious_directory/data/member_directory_repository.dart';
import 'package:communio/features/religious_directory/models/member_directory_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  test('MEMBER navigation contains only approved destinations', () {
    final destinations = RoleNavigationConfiguration.member.items
        .map((item) => item.destination)
        .toSet();
    expect(
      destinations,
      containsAll({
        AppDestination.dashboard,
        AppDestination.religious,
        AppDestination.communities,
        AppDestination.calendar,
        AppDestination.ministries,
        AppDestination.documents,
        AppDestination.congregationProfile,
        AppDestination.provinceProfile,
        AppDestination.myProfile,
        AppDestination.askCommunio,
      }),
    );
    expect(destinations, isNot(contains(AppDestination.governance)));
    expect(destinations, isNot(contains(AppDestination.formation)));
    expect(destinations, isNot(contains(AppDestination.reports)));
    expect(
      destinationAllowed(
        RoleNavigationConfiguration.member,
        AppDestination.governance,
      ),
      isFalse,
    );
  });

  test('Provincial navigation retains Formation and Governance', () {
    final destinations = RoleNavigationConfiguration.provincial.items.map(
      (item) => item.destination,
    );
    expect(destinations, contains(AppDestination.formation));
    expect(destinations, contains(AppDestination.governance));
    expect(destinations, contains(AppDestination.documents));
  });

  test('Community Superior navigation is MEMBER-shaped and restricted', () {
    final destinations = RoleNavigationConfiguration.communitySuperior.items
        .map((item) => item.destination)
        .toSet();
    expect(
      destinations,
      RoleNavigationConfiguration.member.items
          .map((item) => item.destination)
          .toSet(),
    );
    expect(destinations, isNot(contains(AppDestination.formation)));
    expect(destinations, isNot(contains(AppDestination.governance)));
    expect(destinations, isNot(contains(AppDestination.reports)));
  });

  test('Community Superior context remains distinct from MEMBER', () {
    const access = AppAccessContext(
      role: AccessRole.communitySuperior,
      memberId: 'felix-uuid',
      managedCommunityId: 'sacred-heart-uuid',
      managedCommunityName: 'Sacred Heart Community',
      communityResponsibilityCode: 'community_superior',
    );
    expect(access.isCommunitySuperior, isTrue);
    expect(access.isMemberLike, isTrue);
    expect(access.isMember, isFalse);
  });

  testWidgets('MEMBER mobile navigation exposes Home, directory and More', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ProvincialMobileNavigation(
            configuration: RoleNavigationConfiguration.member,
            selected: AppDestination.dashboard,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Religious'), findsOneWidget);
    expect(find.text('Communities'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Ministries'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Ask Communio'), findsOneWidget);
    expect(find.text('Governance'), findsNothing);
    expect(find.text('Formation'), findsNothing);
  });

  testWidgets(
    'MEMBER home uses mapped identity and has no Provincial intelligence',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MemberHomeScreen(
            displayName: 'Member',
            memberId: 'roy',
            directoryRepository: const _RoyDirectoryRepository(),
            onNavigate: (_) {},
            onMyProfile: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Roy'), findsOneWidget);
      expect(find.text('My Community'), findsOneWidget);
      expect(find.text('Sacred Heart Community'), findsOneWidget);
      expect(find.text('My Ministry'), findsOneWidget);
      expect(find.textContaining('St. Thomas Diocesan School'), findsOneWidget);
      expect(find.text('Province Attention'), findsNothing);
      expect(find.text('Member Movements'), findsNothing);
      expect(find.text('Formation'), findsNothing);
      expect(find.text('Governance'), findsNothing);
      expect(find.text('Community Members'), findsNothing);
    },
  );

  testWidgets('Community Superior Home displays managed community actions', (
    tester,
  ) async {
    String? openedCommunity;
    var openedMyProfile = false;
    var openedAdministration = '';
    AppDestination? navigatedDestination;
    await tester.pumpWidget(
      MaterialApp(
        home: MemberHomeScreen(
          displayName: 'Felix',
          memberId: 'other',
          directoryRepository: const _DirectoryRepository(),
          onNavigate: (destination) => navigatedDestination = destination,
          onMyProfile: () => openedMyProfile = true,
          communitySuperior: true,
          managedCommunityName: 'Sacred Heart Community',
          managedCommunityId: 'sacred-heart-uuid',
          provinceRepository: _ProvinceRepository(),
          onCommunity: (id) => openedCommunity = id,
          onAddCommunityEvent: () => openedAdministration = 'event',
          onPlanCommunityEvent: () => openedAdministration = 'plan',
          onCommunityMeetingMinutes: () => openedAdministration = 'minutes',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community Superior'), findsOneWidget);
    expect(find.text('Sacred Heart Community'), findsWidgets);
    expect(find.text("TODAY'S CELEBRATIONS"), findsOneWidget);
    expect(find.text('MY COMMUNITY TODAY'), findsOneWidget);
    expect(find.text('Community Members'), findsNothing);
    expect(find.text('COMMUNITY ADMINISTRATION'), findsOneWidget);
    expect(find.text('Add Calendar Event'), findsOneWidget);
    expect(find.text('Plan Community Event'), findsOneWidget);
    expect(find.text('Meeting Minutes'), findsOneWidget);
    expect(find.text('Community Calendar'), findsOneWidget);
    expect(find.text('Community Documents'), findsOneWidget);
    expect(navigatedDestination, isNull);
    await tester.ensureVisible(find.text('Plan Community Event'));
    await tester.tap(find.text('Plan Community Event'));
    expect(openedAdministration, 'plan');
    await tester.ensureVisible(find.text('My Profile'));
    await tester.tap(find.text('My Profile'));
    expect(openedMyProfile, isTrue);
    await tester.ensureVisible(find.text('Community Calendar'));
    await tester.tap(find.text('Community Calendar'));
    expect(navigatedDestination, AppDestination.calendar);
    await tester.ensureVisible(find.text('Community Documents'));
    await tester.tap(find.text('Community Documents'));
    expect(navigatedDestination, AppDestination.documents);
    await tester.ensureVisible(find.text('My Community'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Community'));
    expect(openedCommunity, 'sacred-heart-uuid');
  });

  test('Community Superior documents remain scoped to own community', () async {
    final documents = await CommunitySuperiorDocumentsRepository(
      const _SuperiorDocumentSource(),
      managedCommunityId: 'own-community',
    ).fetchDocuments();
    expect(documents.map((item) => item.id), ['member-doc', 'own-doc']);
  });

  test(
    'MEMBER documents exclude Provincial, Council and Restricted records',
    () async {
      final documents = await const MemberDocumentsRepository(
        DemoDocumentsRepository(),
      ).fetchDocuments();
      expect(documents, isNotEmpty);
      expect(
        documents.every(
          (document) => document.visibility == 'Province Members',
        ),
        isTrue,
      );
      expect(
        documents.map((document) => document.title),
        isNot(contains('Provincial Council Minutes - 20 August 2026')),
      );
      expect(
        documents.map((document) => document.title),
        isNot(contains('Province Financial Summary 2025-26')),
      );
    },
  );

  test('MEMBER calendar is built only from community feast data', () async {
    final source = _ProvinceRepository();
    final entries = await MemberCalendarRepository(
      source,
    ).fetchCalendarEntries();
    expect(source.privilegedCalendarRequested, isFalse);
    expect(entries, hasLength(3));
    expect(
      entries.every((entry) => entry.eventType == 'community_feast'),
      isTrue,
    );
    expect(entries.any((entry) => entry.category == 'Travel'), isFalse);
  });

  test('other member profiles expose approved directory facts only', () async {
    final selfProfile = _ProfileRepository();
    final repository = MemberSafeReligiousProfileRepository(
      currentMemberId: 'self',
      directoryRepository: const _DirectoryRepository(),
      selfProfileRepository: selfProfile,
      otherProfileRepository: const _OtherSafeProfileRepository(),
    );
    final other = await repository.fetchProfile('other');
    expect(other.sections.family, isEmpty);
    expect(
      other.sections.contacts.map((item) => item.label),
      containsAll(['Mobile', 'Official Email']),
    );
    expect(
      other.sections.contacts.map((item) => item.label),
      isNot(contains('Postal Address')),
    );
    expect(other.sections.documents, isEmpty);
    expect(other.sections.leaveHistory, isEmpty);
    expect(other.origin?.state, 'Jharkhand');
    expect(other.dateOfBirth, isNull);
    expect(other.community, 'Safe Community');
    expect(other.sections.qualifications, isNotEmpty);
    expect(other.sections.communityAssignments, isNotEmpty);
    expect(other.sections.ministryAssignments, isNotEmpty);
    expect(other.sections.offices, isNotEmpty);
    expect(other.sections.vocationEvents, isNotEmpty);
    expect(other.sections.family, isEmpty);
    expect(other.sections.homeContacts, isEmpty);
    expect(selfProfile.requests, isEmpty);

    final own = await repository.fetchProfile('self');
    expect(own.sections.vocationEvents, isNotEmpty);
    expect(own.sections.qualifications, isNotEmpty);
    expect(own.sections.communityAssignments, isNotEmpty);
    expect(own.sections.family, isEmpty);
    expect(selfProfile.requests, ['self']);
  });

  test(
    'My Profile uses canonical member UUID and rejects religious ID',
    () async {
      final selfProfile = _ProfileRepository();
      final repository = MemberSafeReligiousProfileRepository(
        currentMemberId: 'member-uuid',
        directoryRepository: const _DirectoryRepository(),
        selfProfileRepository: selfProfile,
      );

      final own = await repository.fetchProfile('member-uuid');
      expect(own.memberId, 'member-uuid');
      expect(selfProfile.requests, ['member-uuid']);

      await expectLater(
        repository.fetchProfile('REL-0019'),
        throwsA(
          isA<ReligiousProfileException>().having(
            (error) => error.kind,
            'kind',
            ReligiousProfileFailureKind.notFound,
          ),
        ),
      );
      expect(selfProfile.requests, ['member-uuid']);
    },
  );

  test(
    'Community Superior profile resolver centralizes self, resident and outsider paths',
    () async {
      final self = _TrackingProfileRepository('self');
      final enhanced = _TrackingProfileRepository(
        'enhanced',
        notFoundIds: {'outsider'},
      );
      final memberSafe = _TrackingProfileRepository('member-safe');
      final repository = MemberSafeReligiousProfileRepository(
        currentMemberId: '8da743b0-008a-4efd-bb9e-7a9783cbb475',
        accessRole: AccessRole.communitySuperior,
        directoryRepository: const _DirectoryRepository(),
        selfProfileRepository: self,
        ownCommunityProfileRepository: enhanced,
        otherProfileRepository: memberSafe,
      );

      final own = await repository.fetchProfile(
        '8da743b0-008a-4efd-bb9e-7a9783cbb475',
      );
      final resident = await repository.fetchProfile('resident-uuid');
      final outsider = await repository.fetchProfile('outsider');

      expect(own.displayName, 'self');
      expect(resident.displayName, 'enhanced');
      expect(outsider.displayName, 'member-safe');
      expect(self.requests, ['8da743b0-008a-4efd-bb9e-7a9783cbb475']);
      expect(enhanced.requests, ['resident-uuid', 'outsider']);
      expect(memberSafe.requests, ['outsider']);
    },
  );

  test(
    'Community Superior does not downgrade permission failure to MEMBER-safe fallback',
    () async {
      final repository = MemberSafeReligiousProfileRepository(
        currentMemberId: 'felix',
        accessRole: AccessRole.communitySuperior,
        directoryRepository: const _DirectoryRepository(),
        selfProfileRepository: _TrackingProfileRepository('self'),
        ownCommunityProfileRepository: _TrackingProfileRepository(
          'enhanced',
          failure: ReligiousProfileFailureKind.permission,
        ),
        otherProfileRepository: _TrackingProfileRepository('member-safe'),
      );
      await expectLater(
        repository.fetchProfile('resident'),
        throwsA(
          isA<ReligiousProfileException>().having(
            (error) => error.kind,
            'kind',
            ReligiousProfileFailureKind.permission,
          ),
        ),
      );
    },
  );

  test('Community Superior resident maps pastoral profile sections only', () {
    final profile = SupabaseOtherMemberProfileRepository.mapProfile(
      {
        'member_id': 'resident',
        'display_name': 'Resident Member',
        'qualifications': [
          {'qualification': 'B.Ed.'},
        ],
        'languages': [
          {'language_name': 'Hindi', 'can_speak': true},
        ],
        'home_contacts': [
          {
            'name': 'Family Home',
            'relationship': 'Home',
            'phone': '+91 90000 00000',
          },
        ],
        'family': [
          {
            'name': 'Parent Name',
            'relationship': 'Father',
            'life_status': 'living',
          },
        ],
        'documents': [
          {'type': 'Will'},
        ],
        'confidential_notes': 'Must never map',
      },
      memberId: 'resident',
      includeFamily: true,
    );

    expect(profile.sections.qualifications, hasLength(1));
    expect(profile.sections.languages, hasLength(1));
    expect(profile.sections.family, hasLength(2));
    expect(profile.sections.homeContacts, hasLength(1));
    expect(profile.sections.documents, isEmpty);
    expect(profile.sections.leaveHistory, isEmpty);
  });

  test('other member maps safe origin without private postal address', () {
    final profile = SupabaseOtherMemberProfileRepository.mapProfile({
      'member_id': 'other',
      'display_name': 'Other Member',
      'date_of_birth': '1984-07-12',
      'birthplace': 'Pala',
      'native_place': 'Kottayam',
      'home_parish': 'St Mary Parish',
      'diocese': 'Kottayam',
      'district': 'Kottayam',
      'state': 'Kerala',
      'country': 'India',
      'address': 'Private family street address',
    }, memberId: 'other');

    expect(profile.origin?.nativePlace, 'Kottayam');
    expect(profile.origin?.birthplace, 'Pala');
    expect(profile.origin?.homeParish, 'St Mary Parish');
    expect(profile.origin?.diocese, 'Kottayam');
    expect(
      profile.sections.contacts.map((item) => item.value),
      isNot(contains('Private family street address')),
    );
    expect(profile.dateOfBirth, DateTime(1984, 7, 12));
  });

  test('member-safe mapping preserves every returned vocation milestone', () {
    final profile = SupabaseOtherMemberProfileRepository.mapProfile({
      'member_id': 'other',
      'display_name': 'Other Member',
      'vocation_events': [
        {'event_type_code': 'entry', 'event_date': '2001-06-01'},
        {'event_type_code': 'postulancy', 'event_date': '2002-06-01'},
        {'event_type_code': 'novitiate', 'event_date': '2003-06-01'},
        {'event_type_code': 'first_profession', 'event_date': '2004-06-01'},
        {'event_type_code': 'perpetual_profession', 'event_date': '2010-06-01'},
      ],
    }, memberId: 'other');

    expect(profile.sections.vocationEvents, hasLength(5));
    expect(
      profile.sections.vocationEvents.map((event) => event.label),
      containsAll([
        'Entry',
        'Postulancy',
        'Novitiate',
        'First Profession',
        'Perpetual Profession',
      ]),
    );
  });

  test(
    'member-safe community mapping retains populated identity narrative',
    () {
      final communities = SupabaseMemberSafeProvinceRepository.mapCommunities([
        {
          'community_id': 'community-1',
          'name': 'Sacred Heart Community',
          'active': true,
          'description': 'A community serving the local Church.',
          'motto': 'In communion and service',
          'mission_statement': 'To live and serve together.',
          'vision_statement': 'A compassionate local community.',
          'apostolic_focus': ['Pastoral care'],
          'community_values': ['Communion'],
          'founding_story': 'Opened for mission.',
          'history_summary': 'Continues its local service.',
        },
      ]);

      expect(communities.single.description, isNotEmpty);
      expect(communities.single.missionStatement, isNotEmpty);
      expect(communities.single.visionStatement, isNotEmpty);
      expect(communities.single.apostolicFocus, ['Pastoral care']);
      expect(communities.single.communityValues, ['Communion']);
    },
  );

  test('other member does not create an empty Origin card model', () {
    final profile = SupabaseOtherMemberProfileRepository.mapProfile({
      'member_id': 'other',
      'display_name': 'Other Member',
    }, memberId: 'other');
    expect(profile.origin, isNull);
  });
}

class _OtherSafeProfileRepository implements ReligiousProfileRepository {
  const _OtherSafeProfileRepository();
  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async =>
      SupabaseOtherMemberProfileRepository.mapProfile({
        'member_id': memberId,
        'religious_id': 'REL-OTHER',
        'display_name': 'Other Member',
        'member_status_code': 'active',
        'mobile': '+91 90000 00020',
        'official_email': 'other@communio.com',
        'address': 'Private Mission Road',
        'native_place': 'Ranchi',
        'state': 'Jharkhand',
        'country': 'India',
        'community_name': 'Safe Community',
        'ministry_name': 'Safe Ministry',
        'vocation_events': [
          {'event_type_code': 'first_profession', 'event_date': '2005-06-01'},
        ],
        'qualifications': [
          {
            'qualification': 'M.Ed.',
            'institution': 'St. Xavier College',
            'year_of_passing': '2012',
          },
        ],
        'community_assignments': [
          {
            'name': 'Safe Community',
            'responsibility_code': 'member',
            'from_date': '2020-01-01',
          },
        ],
        'ministry_assignments': [
          {
            'name': 'Safe Ministry',
            'responsibility_code': 'teacher',
            'from_date': '2021-01-01',
          },
        ],
        'normal_responsibilities': [
          {
            'office': 'director',
            'context': 'Safe Ministry',
            'context_kind': 'ministry',
            'from_date': '2021-01-01',
          },
        ],
        'family': [
          {'name': 'Must not map'},
        ],
        'emergency_phone': '+91 00000 00000',
        'confidential_notes': 'Must not map',
        'documents': [
          {'type': 'Will'},
        ],
      }, memberId: memberId);
}

class _SuperiorDocumentSource implements DocumentsRepository {
  const _SuperiorDocumentSource();
  @override
  Future<List<ProvinceDocument>> fetchDocuments() async => [
    _testDocument('member-doc', 'Province Members'),
    _testDocument('own-doc', 'Community Leadership', entityId: 'own-community'),
    _testDocument(
      'other-doc',
      'Community Leadership',
      entityId: 'other-community',
    ),
    _testDocument('council-doc', 'Council'),
    _testDocument('restricted-doc', 'Restricted'),
  ];
}

ProvinceDocument _testDocument(
  String id,
  String visibility, {
  String? entityId,
}) => ProvinceDocument(
  id: id,
  title: id,
  category: DocumentCategory.community,
  documentType: 'Test',
  documentDate: DateTime(2026),
  description: '',
  visibility: visibility,
  relatedEntityType: entityId == null ? null : 'community',
  relatedEntityId: entityId,
  createdAt: DateTime(2026),
);

class _DirectoryRepository implements MemberDirectoryRepository {
  const _DirectoryRepository();
  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async => const [
    MemberDirectoryEntry(
      id: 'other',
      religiousId: 'REL-OTHER',
      displayName: 'Other Member',
      memberStatus: 'Active',
      community: 'Safe Community',
      ministry: 'Safe Ministry',
    ),
  ];
}

class _RoyDirectoryRepository implements MemberDirectoryRepository {
  const _RoyDirectoryRepository();
  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async => const [
    MemberDirectoryEntry(
      id: 'roy',
      religiousId: 'REL-0019',
      displayName: 'Roy Noronha',
      memberStatus: 'Active',
      community: 'Sacred Heart Community',
      communityId: 'community-uuid',
      ministry: 'St. Thomas Diocesan School',
      ministryId: 'ministry-uuid',
      ministryRole: 'Teacher',
    ),
    MemberDirectoryEntry(
      id: 'other',
      religiousId: 'REL-0020',
      displayName: 'Another Religious',
      memberStatus: 'Active',
    ),
  ];
}

class _ProvinceRepository implements ProvinceRepository {
  bool privilegedCalendarRequested = false;
  @override
  Future<List<CommunityRecord>> fetchCommunities() async => const [
    CommunityRecord(
      id: 'community',
      name: 'St. Antony Community',
      residentCount: 4,
      feastMonth: 6,
      feastDay: 13,
      location: 'Demo City',
    ),
  ];
  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async {
    privilegedCalendarRequested = true;
    return [
      CalendarEntry(
        title: 'Private travel',
        date: DateTime(2026),
        category: 'Travel',
      ),
    ];
  }

  @override
  Future<List<MinistryRecord>> fetchMinistries() async => const [];
  @override
  Future<List<FormationMember>> fetchFormation() async => const [];
  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() async => const [];
  @override
  Future<List<EligibilityRole>> fetchEligibilityRoles() async => const [];
  @override
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  }) async => const [];
  @override
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance() async =>
      const [];
}

class _ProfileRepository implements ReligiousProfileRepository {
  final List<String> requests = [];

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    requests.add(memberId);
    return ReligiousProfile(
      memberId: memberId,
      religiousId: 'REL-0019',
      displayName: memberId,
      memberStatus: 'Active',
      sections: const ReligiousProfileSections(
        vocationEvents: [VocationEvent(label: 'First Profession')],
        qualifications: [QualificationRecord(qualification: 'Degree')],
        communityAssignments: [
          AssignmentRecord(kind: 'Community', name: 'Community'),
        ],
      ),
    );
  }
}

class _TrackingProfileRepository implements ReligiousProfileRepository {
  _TrackingProfileRepository(
    this.label, {
    this.notFoundIds = const {},
    this.failure,
  });
  final String label;
  final Set<String> notFoundIds;
  final ReligiousProfileFailureKind? failure;
  final List<String> requests = [];

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    requests.add(memberId);
    if (failure case final kind?) throw ReligiousProfileException(kind);
    if (notFoundIds.contains(memberId)) {
      throw const ReligiousProfileException(
        ReligiousProfileFailureKind.notFound,
      );
    }
    return ReligiousProfile(
      memberId: memberId,
      displayName: label,
      memberStatus: 'Active',
      sections: const ReligiousProfileSections(),
    );
  }
}
