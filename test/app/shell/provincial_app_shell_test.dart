import 'package:communio/app/shell/provincial_app_shell.dart';
import 'package:communio/app/shell/models/app_navigation.dart';
import 'package:communio/app/shell/widgets/provincial_mobile_navigation.dart';
import 'package:communio/app/shell/widgets/provincial_navigation_rail.dart';
import 'package:communio/app/shell/widgets/provincial_sidebar.dart';
import 'package:communio/app/shell/widgets/shell_destination_view.dart';
import 'package:communio/features/authentication/models/auth_session.dart';
import 'package:communio/features/authentication/models/auth_user.dart';
import 'package:communio/features/authentication/services/authentication_service.dart';
import 'package:communio/features/authentication/services/session_store.dart';
import 'package:communio/features/authentication/state/authentication_controller.dart';
import 'package:communio/features/authentication/state/authentication_scope.dart';
import 'package:communio/features/ask_communio/data/ask_communio_service.dart';
import 'package:communio/features/ask_communio/models/ask_communio_models.dart';
import 'package:communio/features/dashboard/data/dashboard_repository.dart';
import 'package:communio/features/dashboard/models/dashboard_models.dart';
import 'package:communio/features/organization_identity/data/organization_identity_repository.dart';
import 'package:communio/features/organization_identity/models/organization_identity_models.dart';
import 'package:communio/features/province_modules/data/province_repository.dart';
import 'package:communio/features/province_modules/models/province_models.dart';
import 'package:communio/features/religious_directory/data/member_directory_repository.dart';
import 'package:communio/features/religious_directory/models/member_directory_entry.dart';
import 'package:communio/features/religious_profile/data/religious_profile_repository.dart';
import 'package:communio/features/religious_profile/models/religious_profile.dart';
import 'package:communio/core/widgets/member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop uses the permanent Provincial sidebar', (tester) async {
    await _setSurface(tester, const Size(1600, 900));
    final controller = await _pumpShell(tester);

    expect(find.byType(ProvincialSidebar), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Finance'), findsNothing);
    expect(find.text('Province Pulse'), findsOneWidget);
    expect(
      find.text('What needs your attention across the Province today.'),
      findsNothing,
    );
    expect(find.text('TODAY AT A GLANCE'), findsOneWidget);
    expect(find.text('PROVINCE ATTENTION'), findsOneWidget);

    await tester.tap(find.text('Religious').first);
    await tester.pumpAndSettle();
    expect(find.text('Religious'), findsWidgets);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('tablet uses a scroll-safe compact rail', (tester) async {
    await _setSurface(tester, const Size(1024, 768));
    final controller = await _pumpShell(tester);

    expect(find.byType(ProvincialNavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('mobile uses five destinations and More navigation', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    final controller = await _pumpShell(tester);

    expect(find.byType(ProvincialMobileNavigation), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(tester.getSize(find.byType(AppBar)).height, 38);
    expect(tester.getSize(find.byType(NavigationBar)).height, 64);
    expect(find.text('Ask Communio'), findsOneWidget);
    expect(find.text('Missionaries of St. Antony'), findsOneWidget);
    expect(find.text('Indian Province'), findsOneWidget);
    expect(find.text('VERSE FOR TODAY'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('province-pulse-identity-card')))
          .height,
      lessThan(320),
    );
    final identityActionY = [
      'Congregation',
      'Leadership',
      'Province',
    ].map((label) => tester.getCenter(find.text(label)).dy).toSet();
    expect(identityActionY.length, 1);
    expect(
      tester.getSize(find.byKey(const Key('ask-communio-entry'))).height,
      lessThan(70),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('ask-communio-entry')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('ask-communio-entry')));
    await tester.pumpAndSettle();
    expect(
      find.text('Preserve the Past. Understand the Present.'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Ministries'), findsWidgets);

    await tester.tap(find.text('Ministries').last);
    await tester.pumpAndSettle();
    expect(find.text('Ministries'), findsWidgets);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('Province Pulse identity actions use existing navigation', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    final controller = await _pumpShell(tester);

    await tester.tap(find.text('Congregation'));
    await tester.pumpAndSettle();
    expect(find.text('Congregation Profile'), findsWidgets);

    controller.dispose();
  });

  testWidgets('Province Pulse Leadership action opens existing page', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    final controller = await _pumpShell(tester);

    await tester.tap(find.text('Leadership'));
    await tester.pumpAndSettle();
    final destination = tester.widget<ShellDestinationView>(
      find.byType(ShellDestinationView),
    );
    expect(destination.item.destination, AppDestination.congregationLeadership);

    controller.dispose();
  });

  testWidgets('Province Pulse Province action opens existing page', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    final controller = await _pumpShell(tester);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Province'));
    await tester.pumpAndSettle();
    expect(find.text('Province Profile'), findsWidgets);

    controller.dispose();
  });

  testWidgets('mobile shell remains usable at accessibility text scales', (
    tester,
  ) async {
    for (final scale in const [1.0, 1.3, 1.5]) {
      await _setSurface(tester, const Size(390, 844));
      final controller = await _pumpShell(tester, textScaleFactor: scale);

      expect(find.text('Province Pulse'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Formation'), findsWidgets);
      expect(tester.takeException(), isNull);
      controller.dispose();
    }
  });

  testWidgets('dashboard renders Province Pulse sections at 1440x900', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1440, 900));
    final controller = await _pumpShell(tester);

    expect(find.text('Province Pulse'), findsOneWidget);
    expect(find.textContaining('Provincial!'), findsOneWidget);
    expect(find.text('PROVINCE ATTENTION'), findsOneWidget);
    expect(find.text("TODAY'S SCHEDULE"), findsNothing);
    expect(find.text('QUICK OVERVIEW'), findsOneWidget);
    expect(find.text('RECENT UPDATES'), findsOneWidget);
    expect(find.text('CELEBRATIONS'), findsOneWidget);
    expect(find.text('MEMBER MOVEMENTS'), findsOneWidget);
    expect(find.text('UPCOMING EVENTS'), findsOneWidget);
    expect(find.text('Hospital Admission'), findsOneWidget);
    expect(find.byTooltip('Call Pradeep Raj'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Pradeep Raj'), findsOneWidget);
    expect(find.textContaining('CURRENT'), findsOneWidget);
    expect(find.text('DEMO'), findsNothing);
    expect(find.text('113'), findsOneWidget);
    expect(find.text('Province Health'), findsNothing);
    final dashboardText = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    final orderedSections = [
      'TODAY AT A GLANCE',
      'CELEBRATIONS',
      'MEMBER MOVEMENTS',
      'PROVINCE ATTENTION',
      'UPCOMING EVENTS',
      'QUICK OVERVIEW',
      'RECENT UPDATES',
    ].map(dashboardText.indexOf).toList();
    expect(orderedSections, orderedEquals([...orderedSections]..sort()));
    final dashboardAvatars = tester.widgetList<MemberAvatar>(
      find.byType(MemberAvatar),
    );
    expect(
      dashboardAvatars.any(
        (avatar) => avatar.photoUrl == 'https://example.org/augustine.jpg',
      ),
      isTrue,
    );
    expect(
      dashboardAvatars.any(
        (avatar) => avatar.photoUrl == 'https://example.org/pradeep.jpg',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('dashboard adapts at mobile and tablet widths', (tester) async {
    for (final size in const [Size(390, 844), Size(900, 1000)]) {
      await _setSurface(tester, size);
      final controller = await _pumpShell(tester);
      expect(find.text('PROVINCE ATTENTION'), findsOneWidget);
      expect(find.text('TODAY AT A GLANCE'), findsOneWidget);
      expect(find.text('QUICK OVERVIEW'), findsOneWidget);
      expect(find.text('CELEBRATIONS'), findsOneWidget);
      expect(find.text('MEMBER MOVEMENTS'), findsOneWidget);
      expect(find.text('UPCOMING EVENTS'), findsOneWidget);
      if (size.width == 390) {
        final overviewValues = [
          '113',
          '16',
          '36',
          '34',
          '11',
          '6',
          '15',
          '10',
        ].map((value) => tester.getCenter(find.text(value))).toList();
        expect(
          overviewValues.take(4).map((point) => point.dy).toSet().length,
          1,
        );
        expect(
          overviewValues.skip(4).map((point) => point.dy).toSet().length,
          1,
        );
        expect(overviewValues[4].dy, greaterThan(overviewValues[0].dy));
      }
      expect(tester.takeException(), isNull);
      controller.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('dashboard attention member opens Religious Profile', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1200, 900));
    final controller = await _pumpShell(
      tester,
      profileRepository: const _ProfileRepository(
        ReligiousProfile(
          memberId: 'member-1',
          displayName: 'Augustine Palackal',
          title: 'Fr.',
          memberStatus: 'Active',
          sections: ReligiousProfileSections(),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Hospital Admission'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hospital Admission'));
    await tester.pumpAndSettle();
    expect(find.text('Religious Profile'), findsOneWidget);
    expect(find.text('Fr. Augustine Palackal'), findsOneWidget);
    controller.dispose();
  });

  testWidgets(
    'mobile dashboard scrolls through appointments above navigation',
    (tester) async {
      await _setSurface(tester, const Size(390, 844));
      final controller = await _pumpShell(tester);

      await tester.scrollUntilVisible(
        find.text('18 Aug 2026'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('18 Aug 2026'), findsOneWidget);
      expect(find.byType(ProvincialMobileNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );

  testWidgets('directory member tap opens the matching profile in the shell', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1200, 900));
    const member = MemberDirectoryEntry(
      id: 'member-uuid-42',
      religiousId: 'REL-0042',
      displayName: 'Justin Mukkath',
      title: 'Bro.',
      memberStatus: 'Higher Studies',
      community: 'St. Thomas Community',
      communityRole: 'Member',
    );
    final controller = await _pumpShell(
      tester,
      directoryRepository: const _DirectoryRepository([member]),
      profileRepository: const _ProfileRepository(
        ReligiousProfile(
          memberId: 'member-uuid-42',
          displayName: 'Justin Mukkath',
          title: 'Bro.',
          memberStatus: 'Higher Studies',
          community: 'St. Thomas Community',
          communityRole: 'Member',
          sections: ReligiousProfileSections(),
        ),
      ),
    );

    await tester.tap(find.text('Religious').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('member-row-member-uuid-42')));
    await tester.pumpAndSettle();

    expect(find.text('Religious Profile'), findsOneWidget);
    expect(find.text('Bro. Justin Mukkath'), findsOneWidget);
    expect(find.text('REL-0042'), findsNothing);
    expect(find.byType(ProvincialNavigationRail), findsOneWidget);
    controller.dispose();
  });
}

Future<AuthenticationController> _pumpShell(
  WidgetTester tester, {
  MemberDirectoryRepository? directoryRepository,
  ReligiousProfileRepository? profileRepository,
  DashboardRepository? dashboardRepository,
  ProvinceRepository? provinceRepository,
  double textScaleFactor = 1,
}) async {
  final session = AuthSession(
    user: const AuthUser(id: 'provincial-1', email: 'provincial@example.com'),
    accessToken: 'test-access-token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  final controller = AuthenticationController(
    _ShellAuthenticationService(session),
    InMemorySessionStore(),
  );
  await controller.restoreSession();
  await tester.pumpWidget(
    AuthenticationScope(
      controller: controller,
      child: MaterialApp(
        key: ValueKey(textScaleFactor),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child!,
        ),
        home: ProvincialAppShell(
          memberDirectoryRepository:
              directoryRepository ?? const _DirectoryRepository([]),
          religiousProfileRepository:
              profileRepository ?? const _EmptyProfileRepository(),
          dashboardRepository:
              dashboardRepository ?? const _DashboardRepository(),
          provinceRepository: provinceRepository ?? const _ProvinceRepository(),
          organizationIdentityRepository: const _OrganizationRepository(),
          askCommunioService: const _AskCommunioService(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

class _OrganizationRepository implements OrganizationIdentityRepository {
  const _OrganizationRepository();

  @override
  Future<OrganizationIdentitySnapshot> fetchIdentity() async =>
      const OrganizationIdentitySnapshot(
        congregation: CongregationProfile(
          id: 'congregation-1',
          name: 'Missionaries of St. Antony',
          founder: 'Fr. Antony Maria De Rossi',
          patronSaintName: 'St. Antony',
        ),
        leaders: [],
        province: ProvinceProfile(
          id: 'province-1',
          congregationName: 'Missionaries of St. Antony',
          name: 'Indian Province',
          motto: 'Together in Faith, United in Mission',
          activeMembers: 113,
          activeCommunities: 16,
          activeMinistries: 36,
        ),
      );
}

class _DashboardRepository implements DashboardRepository {
  const _DashboardRepository();
  @override
  Future<DashboardSnapshot> fetchDashboard() async => DashboardSnapshot(
    metrics: const [
      OverviewMetric(
        value: '113',
        label: 'Religious',
        icon: Icons.groups_outlined,
        accent: Colors.blue,
      ),
      OverviewMetric(
        value: '16',
        label: 'Communities',
        icon: Icons.church_outlined,
        accent: Colors.green,
      ),
      OverviewMetric(
        value: '36',
        label: 'Ministries',
        icon: Icons.work_outline,
        accent: Colors.purple,
      ),
      OverviewMetric(
        value: '34',
        label: 'Formation',
        icon: Icons.school_outlined,
        accent: Colors.cyan,
      ),
      OverviewMetric(
        value: '11',
        label: 'Candidates',
        icon: Icons.person_add_alt_outlined,
        accent: Colors.orange,
      ),
      OverviewMetric(
        value: '6',
        label: 'Novices',
        icon: Icons.auto_stories_outlined,
        accent: Colors.blue,
      ),
      OverviewMetric(
        value: '15',
        label: 'Temporary Professed',
        icon: Icons.workspace_premium_outlined,
        accent: Colors.green,
      ),
      OverviewMetric(
        value: '10',
        label: 'Office Holders',
        icon: Icons.badge_outlined,
        accent: Colors.purple,
      ),
    ],
    attention: [
      PulseEvent(
        id: 'hospital-1',
        memberId: 'member-1',
        photoUrl: 'https://example.org/augustine.jpg',
        memberName: 'Fr. Augustine Palackal',
        type: 'hospital',
        title: 'Hospital Admission',
        location: 'St. Joseph Hospital, Bengaluru',
        fromDate: DateTime(2026, 8, 16),
        toDate: DateTime(2026, 8, 20),
        timing: 'CURRENT',
        priority: 'high',
        icon: Icons.local_hospital_outlined,
        accent: Colors.red,
      ),
    ],
    celebrations: [
      CelebrationItem(
        memberId: 'member-2',
        photoUrl: 'https://example.org/pradeep.jpg',
        memberName: 'Pradeep Raj',
        kind: 'Birthday',
        date: DateTime(2026, 8, 19),
        daysUntil: 0,
        icon: Icons.cake_outlined,
        accent: Colors.purple,
        mobile: '+91 70000 00041',
        whatsApp: '+91 70000 00041',
      ),
    ],
    movements: [
      PulseEvent(
        id: 'travel-1',
        memberId: 'member-3',
        photoUrl: 'https://example.org/peter.jpg',
        memberName: 'Peter Philip',
        type: 'travel',
        title: 'Province Travel',
        timing: 'CURRENT',
        priority: 'normal',
        icon: Icons.flight_outlined,
        accent: Colors.blue,
      ),
    ],
    upcomingEvents: [
      PulseEvent(
        id: 'visit-1',
        memberName: 'Thomas Mathew',
        type: 'visit',
        title: 'Provincial Community Visitation',
        timing: 'UPCOMING',
        priority: 'high',
        icon: Icons.travel_explore_outlined,
        accent: Colors.amber,
      ),
    ],
    recentUpdates: [
      ProvinceUpdate(
        title: 'Provincial Secretary',
        detail: 'Fr. Thomas Mathew · Provincial House',
        date: '18 Aug 2026',
        icon: Icons.badge_outlined,
        memberId: 'member-4',
        photoUrl: 'https://example.org/thomas.jpg',
      ),
    ],
  );
}

class _DirectoryRepository implements MemberDirectoryRepository {
  const _DirectoryRepository(this.members);
  final List<MemberDirectoryEntry> members;
  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async => members;
}

class _ProvinceRepository implements ProvinceRepository {
  const _ProvinceRepository();

  @override
  Future<List<CommunityRecord>> fetchCommunities() async => const [];

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

  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async => const [];
}

class _ProfileRepository implements ReligiousProfileRepository {
  const _ProfileRepository(this.profile);
  final ReligiousProfile profile;
  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    if (memberId != profile.memberId) {
      throw const ReligiousProfileException(
        ReligiousProfileFailureKind.notFound,
      );
    }
    return profile;
  }
}

class _EmptyProfileRepository implements ReligiousProfileRepository {
  const _EmptyProfileRepository();

  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async {
    throw const ReligiousProfileException(ReligiousProfileFailureKind.notFound);
  }
}

class _AskCommunioService implements AskCommunioService {
  const _AskCommunioService();

  @override
  Future<AskCommunioResponse> ask(AskCommunioRequest request) async {
    throw const AskCommunioException('No response configured for this test.');
  }
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

class _ShellAuthenticationService implements AuthenticationService {
  _ShellAuthenticationService(this._session);

  final AuthSession _session;

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<void> get passwordRecoveryRequests => const Stream.empty();

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async => _session;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword(String password) async {}
}
