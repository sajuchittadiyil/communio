import 'package:communio/features/demo_persona/data/demo_persona_presenter.dart';
import 'package:communio/features/demo_persona/models/demo_persona.dart';
import 'package:communio/features/religious_directory/data/supabase_member_directory_repository.dart';
import 'package:communio/features/province_modules/data/supabase_province_repository.dart';
import 'package:communio/features/province_modules/models/province_models.dart';
import 'package:communio/features/province_modules/data/province_repository.dart';
import 'package:communio/features/province_modules/screens/province_module_screens.dart';
import 'package:communio/features/religious_profile/data/religious_profile_repository.dart';
import 'package:communio/features/religious_profile/models/religious_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const memberId = '3cc8dc56-18b2-4ed1-918a-4c6dc0af80f2';
  const alias = DemoPersonaMemberAlias(
    memberId: memberId,
    displayName: 'Teresa Mathew',
    title: 'Sr.',
  );

  tearDown(() {
    DemoPersonaPresenter.configure(resolvedPersona: DemoPersona.standard);
  });

  test('standard persona preserves canonical identity and photo', () {
    DemoPersonaPresenter.configure(resolvedPersona: DemoPersona.standard);

    expect(
      DemoPersonaPresenter.memberName(memberId, 'Thomas Mathew'),
      'Thomas Mathew',
    );
    expect(DemoPersonaPresenter.memberTitle(memberId, 'Fr.'), 'Fr.');
    expect(
      DemoPersonaPresenter.memberPhoto(memberId, 'standard-male.webp'),
      'standard-male.webp',
    );
  });

  test('same UUID resolves to Sisters alias without changing identifiers', () {
    DemoPersonaPresenter.configure(
      resolvedPersona: DemoPersona.sisters,
      resolvedIdentity: const DemoPersonaIdentity(
        congregationName: 'Sisters of Our Lady of Communion',
        abbreviation: 'SOLC',
        provinceName: 'Indian Province',
        motto: 'In Communion for Mission',
      ),
      resolvedAliases: const {memberId: alias},
      canonicalNames: const {memberId: 'Thomas Mathew'},
    );

    expect(DemoPersonaPresenter.member(memberId)?.memberId, memberId);
    expect(
      DemoPersonaPresenter.memberName(memberId, 'Thomas Mathew'),
      'Teresa Mathew',
    );
    expect(DemoPersonaPresenter.memberTitle(memberId, 'Fr.'), 'Sr.');
    expect(DemoPersonaPresenter.identity?.abbreviation, 'SOLC');
  });

  test('missing Sisters photo never falls back to canonical male photo', () {
    DemoPersonaPresenter.configure(
      resolvedPersona: DemoPersona.sisters,
      resolvedAliases: const {memberId: alias},
    );

    expect(
      DemoPersonaPresenter.memberPhoto(memberId, 'standard-male.webp'),
      isNull,
    );
  });

  test(
    'Ask Communio prose and governance roles are presentation translated',
    () {
      DemoPersonaPresenter.configure(
        resolvedPersona: DemoPersona.sisters,
        resolvedAliases: const {memberId: alias},
        canonicalNames: const {memberId: 'Thomas Mathew'},
      );

      expect(
        DemoPersonaPresenter.translateText(
          'The current Provincial is Fr. Thomas Mathew.',
        ),
        'The current Provincial Superior is Sr. Teresa Mathew.',
      );
      expect(
        DemoPersonaPresenter.role('Formation Director'),
        'Formation Directress',
      );
    },
  );

  test('Sisters directory preserves canonical Provincial count and IDs', () {
    final repository = SupabaseMemberDirectoryRepository(
      SupabaseClient('https://example.supabase.co', 'test-key'),
    );
    final results = <List<Map<String, dynamic>>>[
      [
        {
          'member_id': memberId,
          'religious_id': 'REL-0001',
          'display_name': 'Thomas Mathew',
          'ecclesiastical_title_code': 'FR',
          'active': true,
        },
        {
          'member_id': 'member-2',
          'religious_id': 'REL-0002',
          'display_name': 'John Kuriakose',
          'ecclesiastical_title_code': 'BRO',
          'active': true,
        },
      ],
      <Map<String, dynamic>>[],
      <Map<String, dynamic>>[],
      <Map<String, dynamic>>[],
      <Map<String, dynamic>>[],
      <Map<String, dynamic>>[],
      <Map<String, dynamic>>[],
    ];

    DemoPersonaPresenter.configure(resolvedPersona: DemoPersona.standard);
    final standard = repository.mapDirectoryResults(results);
    DemoPersonaPresenter.configure(
      resolvedPersona: DemoPersona.sisters,
      resolvedAliases: const {
        memberId: alias,
        'member-2': DemoPersonaMemberAlias(
          memberId: 'member-2',
          displayName: 'Maria Kuriakose',
          title: 'Sr.',
        ),
      },
      canonicalNames: const {
        memberId: 'Thomas Mathew',
        'member-2': 'John Kuriakose',
      },
    );
    final sisters = repository.mapDirectoryResults(results);

    expect(sisters, hasLength(standard.length));
    expect(sisters.map((entry) => entry.id), standard.map((entry) => entry.id));
    expect(
      sisters.map((entry) => entry.religiousId),
      standard.map((entry) => entry.religiousId),
    );
    expect(sisters.map((entry) => entry.title), everyElement('Sr.'));
    expect(sisters.map((entry) => entry.displayName), [
      'Teresa Mathew',
      'Maria Kuriakose',
    ]);
  });

  test(
    'structured community and ministry leaders have no male title leakage',
    () {
      DemoPersonaPresenter.configure(
        resolvedPersona: DemoPersona.sisters,
        resolvedAliases: const {memberId: alias},
        canonicalNames: const {memberId: 'Thomas Mathew'},
      );

      final superior = DemoPersonaPresenter.presentPerson(
        memberId: memberId,
        canonicalDisplayName: 'Thomas Mathew',
        canonicalTitle: 'Fr.',
        canonicalPhotoUrl: 'canonical-male.jpg',
      );
      final ministryHead = DemoPersonaPresenter.presentPerson(
        memberId: memberId,
        canonicalDisplayName: 'Thomas Mathew',
        canonicalTitle: 'Bro.',
      );

      expect('${superior.title} ${superior.displayName}', 'Sr. Teresa Mathew');
      expect(
        '${ministryHead.title} ${ministryHead.displayName}',
        'Sr. Teresa Mathew',
      );
      expect(superior.memberId, memberId);
      expect(superior.photoUrl, isNull);
      expect('${superior.title} ${ministryHead.title}', isNot(contains('Fr.')));
      expect(
        '${superior.title} ${ministryHead.title}',
        isNot(contains('Bro.')),
      );
      expect(
        DemoPersonaPresenter.role('Formation Director'),
        'Formation Directress',
      );
    },
  );

  test('formation aliases are varied while canonical IDs remain stable', () {
    const formationAliases = {
      'formation-1': DemoPersonaMemberAlias(
        memberId: 'formation-1',
        displayName: 'Agnes Minz',
        title: 'Sr.',
      ),
      'formation-2': DemoPersonaMemberAlias(
        memberId: 'formation-2',
        displayName: 'Clara Ekka',
        title: 'Sr.',
      ),
      'formation-3': DemoPersonaMemberAlias(
        memberId: 'formation-3',
        displayName: 'Sophia Tirkey',
        title: 'Sr.',
      ),
    };
    DemoPersonaPresenter.configure(
      resolvedPersona: DemoPersona.sisters,
      resolvedAliases: formationAliases,
    );

    expect(DemoPersonaPresenter.aliases.keys, formationAliases.keys);
    expect(
      formationAliases.values.map((value) => value.displayName).toSet(),
      hasLength(3),
    );
    expect(
      formationAliases.values.map((value) => value.displayName),
      everyElement(isNot(startsWith('Maria '))),
    );
  });

  test('missing structured alias fails closed to a neutral Sister name', () {
    DemoPersonaPresenter.configure(resolvedPersona: DemoPersona.sisters);

    expect(
      DemoPersonaPresenter.memberName('canonical-member-id', 'Fr. Unknown Man'),
      'Sister',
    );
    expect(
      DemoPersonaPresenter.memberTitle('canonical-member-id', 'Bro.'),
      'Sr.',
    );
  });

  test('General Administration aliases are keyed by stable leader ID', () {
    const leaderId = '30000000-0000-4000-8000-000000000003';
    DemoPersonaPresenter.configure(
      resolvedPersona: DemoPersona.sisters,
      resolvedLeaderAliases: const {
        leaderId: DemoPersonaLeaderAlias(
          leaderId: leaderId,
          displayName: 'Maria Okafor',
        ),
      },
    );

    final leader = DemoPersonaPresenter.leader(leaderId)!;
    expect(leader.displayName, 'Maria Okafor');
    expect(
      '${leader.title} ${leader.displayName}, ${leader.postNominal}',
      'Sr. Maria Okafor, SOLC',
    );
    expect(leader.displayName, isNot(contains('Daniel Okoro')));
  });

  test('ministry leadership selects presented leader by canonical UUID', () {
    const headId = 'canonical-head-uuid';
    const presentedHead = ProvincePerson(id: headId, name: 'Sr. Teresa Mathew');
    final ministry = SupabaseProvinceRepository.mapOperationalMinistry(
      {'ministry_id': 'ministry-1', 'ministry_name': 'College'},
      [
        {
          'ministry_id': 'ministry-1',
          'member_id': headId,
          'responsibility_code': 'principal',
          'to_date': null,
        },
      ],
      const {headId: presentedHead},
      const {},
      publicUrl: (_, _) => null,
    );

    expect(ministry.headPerson?.id, headId);
    expect(ministry.headName, 'Sr. Teresa Mathew');
  });

  test('community leadership retains presented member canonical UUID', () {
    const leaderId = 'canonical-community-superior-uuid';
    const leader = ProvincePerson(id: leaderId, name: 'Sr. Alberta Kindo');
    final selected = SupabaseProvinceRepository.selectCurrentLeader(
      const [ProvinceAssignment(person: leader, role: 'Community Superior')],
      const ['Community Superior'],
    );

    expect(selected?.id, leaderId);
    expect(selected?.name, 'Sr. Alberta Kindo');
  });

  testWidgets('Formation Sister opens canonical profile by UUID', (
    tester,
  ) async {
    const canonicalId = 'canonical-formation-member-uuid';
    final profileRepository = _RecordingProfileRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: FormationScreen(
          repository: const _PersonaFormationRepository(),
          onMember: (member) => profileRepository.fetchProfile(member.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sr. Mercy Lakra'));
    await tester.pump();

    expect(profileRepository.requestedMemberId, canonicalId);
    expect(profileRepository.loadedProfile?.memberId, canonicalId);
    expect(profileRepository.loadedProfile?.displayName, 'Mercy Lakra');
  });
}

class _PersonaFormationRepository implements ProvinceRepository {
  const _PersonaFormationRepository();

  @override
  Future<List<FormationMember>> fetchFormation() async => const [
    FormationMember(
      person: ProvincePerson(
        id: 'canonical-formation-member-uuid',
        name: 'Sr. Mercy Lakra',
      ),
      stage: 'Novice',
      house: 'Mary Immaculate Novitiate',
    ),
  ];

  @override
  Future<List<MinistryRecord>> fetchMinistries() async => const [];
  @override
  Future<List<CommunityRecord>> fetchCommunities() async => const [];
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
  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async => const [];
}

class _RecordingProfileRepository implements ReligiousProfileRepository {
  String? requestedMemberId;
  ReligiousProfile? loadedProfile;

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    requestedMemberId = memberId;
    loadedProfile = ReligiousProfile(
      memberId: memberId,
      religiousId: 'REL-0042',
      displayName: 'Mercy Lakra',
      title: 'Sr.',
      memberStatus: 'Formation',
      sections: const ReligiousProfileSections(),
    );
    return loadedProfile!;
  }
}
