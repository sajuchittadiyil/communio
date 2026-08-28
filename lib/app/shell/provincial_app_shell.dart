import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/config/app_environment.dart';
import '../../features/authentication/state/authentication_scope.dart';
import '../../features/access/data/member_safe_repositories.dart';
import '../../features/access/data/member_celebrations_repository.dart';
import '../../features/access/data/member_self_profile_repository.dart';
import '../../features/access/data/community_administration_repository.dart';
import '../../features/access/models/app_access_context.dart';
import '../../features/access/screens/community_administration_screen.dart';
import '../../features/religious_directory/data/member_directory_repository.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/dashboard/data/supabase_dashboard_repository.dart';
import '../../features/dashboard/models/dashboard_models.dart';
import '../../features/governance/data/governance_repository.dart';
import '../../features/governance/data/supabase_governance_repository.dart';
import '../../features/governance/models/governance_models.dart';
import '../../features/religious_directory/data/supabase_member_directory_repository.dart';
import '../../features/religious_directory/models/member_directory_entry.dart';
import '../../features/religious_profile/data/religious_profile_repository.dart';
import '../../features/religious_profile/data/supabase_religious_profile_repository.dart';
import '../../features/religious_profile/models/religious_profile.dart';
import '../../features/province_modules/data/province_repository.dart';
import '../../features/province_modules/data/supabase_province_repository.dart';
import '../../features/province_modules/models/province_models.dart';
import '../../features/organization_identity/data/organization_identity_repository.dart';
import '../../features/organization_identity/data/supabase_organization_identity_repository.dart';
import '../../features/organization_identity/models/organization_identity_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_navigation.dart';
import 'widgets/provincial_mobile_navigation.dart';
import 'widgets/provincial_navigation_rail.dart';
import 'widgets/provincial_sidebar.dart';
import 'widgets/shell_destination_view.dart';
import 'widgets/shell_top_bar.dart';
import 'widgets/global_search_dialog.dart';
import '../../features/province_modules/screens/province_module_screens.dart';
import '../../features/ask_communio/data/ask_communio_service.dart';
import '../../features/ask_communio/data/supabase_ask_communio_service.dart';
import '../../features/ask_communio/models/ask_communio_models.dart';
import '../../features/ask_communio/screens/ask_communio_screen.dart';
import '../../features/demo_persona/models/demo_persona.dart';
import '../../features/demo_persona/data/demo_persona_presenter.dart';

class ProvincialAppShell extends StatefulWidget {
  const ProvincialAppShell({
    this.memberDirectoryRepository,
    this.religiousProfileRepository,
    this.dashboardRepository,
    this.provinceRepository,
    this.governanceRepository,
    this.organizationIdentityRepository,
    this.askCommunioService,
    this.memberCelebrationsRepository,
    this.memberSelfProfileRepository,
    this.access = const AppAccessContext.provincial(),
    super.key,
  });

  final MemberDirectoryRepository? memberDirectoryRepository;
  final ReligiousProfileRepository? religiousProfileRepository;
  final DashboardRepository? dashboardRepository;
  final ProvinceRepository? provinceRepository;
  final GovernanceRepository? governanceRepository;
  final OrganizationIdentityRepository? organizationIdentityRepository;
  final AskCommunioService? askCommunioService;
  final MemberCelebrationsRepository? memberCelebrationsRepository;
  final ReligiousProfileRepository? memberSelfProfileRepository;
  final AppAccessContext access;

  @override
  State<ProvincialAppShell> createState() => _ProvincialAppShellState();
}

class _ProvincialAppShellState extends State<ProvincialAppShell> {
  static const _mobileBreakpoint = 768.0;
  static const _desktopBreakpoint = 1440.0;
  RoleNavigationConfiguration get _configuration =>
      widget.access.isCommunitySuperior
      ? RoleNavigationConfiguration.communitySuperior
      : widget.access.isMember
      ? RoleNavigationConfiguration.member
      : RoleNavigationConfiguration.provincial;

  AppDestination _selected = AppDestination.dashboard;
  String? _profileMemberId;
  String? _formationFilter;
  MemberDirectoryRepository get _directoryRepository =>
      widget.memberDirectoryRepository ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseMemberDirectoryRepository(Supabase.instance.client)
          : const _UnavailableMemberDirectoryRepository());
  MemberDirectoryRepository get _authorizedDirectoryRepository =>
      widget.access.isMemberLike && AppEnvironment.hasSupabaseConfiguration
      ? SupabaseMemberSafeDirectoryRepository(Supabase.instance.client)
      : _directoryRepository;
  ReligiousProfileRepository get _profileRepository =>
      widget.religiousProfileRepository ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseReligiousProfileRepository(Supabase.instance.client)
          : const _UnavailableReligiousProfileRepository());
  DashboardRepository get _dashboardRepository =>
      widget.dashboardRepository ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseDashboardRepository(Supabase.instance.client)
          : const _UnavailableDashboardRepository());
  ProvinceRepository get _provinceRepository =>
      widget.provinceRepository ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseProvinceRepository(Supabase.instance.client)
          : const _UnavailableProvinceRepository());
  GovernanceRepository get _governanceRepository =>
      widget.governanceRepository ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseGovernanceRepository(Supabase.instance.client)
          : const _UnavailableGovernanceRepository());
  ProvinceRepository get _authorizedProvinceRepository =>
      widget.access.isMemberLike
      ? MemberCalendarRepository(
          AppEnvironment.hasSupabaseConfiguration
              ? SupabaseMemberSafeProvinceRepository(
                  Supabase.instance.client,
                  managedCommunityOnly: widget.access.isCommunitySuperior,
                )
              : _provinceRepository,
        )
      : _provinceRepository;
  MemberCelebrationsRepository get _memberCelebrationsRepository =>
      widget.memberCelebrationsRepository ??
      (widget.access.isMemberLike && AppEnvironment.hasSupabaseConfiguration
          ? SupabaseMemberCelebrationsRepository(Supabase.instance.client)
          : const EmptyMemberCelebrationsRepository());
  ReligiousProfileRepository get _authorizedProfileRepository =>
      widget.access.isMemberLike
      ? MemberSafeReligiousProfileRepository(
          currentMemberId: widget.access.memberId!,
          directoryRepository: _authorizedDirectoryRepository,
          selfProfileRepository:
              widget.memberSelfProfileRepository ??
              (AppEnvironment.hasSupabaseConfiguration
                  ? SupabaseMemberSelfProfileRepository(
                      Supabase.instance.client,
                      expectedMemberId: widget.access.memberId!,
                      rpcName: widget.access.isCommunitySuperior
                          ? 'get_current_user_profile_safe'
                          : 'get_member_self_profile_safe',
                    )
                  : const _UnavailableReligiousProfileRepository()),
          otherProfileRepository: AppEnvironment.hasSupabaseConfiguration
              ? SupabaseOtherMemberProfileRepository(Supabase.instance.client)
              : null,
          ownCommunityProfileRepository:
              widget.access.isCommunitySuperior &&
                  AppEnvironment.hasSupabaseConfiguration
              ? SupabaseOtherMemberProfileRepository(
                  Supabase.instance.client,
                  rpcName: 'get_community_superior_resident_profile_safe',
                )
              : null,
          accessRole: widget.access.role,
        )
      : _profileRepository;
  OrganizationIdentityRepository get _organizationIdentityRepository =>
      widget.organizationIdentityRepository ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseOrganizationIdentityRepository(Supabase.instance.client)
          : const _UnavailableOrganizationIdentityRepository());
  OrganizationIdentityRepository get _authorizedIdentityRepository =>
      widget.access.isMemberLike && AppEnvironment.hasSupabaseConfiguration
      ? MemberSafeOrganizationIdentityRepository(Supabase.instance.client)
      : _organizationIdentityRepository;
  AskCommunioService get _askCommunioService =>
      widget.askCommunioService ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseAskCommunioService(Supabase.instance.client)
          : const _UnavailableAskCommunioService());

  @override
  void initState() {
    super.initState();
    final base = Uri.base;
    final fragment = base.fragment.startsWith('/')
        ? base.fragment.substring(1)
        : base.fragment;
    final segments = base.pathSegments.length > 1
        ? base.pathSegments
        : Uri.parse(fragment).pathSegments;
    if (segments.length == 2 && segments.first == 'religious') {
      _selected = AppDestination.religious;
      _profileMemberId = segments.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authentication = AuthenticationScope.of(context);
    final displayName = widget.access.persona == DemoPersona.sisters
        ? 'SOLC Provincial'
        : _displayName(authentication.session?.user.email);
    final selectedItem = _configuration.itemFor(_selected);
    final shellTitle = selectedItem.destination == AppDestination.religious
        ? ''
        : selectedItem.label;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _mobileBreakpoint) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: ShellTopBar(
              title: shellTitle,
              displayName: displayName,
              mobile: true,
              mobileBranded:
                  selectedItem.destination == AppDestination.dashboard,
              onNavigate: _select,
              onSignOut: authentication.signOut,
              onSearch: () => _showSearch(context),
            ),
            body: ShellDestinationView(
              item: selectedItem,
              displayName: displayName,
              onNavigate: _select,
              memberDirectoryRepository: _authorizedDirectoryRepository,
              onMemberSelected: _openMember,
              religiousProfileRepository: _authorizedProfileRepository,
              profileMemberId: _profileMemberId,
              onProfileBack: _closeProfile,
              dashboardRepository: _dashboardRepository,
              provinceRepository: _authorizedProvinceRepository,
              governanceRepository: _governanceRepository,
              organizationIdentityRepository: _authorizedIdentityRepository,
              formationFilter: _formationFilter,
              onFormationFilter: _openFormation,
              onAskCommunio: () => _openAskCommunio(context),
              access: widget.access,
              memberCelebrationsRepository: _memberCelebrationsRepository,
              onCommunity: _openCommunityById,
              onMinistry: _openMinistryById,
              onAddCommunityEvent: () => _openCommunityAdministration(
                CommunityAdministrationAction.calendarEvent,
              ),
              onPlanCommunityEvent: () => _openCommunityAdministration(
                CommunityAdministrationAction.plannedEvent,
              ),
              onCommunityMeetingMinutes: () => _openCommunityAdministration(
                CommunityAdministrationAction.minutes,
              ),
            ),
            bottomNavigationBar: ProvincialMobileNavigation(
              configuration: _configuration,
              selected: _selected,
              onSelected: _select,
            ),
          );
        }

        final navigation = constraints.maxWidth >= _desktopBreakpoint
            ? ProvincialSidebar(
                configuration: _configuration,
                selected: _selected,
                displayName: displayName,
                onSelected: _select,
                onSignOut: authentication.signOut,
              )
            : ProvincialNavigationRail(
                configuration: _configuration,
                selected: _selected,
                displayName: displayName,
                onSelected: _select,
                onSignOut: authentication.signOut,
              );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              navigation,
              Expanded(
                child: Column(
                  children: [
                    ShellTopBar(
                      title: shellTitle,
                      displayName: displayName,
                      onNavigate: _select,
                      onSignOut: authentication.signOut,
                      onSearch: () => _showSearch(context),
                    ),
                    Expanded(
                      child: ShellDestinationView(
                        item: selectedItem,
                        displayName: displayName,
                        onNavigate: _select,
                        memberDirectoryRepository:
                            _authorizedDirectoryRepository,
                        onMemberSelected: _openMember,
                        religiousProfileRepository:
                            _authorizedProfileRepository,
                        profileMemberId: _profileMemberId,
                        onProfileBack: _closeProfile,
                        dashboardRepository: _dashboardRepository,
                        provinceRepository: _authorizedProvinceRepository,
                        governanceRepository: _governanceRepository,
                        organizationIdentityRepository:
                            _authorizedIdentityRepository,
                        formationFilter: _formationFilter,
                        onFormationFilter: _openFormation,
                        onAskCommunio: () => _openAskCommunio(context),
                        access: widget.access,
                        memberCelebrationsRepository:
                            _memberCelebrationsRepository,
                        onCommunity: _openCommunityById,
                        onMinistry: _openMinistryById,
                        onAddCommunityEvent: () => _openCommunityAdministration(
                          CommunityAdministrationAction.calendarEvent,
                        ),
                        onPlanCommunityEvent: () =>
                            _openCommunityAdministration(
                              CommunityAdministrationAction.plannedEvent,
                            ),
                        onCommunityMeetingMinutes: () =>
                            _openCommunityAdministration(
                              CommunityAdministrationAction.minutes,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _select(AppDestination destination) {
    if (destination == AppDestination.more) return;
    if (!destinationAllowed(_configuration, destination)) {
      _denyRestrictedRoute();
      return;
    }
    if (destination == AppDestination.myProfile) {
      _openMyProfile();
      return;
    }
    if (destination == AppDestination.askCommunio) {
      _openAskCommunio(context);
      return;
    }
    if (destination == _selected && _profileMemberId == null) return;
    setState(() {
      _selected = destination;
      _profileMemberId = null;
      if (destination != AppDestination.formation) _formationFilter = null;
    });
    _setWebPath('/');
  }

  void _openFormation(String? stage) {
    if (widget.access.isMemberLike) {
      _denyRestrictedRoute();
      return;
    }
    setState(() {
      _selected = AppDestination.formation;
      _formationFilter = stage;
      _profileMemberId = null;
    });
    _setWebPath('/');
  }

  void _openMyProfile() {
    final memberId = widget.access.memberId;
    if (memberId == null) return;
    setState(() {
      _selected = AppDestination.religious;
      _profileMemberId = memberId;
    });
    _setWebPath('/religious/$memberId');
  }

  void _denyRestrictedRoute() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This area is not available for your role.'),
      ),
    );
    if (_selected != AppDestination.dashboard) {
      setState(() {
        _selected = AppDestination.dashboard;
        _profileMemberId = null;
      });
    }
  }

  void _openMember(MemberDirectoryEntry member) {
    if (kDebugMode && widget.access.persona == DemoPersona.sisters) {
      debugPrint(
        '[SistersPersona] open_profile member_id=${member.id} '
        'alias_found=${DemoPersonaPresenter.member(member.id) != null}',
      );
    }
    setState(() => _profileMemberId = member.id);
    _setWebPath('/religious/${member.id}');
  }

  Future<void> _openCommunityById(String communityId) async {
    final communities = await _authorizedProvinceRepository.fetchCommunities();
    if (!mounted) return;
    final community = communities
        .where((item) => item.id == communityId)
        .firstOrNull;
    if (community == null) {
      _showMissingDetail('community');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityDetailScreen(
          community: community,
          onMember: (member) {
            Navigator.of(context).pop();
            _openMember(member);
          },
        ),
      ),
    );
  }

  Future<void> _openCommunityAdministration(
    CommunityAdministrationAction action,
  ) async {
    if (!widget.access.isCommunitySuperior ||
        widget.access.managedCommunityId == null ||
        !AppEnvironment.hasSupabaseConfiguration) {
      _denyRestrictedRoute();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CommunityAdministrationScreen(
          repository: SupabaseCommunityAdministrationRepository(
            Supabase.instance.client,
          ),
          communityName: widget.access.managedCommunityName ?? 'My Community',
          initialAction: action,
        ),
      ),
    );
  }

  Future<void> _openMinistryById(String ministryId) async {
    final ministries = await _authorizedProvinceRepository.fetchMinistries();
    if (!mounted) return;
    final ministry = ministries
        .where((item) => item.id == ministryId)
        .firstOrNull;
    if (ministry == null) {
      _showMissingDetail('ministry');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MinistryDetailScreen(
          ministry: ministry,
          onMember: (member) {
            Navigator.of(context).pop();
            _openMember(member);
          },
        ),
      ),
    );
  }

  void _showMissingDetail(String type) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to load this $type.')));
  }

  Future<void> _openAskCommunio(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AskCommunioScreen(
            service: _askCommunioService,
            onEntity: (entity) => _openAskEntity(context, entity),
          ),
        ),
      );

  void _openAskEntity(BuildContext context, AskCommunioEntityReference entity) {
    if (entity.type != 'member' || entity.id.isEmpty) return;
    Navigator.of(context).pop();
    _openMember(
      MemberDirectoryEntry(
        id: entity.id,
        religiousId: '',
        displayName: entity.label,
        memberStatus: 'Active',
      ),
    );
  }

  Future<void> _showSearch(BuildContext context) => showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => GlobalSearchDialog(
      members: _directoryRepository,
      province: _provinceRepository,
      onMember: _openMember,
      onCommunity: (community) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(
            community: community,
            onMember: (member) {
              Navigator.of(context).pop();
              _openMember(member);
            },
          ),
        ),
      ),
      onMinistry: (ministry) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MinistryDetailScreen(
            ministry: ministry,
            onMember: (member) {
              Navigator.of(context).pop();
              _openMember(member);
            },
          ),
        ),
      ),
    ),
  );

  void _closeProfile() {
    setState(() => _profileMemberId = null);
    _setWebPath('/');
  }

  void _setWebPath(String path) {
    if (!kIsWeb) return;
    SystemNavigator.routeInformationUpdated(uri: Uri.parse(path));
  }

  String _displayName(String? email) {
    final localPart = email?.split('@').first.trim() ?? '';
    if (localPart.isEmpty) return 'Provincial User';
    return localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _UnavailableReligiousProfileRepository
    implements ReligiousProfileRepository {
  const _UnavailableReligiousProfileRepository();
  @override
  Future<ReligiousProfile> fetchProfile(String memberId) =>
      Future.error(StateError('Supabase is not configured'));
}

class _UnavailableGovernanceRepository implements GovernanceRepository {
  const _UnavailableGovernanceRepository();

  @override
  Future<List<GovernanceBody>> fetchBodies() async => const [];
}

class _UnavailableDashboardRepository implements DashboardRepository {
  const _UnavailableDashboardRepository();
  @override
  Future<DashboardSnapshot> fetchDashboard() =>
      Future.error(StateError('Supabase is not configured'));
}

class _UnavailableMemberDirectoryRepository
    implements MemberDirectoryRepository {
  const _UnavailableMemberDirectoryRepository();
  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() =>
      Future.error(StateError('Supabase is not configured'));
}

class _UnavailableProvinceRepository implements ProvinceRepository {
  const _UnavailableProvinceRepository();
  Future<T> _error<T>() =>
      Future.error(StateError('Supabase is not configured'));
  @override
  Future<List<CommunityRecord>> fetchCommunities() => _error();
  @override
  Future<List<FormationMember>> fetchFormation() => _error();
  @override
  Future<List<MinistryRecord>> fetchMinistries() => _error();
  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() => _error();
  @override
  Future<List<EligibilityRole>> fetchEligibilityRoles() => _error();
  @override
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  }) => _error();
  @override
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance() => _error();
  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() => _error();
}

class _UnavailableOrganizationIdentityRepository
    implements OrganizationIdentityRepository {
  const _UnavailableOrganizationIdentityRepository();
  @override
  Future<OrganizationIdentitySnapshot> fetchIdentity() =>
      Future.error(StateError('Supabase is not configured'));
}

class _UnavailableAskCommunioService implements AskCommunioService {
  const _UnavailableAskCommunioService();
  @override
  Future<AskCommunioResponse> ask(AskCommunioRequest request) => Future.error(
    const AskCommunioException(
      'Ask Communio requires a configured Supabase connection.',
    ),
  );
}
