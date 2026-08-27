import 'package:communio/app/shell/models/app_navigation.dart';
import 'package:communio/core/theme/colors.dart';
import 'package:communio/features/organization_identity/data/organization_identity_repository.dart';
import 'package:communio/features/organization_identity/models/organization_identity_models.dart';
import 'package:communio/features/organization_identity/screens/organization_identity_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the complete congregation institutional profile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrganizationIdentityScreen(
            repository: _IdentityRepository(),
            page: OrganizationIdentityPage.congregation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MSA'), findsOneWidget);
    expect(find.text('Missionaries of St. Antony'), findsOneWidget);
    expect(find.text('In Communion for Mission'), findsOneWidget);
    expect(find.text('Charism & Mission'), findsOneWidget);
    expect(find.text('Foundation'), findsOneWidget);
    expect(find.text('Fr. Antony Maria De Rossi'), findsOneWidget);
    expect(find.text('St. Antony'), findsOneWidget);
    expect(find.text('1938'), findsOneWidget);
    expect(find.text('General Administration'), findsOneWidget);
    expect(find.text('General Leadership'), findsOneWidget);
    expect(find.text('Fr. Michael D’Souza, MSA'), findsOneWidget);
    expect(find.text('Fr. Jean-Baptiste Moreau, MSA'), findsOneWidget);
    expect(
      find.byTooltip('Call Fr. Jean-Baptiste Moreau, MSA'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('WhatsApp Fr. Jean-Baptiste Moreau, MSA'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Email Fr. Jean-Baptiste Moreau, MSA'),
      findsOneWidget,
    );
    expect(find.byTooltip('Call Fr. Michael D’Souza, MSA'), findsNothing);
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('congregation-leader-name-leader-0')),
          )
          .style
          ?.color,
      AppColors.primary,
    );
    expect(find.text('Congregation at a Glance'), findsOneWidget);
    expect(find.text('113 Religious'), findsOneWidget);
    expect(find.text('12 Communities'), findsOneWidget);
    expect(find.text('21 Ministries'), findsOneWidget);
    expect(find.text('Our Story'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('congregation profile remains safe at narrow mobile widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrganizationIdentityScreen(
              repository: _IdentityRepository(),
              page: OrganizationIdentityPage.congregation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('General Administration'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('congregation leadership ordering is stable', () {
    final leaders = orderedCongregationLeaders([
      const CongregationLeader(
        id: 'second',
        displayName: 'Second',
        roleName: 'Council Member',
        displayOrder: 2,
      ),
      const CongregationLeader(
        id: 'first',
        displayName: 'First',
        roleName: 'Superior General',
        displayOrder: 1,
      ),
      const CongregationLeader(
        id: 'same-order',
        displayName: 'Same order',
        roleName: 'Council Member',
        displayOrder: 2,
      ),
    ]);
    expect(leaders.map((leader) => leader.id), [
      'first',
      'second',
      'same-order',
    ]);
  });

  test('redundant congregation leadership navigation entry is removed', () {
    expect(
      RoleNavigationConfiguration.provincial.items.map(
        (item) => item.destination,
      ),
      isNot(contains(AppDestination.congregationLeadership)),
    );
    expect(
      RoleNavigationConfiguration.provincial.items.map((item) => item.label),
      isNot(contains('Congregation Leadership')),
    );
  });

  testWidgets('missing congregation fields omit empty optional sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrganizationIdentityScreen(
            repository: _SparseIdentityRepository(),
            page: OrganizationIdentityPage.congregation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Charism & Mission'), findsNothing);
    expect(find.text('Foundation'), findsNothing);
    expect(find.text('General Administration'), findsNothing);
    expect(find.text('General Leadership'), findsNothing);
    expect(find.text('Our Story'), findsNothing);
  });

  testWidgets('shows congregation identity and all five leaders in order', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrganizationIdentityScreen(
            repository: _IdentityRepository(),
            page: OrganizationIdentityPage.leadership,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Missionaries of St. Antony'), findsOneWidget);
    expect(find.text('Superior General'), findsOneWidget);
    expect(find.text('Fr. Michael D’Souza, MSA'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fr. Jean-Baptiste Moreau, MSA'), findsOneWidget);
    expect(
      find.byTooltip('Call Fr. Jean-Baptiste Moreau, MSA'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Email Fr. Jean-Baptiste Moreau, MSA'),
      findsOneWidget,
    );
  });

  testWidgets('shows Province identity and safely derived statistics', (
    tester,
  ) async {
    ProvinceLeader? selectedLeader;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationIdentityScreen(
            repository: const _IdentityRepository(),
            page: OrganizationIdentityPage.province,
            onProvinceLeader: (leader) => selectedLeader = leader,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Indian Province'), findsOneWidget);
    expect(find.text('Missionaries of St. Antony'), findsWidgets);
    expect(find.text('Province Details'), findsOneWidget);
    expect(find.text('Provincial House, Bengaluru'), findsOneWidget);
    expect(find.text('113'), findsOneWidget);
    expect(find.text('Active Members'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Communities'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('Ministries'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('Formation Members'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Provincial Offices'), findsOneWidget);

    await tester.ensureVisible(find.text('Provincial Leadership'));
    expect(find.text('Provincial Leadership'), findsOneWidget);
    expect(find.text('Fr. Thomas Mathew'), findsOneWidget);
    expect(find.text('Formation Director'), findsNothing);
    await tester.ensureVisible(find.text('Fr. Thomas Mathew'));
    await tester.tap(find.text('Fr. Thomas Mathew'));
    expect(selectedLeader?.memberId, 'provincial-member');

    await tester.ensureVisible(find.text('Province Contact'));
    expect(find.byTooltip('Call Indian Province'), findsOneWidget);
    expect(find.byTooltip('Email Indian Province'), findsOneWidget);
    expect(find.text('Province Identity'), findsNothing);
    expect(find.text('Province History'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Province profile remains safe at narrow mobile widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrganizationIdentityScreen(
              repository: _IdentityRepository(),
              page: OrganizationIdentityPage.province,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Province Contact'));
      expect(tester.takeException(), isNull);
    }
  });

  test('Provincial leadership keeps core roles in governance order', () {
    final leaders = orderedProvincialLeaders(const [
      ProvinceLeader(
        memberId: 'formation',
        displayName: 'Formation Director',
        roleCode: 'formation_director',
        roleName: 'Formation Director',
      ),
      ProvinceLeader(
        memberId: 'bursar',
        displayName: 'Bursar',
        roleCode: 'provincial_bursar',
        roleName: 'Provincial Bursar',
      ),
      ProvinceLeader(
        memberId: 'provincial',
        displayName: 'Provincial',
        roleCode: 'provincial',
        roleName: 'Provincial',
      ),
      ProvinceLeader(
        memberId: 'councillor',
        displayName: 'Councillor',
        roleCode: 'provincial_councillor',
        roleName: 'Provincial Councillor',
      ),
    ]);
    expect(leaders.map((leader) => leader.memberId), [
      'provincial',
      'councillor',
      'bursar',
    ]);
  });

  testWidgets('Province optional sections are omitted when data is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrganizationIdentityScreen(
            repository: _SparseIdentityRepository(),
            page: OrganizationIdentityPage.province,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current Province Snapshot'), findsOneWidget);
    expect(find.text('Active Members'), findsOneWidget);
    expect(find.text('Communities'), findsOneWidget);
    expect(find.text('Ministries'), findsOneWidget);
    expect(find.text('Provincial Leadership'), findsNothing);
    expect(find.text('Province Contact'), findsNothing);
    expect(find.text('Province Identity'), findsNothing);
    expect(find.text('Province History'), findsNothing);
  });
}

class _IdentityRepository implements OrganizationIdentityRepository {
  const _IdentityRepository();

  @override
  Future<OrganizationIdentitySnapshot> fetchIdentity() async =>
      OrganizationIdentitySnapshot(
        congregation: const CongregationProfile(
          id: 'congregation',
          name: 'Missionaries of St. Antony',
          abbreviation: 'MSA',
          motto: 'In Communion for Mission',
          charism:
              'To witness to the Gospel through community life and mission.',
          founder: 'Fr. Antony Maria De Rossi',
          patronSaintName: 'St. Antony',
          foundedYear: 1938,
          generalateCity: 'Rome',
          generalateAddress: 'Via Sant’Antonio 48\n00165 Rome\nItaly',
          country: 'Italy',
          email: 'general-administration-office@missionariesofstantony.org',
          phone: '+39 06 5550 1840',
          website: 'https://www.missionariesofstantony.org',
        ),
        leaders: List.generate(
          5,
          (index) => CongregationLeader(
            id: 'leader-$index',
            displayName: index == 0
                ? 'Fr. Michael D’Souza, MSA'
                : index == 4
                ? 'Fr. Jean-Baptiste Moreau, MSA'
                : 'General Administration Member $index',
            roleName: index == 0 ? 'Superior General' : 'General Councillor',
            displayOrder: index + 1,
            countryOfOrigin: index == 0 ? 'India' : 'Italy',
            administrationCity: 'Rome',
            email: index == 4 ? 'councillor2@example.org' : null,
            phone: index == 4 ? '+39 06 5550 1845' : null,
          ),
        ),
        province: const ProvinceProfile(
          id: 'province',
          congregationName: 'Missionaries of St. Antony',
          name: 'Indian Province',
          motto: 'Together in Faith, United in Mission',
          headquarters: 'Provincial House, Bengaluru',
          address: '12 Mission Road, Bengaluru 560001',
          country: 'India',
          email: 'province-office@missionariesofstantony.org',
          phone: '+91 80 5550 1840',
          website: 'https://india.missionariesofstantony.org',
          activeMembers: 113,
          activeCommunities: 12,
          activeMinistries: 21,
          activeFormationMembers: 34,
          currentProvincialOffices: 6,
        ),
        provincialLeaders: const [
          ProvinceLeader(
            memberId: 'secretary-member',
            displayName: 'Fr. Joseph Secretary',
            roleCode: 'provincial_secretary',
            roleName: 'Provincial Secretary',
          ),
          ProvinceLeader(
            memberId: 'formation-member',
            displayName: 'Fr. Formation Director',
            roleCode: 'formation_director',
            roleName: 'Formation Director',
          ),
          ProvinceLeader(
            memberId: 'provincial-member',
            displayName: 'Fr. Thomas Mathew',
            roleCode: 'provincial',
            roleName: 'Provincial',
            phone: '+91 98765 43210',
            whatsApp: '+91 98765 43210',
            email: 'provincial@example.org',
          ),
          ProvinceLeader(
            memberId: 'assistant-member',
            displayName: 'Fr. Assistant',
            roleCode: 'assistant_provincial',
            roleName: 'Assistant Provincial',
          ),
          ProvinceLeader(
            memberId: 'councillor-member',
            displayName: 'Fr. Councillor',
            roleCode: 'provincial_councillor',
            roleName: 'Provincial Councillor',
          ),
          ProvinceLeader(
            memberId: 'bursar-member',
            displayName: 'Fr. Bursar',
            roleCode: 'provincial_bursar',
            roleName: 'Provincial Bursar',
          ),
          ProvinceLeader(
            memberId: 'vice-member',
            displayName: 'Fr. Vice',
            roleCode: 'vice_provincial',
            roleName: 'Vice Provincial',
          ),
        ],
      );
}

class _SparseIdentityRepository implements OrganizationIdentityRepository {
  const _SparseIdentityRepository();

  @override
  Future<OrganizationIdentitySnapshot> fetchIdentity() async =>
      const OrganizationIdentitySnapshot(
        congregation: CongregationProfile(
          id: 'sparse-congregation',
          name: 'Sparse Congregation',
        ),
        leaders: [],
        province: ProvinceProfile(
          id: 'sparse-province',
          congregationName: 'Sparse Congregation',
          name: 'Sparse Province',
          activeMembers: 0,
          activeCommunities: 0,
          activeMinistries: 0,
        ),
      );
}
