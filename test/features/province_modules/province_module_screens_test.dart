import 'package:communio/features/province_modules/data/province_repository.dart';
import 'package:communio/features/province_modules/models/province_models.dart';
import 'package:communio/features/province_modules/screens/province_module_screens.dart';
import 'package:communio/features/province_modules/screens/calendar_screen.dart';
import 'package:communio/core/theme/colors.dart';
import 'package:communio/core/theme/spacing.dart';
import 'package:communio/core/widgets/member_avatar.dart';
import 'package:communio/core/widgets/module_background.dart';
import 'package:communio/features/religious_directory/models/member_directory_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repository = _Repository();

  testWidgets('communities render responsively and open detail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CommunitiesScreen(repository: repository, onMember: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('St. Thomas Community'), findsOneWidget);
    expect(find.text('7 Residents'), findsOneWidget);
    expect(find.byTooltip('Call Francis Thomas'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Francis Thomas'), findsOneWidget);
    expect(find.byTooltip('Email Francis Thomas'), findsOneWidget);
    expect(find.text('View Community'), findsWidgets);
    final communityCard = find
        .ancestor(
          of: find.text('St. Thomas Community'),
          matching: find.byType(InkWell),
        )
        .first;
    final emptyCommunityCard = find
        .ancestor(
          of: find.text(
            'Blessed William Joseph St. Antony International Community',
          ),
          matching: find.byType(InkWell),
        )
        .first;
    expect(
      find.descendant(of: communityCard, matching: find.text('1 Ministry')),
      findsOneWidget,
    );
    expect(
      tester.getSize(emptyCommunityCard).height,
      lessThan(tester.getSize(communityCard).height),
    );
    await tester.tap(find.text('St. Thomas Community'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel('St. Thomas Community cover image unavailable'),
      findsOneWidget,
    );
    expect(find.byType(ModuleBackground), findsOneWidget);
    final mobileCover = find.byType(AspectRatio).first;
    final mobileCoverSize = tester.getSize(mobileCover);
    expect(mobileCoverSize.width / mobileCoverSize.height, closeTo(2.4, .01));
    expect(find.text('Leadership'), findsOneWidget);
    expect(find.text('At a Glance'), findsOneWidget);
    expect(find.text('Opened 1965'), findsOneWidget);
    expect(find.text('Accountant'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Current Residents'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Current Residents'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Ministries'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ministries'), findsOneWidget);
    expect(find.textContaining('900 Students'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('community grid handles long names and missing leadership', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CommunitiesScreen(repository: repository, onMember: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Blessed William Joseph St. Antony International Community'),
      findsOneWidget,
    );
    final communityWithoutLeadership = find
        .ancestor(
          of: find.text(
            'Blessed William Joseph St. Antony International Community',
          ),
          matching: find.byType(InkWell),
        )
        .first;
    expect(
      find.descendant(
        of: communityWithoutLeadership,
        matching: find.text('Superior'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('St. Thomas Community'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('St. Thomas Community cover image unavailable'),
      findsOneWidget,
    );
    final desktopCover = find.byType(AspectRatio).first;
    final desktopCoverSize = tester.getSize(desktopCover);
    expect(desktopCoverSize.width / desktopCoverSize.height, closeTo(3.2, .01));
    expect(find.text('Leadership'), findsOneWidget);
    expect(find.text('At a Glance'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Community Membership History'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Community Membership History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ministries show category, head, counts, filters, and detail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MinistriesScreen(repository: repository, onMember: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('St. Joseph Academy'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    expect(find.text('SCHOOL'), findsOneWidget);
    expect(find.text('HEALTH CENTRE'), findsOneWidget);
    expect(find.text('TRAINING INSTITUTE'), findsOneWidget);
    expect(find.text('INACTIVE'), findsOneWidget);
    expect(find.text('Ranchi, Jharkhand'), findsOneWidget);
    expect(find.text('Principal: Fr. Francis Thomas'), findsOneWidget);
    expect(find.text('Students: 900'), findsOneWidget);
    expect(find.text('Staff: 85'), findsOneWidget);
    expect(find.text('Religious: 3'), findsOneWidget);
    expect(
      find.text('Blessed St. Antony Skills and Technical Training Institute'),
      findsOneWidget,
    );
    expect(find.text('Leadership: No current head assigned'), findsWidgets);
    await tester.tap(find.text('Formation'));
    await tester.pump();
    expect(find.text('St. Joseph Academy'), findsNothing);
    expect(
      find.text('Blessed St. Antony Skills and Technical Training Institute'),
      findsOneWidget,
    );
    await tester.tap(find.text('All'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search ministries'),
      'academy',
    );
    await tester.pump();
    expect(find.text('St. Joseph Academy'), findsOneWidget);
    expect(find.text('St. Anne Health Centre'), findsNothing);
    await tester.tap(find.text('St. Joseph Academy'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('St. Joseph Academy cover image unavailable'),
      findsOneWidget,
    );
    expect(find.byType(ModuleBackground), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    expect(find.text('School'), findsOneWidget);
    expect(find.text('Ministry overview'), findsOneWidget);
    expect(find.text('Operational statistics'), findsOneWidget);
    expect(find.text('Programs & services'), findsOneWidget);
    expect(find.text('Ministry Identity & Mission'), findsNothing);
    expect(find.text('Our Story'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Contact details'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Contact details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ministry profile keeps current workers, history, identity, and story',
    (tester) async {
      MemberDirectoryEntry? openedMember;
      final currentLeader = ProvincePerson(
        id: 'leader',
        name: 'Fr. Dominic Kunnath',
      );
      final currentTeacher = ProvincePerson(
        id: 'teacher',
        name: 'Bro. Joseph Teacher',
      );
      final historicalChaplain = ProvincePerson(
        id: 'chaplain',
        name: 'Fr. Antony Chaplain',
      );
      final ministry = MinistryRecord(
        id: 'parish-1',
        name: 'Sacred Heart Parish',
        type: 'Parish',
        status: 'Active',
        totalReligious: 2,
        assignments: [
          ProvinceAssignment(
            person: currentLeader,
            role: 'Parish Priest',
            fromDate: DateTime(2024, 1, 1),
          ),
          ProvinceAssignment(
            person: currentTeacher,
            role: 'Teacher',
            fromDate: DateTime(2025, 6, 1),
          ),
          ProvinceAssignment(
            person: historicalChaplain,
            role: 'Chaplain',
            fromDate: DateTime(2019, 7, 1),
            toDate: DateTime(2022, 11, 17),
          ),
        ],
        programsServices: 'Parish pastoral care',
        patronSaintName: 'Sacred Heart of Jesus',
        feastMonth: 6,
        feastDay: 12,
        motto: 'To serve with compassion',
        missionStatement: 'Accompany the parish community.',
        visionStatement: 'A living and welcoming parish.',
        apostolicFocus: ['Pastoral care', 'Youth ministry'],
        ministryValues: ['Faith', 'Service'],
        foundingStory: 'Founded to serve the local Catholic community.',
        historySummary: 'The parish expanded its pastoral outreach.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MinistryDetailScreen(
            ministry: ministry,
            onMember: (member) => openedMember = member,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsNothing);
      expect(find.text('Parish'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ministry Identity & Mission'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ministry Identity & Mission'), findsOneWidget);
      expect(find.text('Sacred Heart of Jesus'), findsOneWidget);
      expect(find.text('12 June'), findsOneWidget);
      expect(find.text('To serve with compassion'), findsOneWidget);
      expect(find.text('Accompany the parish community.'), findsOneWidget);
      expect(find.text('A living and welcoming parish.'), findsOneWidget);
      expect(find.text('Pastoral care'), findsOneWidget);
      expect(find.text('Youth ministry'), findsOneWidget);
      expect(find.text('Faith'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Founding Story'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Our Story'), findsOneWidget);
      expect(find.text('Founding Story'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Religious currently assigned (2)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Fr. Dominic Kunnath'), findsWidgets);
      expect(find.text('Bro. Joseph Teacher'), findsOneWidget);
      expect(find.textContaining('Teacher'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Bro. Joseph Teacher'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bro. Joseph Teacher'));
      expect(openedMember?.id, 'teacher');

      await tester.scrollUntilVisible(
        find.text('Ministry Assignment History'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Fr. Antony Chaplain'), findsOneWidget);
      expect(find.textContaining('Chaplain'), findsWidgets);
      expect(find.textContaining('1 Jul 2019'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ministry profile sections keep the required detail order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1800);
    addTearDown(tester.view.reset);
    const ministry = MinistryRecord(
      id: 'ordered-ministry',
      name: 'Ordered Ministry',
      programsServices: 'Pastoral service',
      motto: 'Serve with joy',
      foundingStory: 'A concise founding story.',
      email: 'ordered@example.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MinistryDetailScreen(ministry: ministry, onMember: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    final programsY = tester.getTopLeft(find.text('Programs & services')).dy;
    final identityY = tester
        .getTopLeft(find.text('Ministry Identity & Mission'))
        .dy;
    final storyY = tester.getTopLeft(find.text('Our Story')).dy;
    final contactY = tester.getTopLeft(find.text('Contact details')).dy;

    expect(programsY, lessThan(identityY));
    expect(identityY, lessThan(storyY));
    expect(storyY, lessThan(contactY));
  });

  testWidgets('ministry patron and story remain responsive on mobile widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const patron =
        'Our Lady of Perpetual Help and Saint Joseph the Compassionate';
    const story =
        'This complete institutional story remains visible and wraps naturally '
        'without truncation while retaining comfortable readability.';
    const ministry = MinistryRecord(
      id: 'responsive-ministry',
      name: 'Responsive Ministry',
      patronSaintName: patron,
      foundingStory: story,
    );

    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          home: MinistryDetailScreen(ministry: ministry, onMember: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Patron / Dedication'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text(patron), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text(story),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final storyText = tester.widget<Text>(find.text(story));
      expect(storyText.maxLines, isNull);
      expect(storyText.overflow, isNull);
      expect(storyText.style?.fontSize, 14.5);
      expect(storyText.style?.height, 1.45);
      expect(tester.takeException(), isNull);
    }
  });

  test('ministry listing groups and accents are deterministic', () {
    expect(ministryListingGroup('School'), 'education');
    expect(ministryListingGroup('Parish'), 'pastoral');
    expect(ministryListingGroup('Health Centre'), 'social_health');
    expect(ministryListingGroup('Social Service'), 'social_health');
    expect(ministryListingGroup('Aspirancy & Postulancy'), 'formation');
    expect(ministryListingGroup('Training Institute'), 'formation');
    expect(ministryTypeBadge('Formation House'), 'FORMATION');
    expect(
      ministryListingAccent('School'),
      isNot(ministryListingAccent('Health Centre')),
    );
    expect(
      ministryListingAccent('Parish'),
      isNot(ministryListingAccent('Formation')),
    );
  });

  test('assignment ending today remains current for the full date', () {
    final now = DateTime.now();
    final assignment = ProvinceAssignment(
      person: const ProvincePerson(id: 'member', name: 'Member'),
      fromDate: DateTime(now.year, now.month, now.day - 1),
      toDate: DateTime(now.year, now.month, now.day),
    );
    expect(assignment.current, isTrue);
  });

  test('ministry current assignments use inclusive date-only bounds', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ministry = MinistryRecord(
      id: 'ministry',
      name: 'Ministry',
      assignments: [
        ProvinceAssignment(
          person: const ProvincePerson(id: 'ongoing', name: 'Ongoing'),
          role: 'Parish Priest',
          fromDate: today.subtract(const Duration(days: 30)),
        ),
        ProvinceAssignment(
          person: const ProvincePerson(id: 'future-end', name: 'Future end'),
          role: 'Teacher',
          fromDate: today.subtract(const Duration(days: 30)),
          toDate: today.add(const Duration(days: 30)),
        ),
        ProvinceAssignment(
          person: const ProvincePerson(
            id: 'future-start',
            name: 'Future start',
          ),
          role: 'Director',
          fromDate: today.add(const Duration(days: 1)),
        ),
        ProvinceAssignment(
          person: const ProvincePerson(id: 'historical', name: 'Historical'),
          role: 'Chaplain',
          fromDate: today.subtract(const Duration(days: 60)),
          toDate: today.subtract(const Duration(days: 1)),
        ),
      ],
    );

    expect(
      ministry.currentAssignments.map((assignment) => assignment.person.id),
      ['ongoing', 'future-end'],
    );
  });

  testWidgets('ministry operational cards remain compact on mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MinistriesScreen(repository: repository, onMember: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('St. Joseph Academy'), findsOneWidget);
    expect(find.text('Students: 900'), findsOneWidget);
    expect(find.text('View Ministry'), findsWidgets);
    final cardInkWell = find
        .ancestor(
          of: find.text('St. Joseph Academy'),
          matching: find.byType(InkWell),
        )
        .first;
    expect(tester.getSize(cardInkWell).height, lessThan(380));
    await tester.tap(find.byTooltip('Call Fr. Francis Thomas'));
    await tester.pump();
    expect(find.text('Ministry overview'), findsNothing);
    expect(find.byTooltip('WhatsApp Fr. Francis Thomas'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('formation renders backend stage counts and houses', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final formationRepository = _FormationRepository();
    MemberDirectoryEntry? openedMember;
    await tester.pumpWidget(
      MaterialApp(
        home: FormationScreen(
          repository: formationRepository,
          onMember: (member) => openedMember = member,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total Formation'), findsOneWidget);
    expect(find.text('Temporary\nProfessed'), findsOneWidget);
    expect(find.text('Novices'), findsOneWidget);
    expect(find.text('Candidates'), findsOneWidget);
    expect(find.text('Perpetual\nProfessed'), findsOneWidget);
    expect(find.text('Formation\nStaff'), findsOneWidget);
    expect(find.byIcon(Icons.manage_accounts_outlined), findsOneWidget);
    expect(find.text('Temporary Professed'), findsWidgets);
    const orderedHouses = [
      'Vidhya Deep Theologate',
      'St. Antony Scholasticate',
      'Mary Immaculate Novitiate',
      'St. Antony Vocation House',
    ];
    final scrollOffsets = <double>[];
    for (final house in orderedHouses) {
      await tester.scrollUntilVisible(
        find.text(house),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(house), findsOneWidget);
      scrollOffsets.add(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
      );
    }
    expect(scrollOffsets, orderedEquals([...scrollOffsets]..sort()));
    expect(
      tester
          .widget<Container>(
            find.byKey(
              const Key('formation-house-accent-st-antony-vocation-house'),
            ),
          )
          .color,
      AppColors.warning,
    );
    expect(
      tester
          .widget<Container>(
            find.byKey(
              const Key('formation-house-accent-mary-immaculate-novitiate'),
            ),
          )
          .color,
      AppColors.purple,
    );
    expect(
      tester
          .widget<Container>(
            find.byKey(
              const Key('formation-house-accent-st-antony-scholasticate'),
            ),
          )
          .color,
      AppColors.info,
    );
    expect(
      tester
          .widget<Container>(
            find.byKey(
              const Key('formation-house-accent-vidhya-deep-theologate'),
            ),
          )
          .color,
      AppColors.cyan,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const Key('formation-house-accent-st-antony-scholasticate'),
            ),
          )
          .width,
      4,
    );
    expect(
      tester
          .widget<Padding>(
            find.byKey(
              const Key('formation-house-spacing-st-antony-scholasticate'),
            ),
          )
          .padding,
      const EdgeInsets.only(top: AppSpacing.xs),
    );
    expect(find.text('Candidate Member'), findsOneWidget);
    expect(find.text('Candidate'), findsOneWidget);
    await tester.tap(find.text('Professed Member'));
    expect(openedMember?.id, 'professed');
    expect(
      tester
          .widgetList<MemberAvatar>(find.byType(MemberAvatar))
          .where(
            (avatar) => avatar.photoUrl == 'https://example.org/francis.jpg',
          )
          .single
          .photoUrl,
      'https://example.org/francis.jpg',
    );
    expect(
      formationStaffFromMinistries(await formationRepository.fetchMinistries()),
      hasLength(2),
    );
  });

  test('formation staff excludes formees, ended roles, and duplicates', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const director = ProvincePerson(id: 'director', name: 'Director');
    const master = ProvincePerson(id: 'master', name: 'Master');
    const novice = ProvincePerson(id: 'novice', name: 'Novice');
    const former = ProvincePerson(id: 'former', name: 'Former staff');
    final staff = formationStaffFromMinistries([
      MinistryRecord(
        id: 'aspirancy',
        name: 'Aspirancy & Postulancy Program',
        type: 'Formation',
        assignments: [
          ProvinceAssignment(person: director, role: 'Director'),
          const ProvinceAssignment(person: novice, role: 'Candidate'),
          ProvinceAssignment(
            person: former,
            role: 'Formation Director',
            fromDate: today.subtract(const Duration(days: 90)),
            toDate: today.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      const MinistryRecord(
        id: 'novitiate',
        name: 'Novitiate Program',
        type: 'Formation',
        assignments: [
          ProvinceAssignment(person: director, role: 'Formation Director'),
          ProvinceAssignment(person: master, role: 'Novice Master'),
        ],
      ),
      const MinistryRecord(
        id: 'school',
        name: 'Ordinary School',
        type: 'School',
        assignments: [ProvinceAssignment(person: former, role: 'Director')],
      ),
    ]);

    expect(staff.map((assignment) => assignment.person.id), [
      'director',
      'master',
    ]);
  });

  testWidgets('formation house cards remain responsive on mobile widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final formationRepository = _FormationRepository();

    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          home: FormationScreen(
            repository: formationRepository,
            onMember: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('formation-summary')), findsOneWidget);
      expect(
        find.byKey(const Key('formation-house-card-vidhya-deep-theologate')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('formation house display priority follows formation progression', () {
    expect(formationHouseDisplayPriority('Vidhya Deep Theologate'), 0);
    expect(formationHouseDisplayPriority('St. Antony Scholasticate'), 1);
    expect(formationHouseDisplayPriority('Mary Immaculate Novitiate'), 2);
    expect(formationHouseDisplayPriority('St. Antony Vocation House'), 3);
  });

  testWidgets('governance renders every current appointment', (tester) async {
    final governanceRepository = _GovernanceRepository();
    MemberDirectoryEntry? openedMember;
    await tester.pumpWidget(
      MaterialApp(
        home: GovernanceScreen(
          repository: governanceRepository,
          onMember: (member) => openedMember = member,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Current leadership and institutional continuity'),
      findsOneWidget,
    );
    expect(find.text('Current Provincial Leadership'), findsOneWidget);
    expect(find.text('Other Provincial Offices'), findsOneWidget);
    expect(find.text('Past Provincials'), findsOneWidget);
    expect(find.text('Provincial'), findsWidgets);
    expect(find.text('Provincial Secretary'), findsOneWidget);
    expect(find.text('Formation Director'), findsOneWidget);
    expect(find.text('Vocation Promoter'), findsOneWidget);
    expect(find.text('Leadership & Eligibility'), findsNothing);
    expect(find.text('Eligible'), findsNothing);
    expect(find.text('Former Provincial Recent'), findsOneWidget);
    expect(find.text('Former Provincial Older'), findsOneWidget);
    expect(find.text('Current Provincial History'), findsNothing);
    expect(find.text('Former Assistant'), findsNothing);
    expect(find.byTooltip('Call Francis Thomas'), findsWidgets);
    expect(find.byTooltip('WhatsApp Francis Thomas'), findsWidgets);
    expect(find.byTooltip('Email Francis Thomas'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Former Provincial Recent'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Former Provincial Recent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Former Provincial Recent'));
    expect(openedMember?.id, 'former-recent');
  });

  test('governance core and past offices use deterministic ordering', () {
    const person = ProvincePerson(id: 'member', name: 'Member');
    const councillorOne = OfficeHolder(
      person: person,
      office: 'Provincial Councillor',
      officeCode: 'provincial_councillor',
    );
    const councillorTwo = OfficeHolder(
      person: person,
      office: 'Provincial Councillor',
      officeCode: 'provincial_councillor',
    );
    final ordered = orderedCoreLeadership(const [
      OfficeHolder(person: person, office: 'Provincial Bursar'),
      councillorOne,
      OfficeHolder(person: person, office: 'Provincial'),
      OfficeHolder(person: person, office: 'Provincial Secretary'),
      councillorTwo,
      OfficeHolder(person: person, office: 'Vice Provincial'),
      OfficeHolder(person: person, office: 'Assistant Provincial'),
      OfficeHolder(person: person, office: 'Formation Director'),
    ]);
    expect(ordered.map((office) => office.office), [
      'Provincial',
      'Assistant Provincial',
      'Vice Provincial',
      'Provincial Councillor',
      'Provincial Councillor',
      'Provincial Secretary',
      'Provincial Bursar',
    ]);
    expect(ordered[3], same(councillorOne));
    expect(ordered[4], same(councillorTwo));

    final past = pastProvincialsNewestFirst([
      OfficeHolder(
        person: person,
        office: 'Provincial',
        fromDate: DateTime(2012),
        toDate: DateTime(2018),
      ),
      const OfficeHolder(person: person, office: 'Provincial'),
      OfficeHolder(
        person: person,
        office: 'Provincial',
        fromDate: DateTime(2018),
        toDate: DateTime(2024),
      ),
      OfficeHolder(
        person: person,
        office: 'Assistant Provincial',
        fromDate: DateTime(2018),
        toDate: DateTime(2024),
      ),
    ]);
    expect(past.map((office) => office.toDate?.year), [2024, 2018]);
  });

  testWidgets('governance leadership remains readable on mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          home: GovernanceScreen(
            repository: _GovernanceRepository(),
            onMember: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final secretary = find.text('Provincial Secretary');
      expect(secretary, findsOneWidget);
      expect(tester.getSize(secretary).width, greaterThan(140));
      expect(find.byTooltip('Call Francis Thomas'), findsWidgets);
      expect(find.byTooltip('WhatsApp Francis Thomas'), findsWidgets);
      expect(find.byTooltip('Email Francis Thomas'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('calendar defaults to a mobile leadership week', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(repository: repository, onMember: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(
      find.text('Birthdays currently available from Supabase.'),
      findsNothing,
    );
    expect(find.text('Upcoming birthdays'), findsNothing);
    expect(find.textContaining('DEMO'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Repository implements ProvinceRepository {
  const _Repository();
  static const person = ProvincePerson(
    id: 'member-1',
    name: 'Francis Thomas',
    role: 'Community Superior',
    phone: '+91 98765 43210',
    whatsApp: '+91 98765 43210',
    email: 'francis@example.org',
    photoUrl: 'https://example.org/francis.jpg',
  );
  static const accountant = ProvincePerson(
    id: 'member-2',
    name: 'Patrick Barla',
    role: 'Community Accountant',
    email: 'patrick@example.org',
  );
  static const ministryHead = ProvincePerson(
    id: 'member-3',
    name: 'Fr. Francis Thomas',
    phone: '+91 98765 40000',
    email: 'principal@example.org',
    photoUrl: 'https://example.org/principal.jpg',
  );
  @override
  Future<List<CommunityRecord>> fetchCommunities() async => const [
    CommunityRecord(
      id: 'community-1',
      name: 'St. Thomas Community',
      residentCount: 7,
      superior: 'Francis Thomas',
      accountant: 'Patrick Barla',
      superiorPerson: person,
      accountantPerson: accountant,
      establishedYear: 1965,
      phone: '0651 234 5678',
      location: 'Ranchi, Jharkhand',
      residents: [person, accountant],
      ministries: ['St. Joseph Academy'],
      ministryRecords: [
        MinistryRecord(
          id: 'ministry-1',
          name: 'St. Joseph Academy',
          type: 'School',
          community: 'St. Thomas Community',
          status: 'Active',
          location: 'Ranchi, Jharkhand',
          totalReligious: 3,
          totalStaff: 85,
          totalStudents: 900,
          assignments: [
            ProvinceAssignment(person: ministryHead, role: 'Principal'),
          ],
        ),
      ],
    ),
    CommunityRecord(
      id: 'community-2',
      name: 'Blessed William Joseph St. Antony International Community',
      residentCount: 0,
    ),
    CommunityRecord(
      id: 'community-3',
      name: 'St. Anne Community',
      residentCount: 2,
      residents: [accountant],
      ministries: ['St. Anne Health Centre'],
      ministryRecords: [
        MinistryRecord(
          id: 'ministry-2',
          name: 'St. Anne Health Centre',
          type: 'Health Centre',
          status: 'Active',
          totalBeneficiaries: 250,
          totalStaff: 12,
          totalReligious: 2,
        ),
      ],
    ),
  ];
  @override
  Future<List<FormationMember>> fetchFormation() async => const [
    FormationMember(
      person: person,
      stage: 'Temporary Professed',
      house: 'St. Antony Scholasticate',
    ),
  ];
  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() async => const [
    OfficeHolder(person: person, office: 'Provincial'),
    OfficeHolder(person: person, office: 'Provincial Secretary'),
  ];
  @override
  Future<List<MinistryRecord>> fetchMinistries() async => const [
    MinistryRecord(
      id: 'ministry-1',
      name: 'St. Joseph Academy',
      type: 'School',
      community: 'St. Thomas Community',
      status: 'Active',
      location: 'Ranchi, Jharkhand',
      headName: 'Fr. Francis Thomas',
      headPerson: ministryHead,
      headRole: 'Principal',
      totalReligious: 3,
      totalStaff: 85,
      totalStudents: 900,
      affiliationAuthority: 'CBSE',
      programsServices: 'Primary and secondary education',
      phone: '+91 651 555 0100',
    ),
    MinistryRecord(
      id: 'ministry-2',
      name: 'St. Anne Health Centre',
      type: 'Health Centre',
      status: 'Inactive',
      totalBeneficiaries: 250,
      totalStaff: 12,
      totalReligious: 2,
    ),
    MinistryRecord(
      id: 'ministry-3',
      name: 'Blessed St. Antony Skills and Technical Training Institute',
      type: 'Training Institute',
      status: 'Active',
      location: 'Bangalore, Karnataka',
      headName: 'Blessed St. Antony Skills and Technical Training Institute',
      headRole: 'Director',
      totalStudents: 120,
      totalStaff: 9,
      totalReligious: 1,
      affiliationAuthority: 'NCVET',
    ),
  ];
  @override
  Future<List<EligibilityRole>> fetchEligibilityRoles() async => const [
    EligibilityRole(code: 'provincial', name: 'Provincial', office: true),
  ];
  @override
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  }) async => const [
    EligibilityRecord(
      person: person,
      role: 'Provincial',
      status: 'ELIGIBLE',
      reason: 'Backend evaluated',
    ),
  ];
  @override
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance() async =>
      const [];
  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async => const [];
}

class _FormationRepository extends _Repository {
  @override
  Future<List<FormationMember>> fetchFormation() async => const [
    FormationMember(
      person: _Repository.person,
      stage: 'Temporary Professed',
      house: 'St. Antony Scholasticate',
    ),
    FormationMember(
      person: ProvincePerson(id: 'novice', name: 'Novice Member'),
      stage: 'Novice',
      house: 'Mary Immaculate Novitiate',
    ),
    FormationMember(
      person: ProvincePerson(id: 'candidate', name: 'Candidate Member'),
      stage: 'Candidate',
      house: 'St. Antony Vocation House',
    ),
    FormationMember(
      person: ProvincePerson(id: 'professed', name: 'Professed Member'),
      stage: 'Perpetual Professed',
      house: 'Vidhya Deep Theologate',
    ),
  ];

  @override
  Future<List<MinistryRecord>> fetchMinistries() async => const [
    MinistryRecord(
      id: 'formation-1',
      name: 'Novitiate Program',
      type: 'Formation',
      assignments: [
        ProvinceAssignment(
          person: ProvincePerson(id: 'staff-1', name: 'Novice Master'),
          role: 'Novice Master',
        ),
        ProvinceAssignment(
          person: ProvincePerson(id: 'candidate', name: 'Candidate Member'),
          role: 'Candidate',
        ),
      ],
    ),
    MinistryRecord(
      id: 'formation-2',
      name: 'Scholasticate Program',
      type: 'Formation',
      assignments: [
        ProvinceAssignment(
          person: ProvincePerson(id: 'staff-1', name: 'Novice Master'),
          role: 'Formation Director',
        ),
        ProvinceAssignment(
          person: ProvincePerson(id: 'staff-2', name: 'Scholastic Master'),
          role: 'Scholastic Master',
        ),
      ],
    ),
  ];
}

class _GovernanceRepository extends _Repository
    implements GovernanceHistoryRepository {
  static const currentPerson = _Repository.person;

  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() async => const [
    OfficeHolder(person: currentPerson, office: 'Provincial Secretary'),
    OfficeHolder(person: currentPerson, office: 'Formation Director'),
    OfficeHolder(person: currentPerson, office: 'Provincial Councillor'),
    OfficeHolder(person: currentPerson, office: 'Provincial Bursar'),
    OfficeHolder(person: currentPerson, office: 'Provincial'),
    OfficeHolder(person: currentPerson, office: 'Assistant Provincial'),
    OfficeHolder(person: currentPerson, office: 'Provincial Councillor'),
    OfficeHolder(person: currentPerson, office: 'Vice Provincial'),
    OfficeHolder(person: currentPerson, office: 'Vocation Promoter'),
  ];

  @override
  Future<List<OfficeHolder>> fetchPastProvincials() async => [
    OfficeHolder(
      person: const ProvincePerson(
        id: 'former-older',
        name: 'Former Provincial Older',
      ),
      office: 'Provincial',
      officeCode: 'provincial',
      fromDate: DateTime(2012, 7, 1),
      toDate: DateTime(2018, 6, 30),
    ),
    const OfficeHolder(
      person: ProvincePerson(
        id: 'current-history',
        name: 'Current Provincial History',
      ),
      office: 'Provincial',
      officeCode: 'provincial',
    ),
    OfficeHolder(
      person: const ProvincePerson(
        id: 'former-recent',
        name: 'Former Provincial Recent',
      ),
      office: 'Provincial',
      officeCode: 'provincial',
      fromDate: DateTime(2018, 7, 1),
      toDate: DateTime(2024, 6, 30),
    ),
    OfficeHolder(
      person: const ProvincePerson(
        id: 'former-assistant',
        name: 'Former Assistant',
      ),
      office: 'Assistant Provincial',
      officeCode: 'assistant_provincial',
      fromDate: DateTime(2018, 7, 1),
      toDate: DateTime(2024, 6, 30),
    ),
  ];
}
