import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/dashboard/screens/provincial_dashboard_screen.dart';
import '../../../features/access/data/member_safe_repositories.dart';
import '../../../features/access/data/member_celebrations_repository.dart';
import '../../../features/access/models/app_access_context.dart';
import '../../../features/access/screens/member_home_screen.dart';
import '../../../features/documents/data/documents_repository.dart';
import '../../../features/documents/screens/documents_screen.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/widgets/module_background.dart';
import '../../../features/dashboard/data/dashboard_repository.dart';
import '../../../features/governance/data/governance_repository.dart';
import '../../../features/governance/screens/governance_screens.dart';
import '../../../features/religious_directory/data/member_directory_repository.dart';
import '../../../features/religious_directory/models/member_directory_entry.dart';
import '../../../features/religious_directory/screens/religious_directory_screen.dart';
import '../../../features/religious_profile/data/religious_profile_repository.dart';
import '../../../features/religious_profile/screens/religious_profile_screen.dart';
import '../../../features/province_modules/data/province_repository.dart';
import '../../../features/province_modules/screens/province_module_screens.dart';
import '../../../features/province_modules/screens/calendar_screen.dart';
import '../../../features/organization_identity/data/organization_identity_repository.dart';
import '../../../features/organization_identity/screens/organization_identity_screens.dart';
import '../models/app_navigation.dart';

class ShellDestinationView extends StatelessWidget {
  const ShellDestinationView({
    required this.item,
    required this.displayName,
    required this.onNavigate,
    required this.memberDirectoryRepository,
    required this.onMemberSelected,
    required this.religiousProfileRepository,
    required this.onProfileBack,
    required this.dashboardRepository,
    required this.provinceRepository,
    required this.governanceRepository,
    required this.organizationIdentityRepository,
    required this.onFormationFilter,
    required this.onAskCommunio,
    this.onCommunity,
    this.onMinistry,
    this.onAddCommunityEvent,
    this.onPlanCommunityEvent,
    this.onCommunityMeetingMinutes,
    this.memberCelebrationsRepository =
        const EmptyMemberCelebrationsRepository(),
    this.access = const AppAccessContext.provincial(),
    this.profileMemberId,
    this.formationFilter,
    super.key,
  });

  final AppNavigationItem item;
  final String displayName;
  final ValueChanged<AppDestination> onNavigate;
  final MemberDirectoryRepository memberDirectoryRepository;
  final ValueChanged<MemberDirectoryEntry> onMemberSelected;
  final ReligiousProfileRepository religiousProfileRepository;
  final VoidCallback onProfileBack;
  final String? profileMemberId;
  final DashboardRepository dashboardRepository;
  final ProvinceRepository provinceRepository;
  final GovernanceRepository governanceRepository;
  final OrganizationIdentityRepository organizationIdentityRepository;
  final ValueChanged<String?> onFormationFilter;
  final VoidCallback onAskCommunio;
  final ValueChanged<String>? onCommunity;
  final ValueChanged<String>? onMinistry;
  final VoidCallback? onAddCommunityEvent;
  final VoidCallback? onPlanCommunityEvent;
  final VoidCallback? onCommunityMeetingMinutes;
  final MemberCelebrationsRepository memberCelebrationsRepository;
  final AppAccessContext access;
  final String? formationFilter;

  @override
  Widget build(BuildContext context) =>
      ModuleBackground(child: _destination(context));

  Widget _destination(BuildContext context) {
    if (access.isMemberLike &&
        !destinationAllowed(
          access.isCommunitySuperior
              ? RoleNavigationConfiguration.communitySuperior
              : RoleNavigationConfiguration.member,
          item.destination,
        )) {
      return const Center(
        key: Key('member-restricted-destination'),
        child: Text('This area is not available for your role.'),
      );
    }
    if (profileMemberId case final memberId?) {
      return ReligiousProfileScreen(
        memberId: memberId,
        repository: religiousProfileRepository,
        onBack: onProfileBack,
      );
    }
    if (item.destination == AppDestination.dashboard) {
      if (access.isMemberLike) {
        return MemberHomeScreen(
          displayName: displayName,
          memberId: access.memberId!,
          directoryRepository: memberDirectoryRepository,
          onNavigate: onNavigate,
          onMyProfile: () => onNavigate(AppDestination.myProfile),
          celebrationsRepository: memberCelebrationsRepository,
          onCelebrationMember: (memberId) => onMemberSelected(
            MemberDirectoryEntry(
              id: memberId,
              religiousId: '',
              displayName: 'Religious',
              memberStatus: 'Active',
            ),
          ),
          onCommunity: onCommunity,
          onMinistry: onMinistry,
          communitySuperior: access.isCommunitySuperior,
          managedCommunityName: access.managedCommunityName,
          managedCommunityId: access.managedCommunityId,
          provinceRepository: provinceRepository,
          onAddCommunityEvent: onAddCommunityEvent,
          onPlanCommunityEvent: onPlanCommunityEvent,
          onCommunityMeetingMinutes: onCommunityMeetingMinutes,
        );
      }
      return ProvincialDashboardScreen(
        displayName: displayName,
        onNavigate: onNavigate,
        repository: dashboardRepository,
        onMemberId: (id) => onMemberSelected(
          MemberDirectoryEntry(
            id: id,
            religiousId: '',
            displayName: 'Religious',
            memberStatus: 'Active',
          ),
        ),
        onFormationFilter: onFormationFilter,
        onAskCommunio: onAskCommunio,
        organizationIdentityRepository: organizationIdentityRepository,
      );
    }
    if (item.destination == AppDestination.religious) {
      return ReligiousDirectoryScreen(
        repository: memberDirectoryRepository,
        onMemberSelected: onMemberSelected,
      );
    }
    if (item.destination == AppDestination.congregationProfile) {
      return OrganizationIdentityScreen(
        repository: organizationIdentityRepository,
        page: OrganizationIdentityPage.congregation,
      );
    }
    if (item.destination == AppDestination.congregationLeadership) {
      return OrganizationIdentityScreen(
        repository: organizationIdentityRepository,
        page: OrganizationIdentityPage.leadership,
      );
    }
    if (item.destination == AppDestination.provinceProfile) {
      return OrganizationIdentityScreen(
        repository: organizationIdentityRepository,
        page: OrganizationIdentityPage.province,
        onProvinceLeader: (leader) => onMemberSelected(
          MemberDirectoryEntry(
            id: leader.memberId,
            religiousId: '',
            displayName: leader.displayName,
            photoUrl: leader.photoUrl,
            memberStatus: 'Active',
          ),
        ),
      );
    }
    if (item.destination == AppDestination.communities) {
      return CommunitiesScreen(
        repository: provinceRepository,
        onMember: onMemberSelected,
      );
    }
    if (item.destination == AppDestination.ministries) {
      return MinistriesScreen(
        repository: provinceRepository,
        onMember: onMemberSelected,
      );
    }
    if (item.destination == AppDestination.formation) {
      return FormationScreen(
        repository: provinceRepository,
        onMember: onMemberSelected,
        initialStage: formationFilter,
      );
    }
    if (item.destination == AppDestination.governance) {
      return GovernanceDirectoryScreen(
        repository: governanceRepository,
        onMember: (member) => onMemberSelected(
          MemberDirectoryEntry(
            id: member.memberId,
            religiousId: member.religiousId ?? '',
            displayName: member.displayName,
            photoUrl: member.photoUrl,
            memberStatus: 'Active',
          ),
        ),
      );
    }
    if (item.destination == AppDestination.calendar) {
      return CalendarScreen(
        repository: provinceRepository,
        onMember: onMemberSelected,
      );
    }
    if (item.destination == AppDestination.documents) {
      final repository = AppEnvironment.hasSupabaseConfiguration
          ? SupabaseDocumentsRepository(Supabase.instance.client)
          : const DemoDocumentsRepository();
      return DocumentsScreen(
        repository: access.isCommunitySuperior
            ? CommunitySuperiorDocumentsRepository(
                repository,
                managedCommunityId: access.managedCommunityId!,
              )
            : access.isMember
            ? MemberDocumentsRepository(repository)
            : repository,
      );
    }
    return Semantics(
      container: true,
      label: '${item.label} page',
      child: const SizedBox.expand(),
    );
  }
}
