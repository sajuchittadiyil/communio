import 'package:communio/features/access/data/member_community_residents_repository.dart';
import 'package:communio/features/access/data/member_safe_repositories.dart';
import 'package:communio/features/access/data/member_self_profile_repository.dart';
import 'package:communio/features/province_modules/data/province_repository.dart';
import 'package:communio/features/province_modules/models/province_models.dart';
import 'package:communio/features/province_modules/screens/province_module_screens.dart';
import 'package:communio/features/religious_directory/models/member_directory_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('self profile maps own mobile, WhatsApp and email', () {
    final profile = SupabaseMemberSelfProfileRepository.mapProfile({
      'member_id': 'roy-uuid',
      'religious_id': 'REL-0019',
      'display_name': 'Roy Noronha',
      'member_status_code': 'active',
      'mobile': '+91 90000 00019',
      'whatsapp': '+91 90000 00019',
      'official_email': 'roy@communio.com',
    }, expectedMemberId: 'roy-uuid');

    expect(profile.sections.contacts.map((item) => (item.label, item.value)), [
      ('Mobile', '+91 90000 00019'),
      ('WhatsApp', '+91 90000 00019'),
      ('Official Email', 'roy@communio.com'),
    ]);
    expect(profile.sections.homeContacts, isEmpty);
  });

  test('self profile omits only missing contact fields', () {
    final profile = SupabaseMemberSelfProfileRepository.mapProfile({
      'member_id': 'roy-uuid',
      'display_name': 'Roy Noronha',
      'member_status_code': 'active',
      'official_email': 'roy@communio.com',
    }, expectedMemberId: 'roy-uuid');
    expect(profile.sections.contacts, hasLength(1));
    expect(profile.sections.contacts.single.label, 'Official Email');
  });

  test('self profile maps caller-bound origin and home facts', () {
    final profile = SupabaseMemberSelfProfileRepository.mapProfile({
      'member_id': 'roy-uuid',
      'display_name': 'Roy Noronha',
      'member_status_code': 'active',
      'native_details': {
        'native_place': 'Mangaluru',
        'home_parish': 'St. Antony Parish',
        'diocese': 'Mangalore',
        'district': 'Dakshina Kannada',
        'state': 'Karnataka',
        'country': 'India',
      },
      'home_contacts': [
        {
          'name': 'Family Home',
          'relationship': 'Home',
          'address': '19 Church Road, Mangaluru',
          'phone': '+91 90000 00019',
        },
      ],
      'family': [
        {
          'name': 'Parent Name',
          'relationship': 'Father',
          'life_status': 'living',
        },
      ],
    }, expectedMemberId: 'roy-uuid');

    expect(profile.origin?.nativePlace, 'Mangaluru');
    expect(profile.origin?.homeParish, 'St. Antony Parish');
    expect(profile.origin?.diocese, 'Mangalore');
    expect(profile.origin?.state, 'Karnataka');
    expect(profile.sections.homeContacts, hasLength(2));
    expect(profile.sections.homeContacts.first.label, 'Home Address');
    expect(profile.sections.homeContacts.last.label, 'Home Phone');
    expect(profile.sections.family, hasLength(2));
  });

  test('self profile maps structured languages and nullable capabilities', () {
    final profile = SupabaseMemberSelfProfileRepository.mapProfile({
      'member_id': 'roy-uuid',
      'display_name': 'Roy Noronha',
      'member_status_code': 'active',
      'languages': [
        {
          'language_name': 'Kannada',
          'language_code': 'kn',
          'proficiency_level_code': 'PROFICIENT',
          'can_speak': true,
          'can_read': true,
          'can_write': null,
          'is_primary': true,
          'is_native': false,
        },
      ],
    }, expectedMemberId: 'roy-uuid');

    final language = profile.sections.languages.single;
    expect(language.name, 'Kannada');
    expect(language.proficiencyLabel, 'Proficient');
    expect(language.capabilityLabel, 'Proficient · Speak · Read');
    expect(language.canWrite, isNull);
    expect(language.isPrimary, isTrue);
  });

  test('self profile maps only explicit transfer rows', () {
    final profile = SupabaseMemberSelfProfileRepository.mapProfile({
      'member_id': 'roy-uuid',
      'display_name': 'Roy Noronha',
      'member_status_code': 'active',
      'community_assignments': [
        {'name': 'Assignment history is not a transfer'},
      ],
      'transfers': [
        {
          'transfer_id': 'transfer-1',
          'from_community_id': 'community-1',
          'from_community_name': 'St. Antony Community',
          'to_community_id': 'community-2',
          'to_community_name': 'St. Anne Community',
          'effective_date': '2026-08-08',
          'transfer_type_code': 'TRANSFER',
        },
      ],
    }, expectedMemberId: 'roy-uuid');

    final transfer = profile.sections.transfers.single;
    expect(transfer.id, 'transfer-1');
    expect(transfer.movementLabel, 'St. Antony Community → St. Anne Community');
    expect(transfer.effectiveDate, DateTime(2026, 8, 8));
  });

  test('current resident mapping uses inclusive boundaries', () {
    final residents = MemberCommunityResidentMapper.fromRows([
      _residentRow('starts-today', from: '2026-08-22'),
      _residentRow('ends-today', to: '2026-08-22'),
      _residentRow('historical', to: '2026-08-21'),
      _residentRow('future', from: '2026-08-23'),
    ], today: DateTime(2026, 8, 22));

    expect(residents.map((item) => item.person.id), [
      'starts-today',
      'ends-today',
    ]);
    expect(residents.every((item) => item.person.phone == null), isTrue);
    expect(residents.every((item) => item.person.email == null), isTrue);
  });

  test('Member community count comes from actual safe resident rows', () async {
    final repository = MemberCalendarRepository(
      const _ProvinceRepository(),
      residentsRepository: const _ResidentsRepository(),
    );
    final community = (await repository.fetchCommunities()).single;

    expect(community.residentCount, 2);
    expect(community.residents, hasLength(2));
    expect(community.residents.map((person) => person.id), [
      'roy-uuid',
      'felix-uuid',
    ]);
  });

  test('MEMBER safe community directory maps only approved collections', () {
    final community = SupabaseMemberSafeProvinceRepository.mapCommunities(
      [
        {
          'community_id': 'sacred-heart-uuid',
          'code': 'COM003',
          'name': 'Sacred Heart Community',
          'community_type': 'apostolic',
          'city': 'Ranchi',
          'active': true,
          'opened_on': '1998-06-12',
          'current_resident_count': 2,
          'ministry_count': 1,
          'current_superior_display_name': 'Fr. Felix Xalxo',
          'current_superior_member_id': 'felix-uuid',
          'current_superior_photo_url': 'https://example.test/felix.webp',
          'current_accountant_display_name': 'Bro. Samuel Nayak',
          'current_accountant_member_id': 'samuel-uuid',
          'current_accountant_photo_url': 'https://example.test/samuel.webp',
          'cover_image_path': 'COM003_sacred_heart_community.webp',
        },
      ],
      residentRows: [_residentRow('roy-uuid'), _residentRow('felix-uuid')],
      ministryRows: const [
        {
          'ministry_id': 'college-uuid',
          'ministry_code': 'MIN003',
          'ministry_name': 'St. Antony College',
          'community_id': 'sacred-heart-uuid',
        },
        {
          'ministry_id': 'parish-uuid',
          'ministry_code': 'MIN004',
          'ministry_name': 'Sacred Heart Parish',
          'community_id': 'sacred-heart-uuid',
        },
      ],
      lifecycleRows: const [
        {
          'community_id': 'sacred-heart-uuid',
          'event_type_code': 'OPENED',
          'effective_date': '1998-01-01',
          'date_precision_code': 'YEAR',
        },
      ],
      publicUrl: (bucket, path) => 'https://storage.test/$bucket/$path',
    ).single;

    expect(community.name, 'Sacred Heart Community');
    expect(community.residentCount, 2);
    expect(community.ministries, ['St. Antony College', 'Sacred Heart Parish']);
    expect(community.ministryRecords, hasLength(2));
    expect(community.ministryRecords.map((ministry) => ministry.name), [
      'St. Antony College',
      'Sacred Heart Parish',
    ]);
    expect(
      community.coverImageUrl,
      'https://storage.test/community-covers/COM003_sacred_heart_community.webp',
    );
    expect(community.superiorPerson?.id, 'felix-uuid');
    expect(
      community.superiorPerson?.photoUrl,
      'https://example.test/felix.webp',
    );
    expect(community.accountantPerson?.id, 'samuel-uuid');
    expect(
      community.accountantPerson?.photoUrl,
      'https://example.test/samuel.webp',
    );
    expect(community.currentMovements, isEmpty);
    expect(community.lifecycleEvents.single.typeCode, 'OPENED');
    expect(community.lifecycleEvents.single.effectiveDate.year, 1998);
    expect(community.lifecycleEvents.single.datePrecisionCode, 'YEAR');
    expect(community.history, isEmpty);
  });

  testWidgets('resident row opens the canonical member UUID', (tester) async {
    final repository = MemberCalendarRepository(
      const _ProvinceRepository(),
      residentsRepository: const _ResidentsRepository(),
    );
    final community = (await repository.fetchCommunities()).single;
    MemberDirectoryEntry? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: CommunityDetailScreen(
          community: community,
          onMember: (member) => selected = member,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Current Residents (2)'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fr. Roy Noronha'));
    expect(selected?.id, 'roy-uuid');
    expect(selected?.mobile, isNull);
  });

  test(
    'Provincial source record is not modified by Member enrichment',
    () async {
      final community =
          (await const _ProvinceRepository().fetchCommunities()).single;
      expect(community.residentCount, 7);
      expect(community.residents, isEmpty);
    },
  );
}

Map<String, dynamic> _residentRow(
  String memberId, {
  String? from,
  String? to,
}) => {
  'community_id': 'sacred-heart-uuid',
  'member_id': memberId,
  'religious_id': 'REL-TEST',
  'display_name': memberId,
  'member_status_code': 'active',
  'from_date': from,
  'to_date': to,
};

class _ResidentsRepository implements MemberCommunityResidentsRepository {
  const _ResidentsRepository();

  @override
  Future<List<MemberCommunityResident>> fetchCurrentResidents() async => const [
    MemberCommunityResident(
      communityId: 'sacred-heart-uuid',
      person: ProvincePerson(
        id: 'roy-uuid',
        name: 'Fr. Roy Noronha',
        role: 'Member',
        ministryAssignment: 'Teacher · St. Thomas Diocesan School',
      ),
    ),
    MemberCommunityResident(
      communityId: 'sacred-heart-uuid',
      person: ProvincePerson(
        id: 'felix-uuid',
        name: 'Fr. Felix Xalxo',
        role: 'Community Superior',
      ),
    ),
  ];
}

class _ProvinceRepository implements ProvinceRepository {
  const _ProvinceRepository();

  @override
  Future<List<CommunityRecord>> fetchCommunities() async => const [
    CommunityRecord(
      id: 'sacred-heart-uuid',
      name: 'Sacred Heart Community',
      residentCount: 7,
      superior: 'Fr. Felix Xalxo',
    ),
  ];

  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async => const [];
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
