import 'package:flutter/material.dart';

enum AppRole { provincial, provincialSecretary, communitySuperior, member }

enum AppDestination {
  dashboard,
  congregationProfile,
  congregationLeadership,
  provinceProfile,
  religious,
  communities,
  ministries,
  formation,
  governance,
  calendar,
  documents,
  reports,
  directory,
  settings,
  myProfile,
  askCommunio,
  more,
}

class AppNavigationItem {
  const AppNavigationItem({
    required this.destination,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final AppDestination destination;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class RoleNavigationConfiguration {
  const RoleNavigationConfiguration({
    required this.role,
    required this.roleLabel,
    required this.items,
  });

  final AppRole role;
  final String roleLabel;
  final List<AppNavigationItem> items;

  static const provincial = RoleNavigationConfiguration(
    role: AppRole.provincial,
    roleLabel: 'Provincial / Provincial Team',
    items: [
      AppNavigationItem(
        destination: AppDestination.dashboard,
        label: 'Dashboard',
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.congregationProfile,
        label: 'Congregation Profile',
        icon: Icons.church_outlined,
        selectedIcon: Icons.church_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.provinceProfile,
        label: 'Province Profile',
        icon: Icons.public_outlined,
        selectedIcon: Icons.public_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.religious,
        label: 'Religious',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.communities,
        label: 'Communities',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.ministries,
        label: 'Ministries',
        icon: Icons.volunteer_activism_outlined,
        selectedIcon: Icons.volunteer_activism_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.formation,
        label: 'Formation',
        icon: Icons.school_outlined,
        selectedIcon: Icons.school_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.governance,
        label: 'Governance',
        icon: Icons.account_balance_outlined,
        selectedIcon: Icons.account_balance_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.calendar,
        label: 'Calendar',
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_month_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.documents,
        label: 'Documents',
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.reports,
        label: 'Reports',
        icon: Icons.insert_chart_outlined_rounded,
        selectedIcon: Icons.insert_chart_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.directory,
        label: 'Directory',
        icon: Icons.contacts_outlined,
        selectedIcon: Icons.contacts_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.settings,
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ],
  );

  static const member = RoleNavigationConfiguration(
    role: AppRole.member,
    roleLabel: 'Member',
    items: [
      AppNavigationItem(
        destination: AppDestination.dashboard,
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.religious,
        label: 'Religious',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.communities,
        label: 'Communities',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.calendar,
        label: 'Calendar',
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_month_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.ministries,
        label: 'Ministries',
        icon: Icons.volunteer_activism_outlined,
        selectedIcon: Icons.volunteer_activism_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.documents,
        label: 'Documents',
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.congregationProfile,
        label: 'Congregation Profile',
        icon: Icons.church_outlined,
        selectedIcon: Icons.church_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.provinceProfile,
        label: 'Province Profile',
        icon: Icons.public_outlined,
        selectedIcon: Icons.public_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.myProfile,
        label: 'My Profile',
        icon: Icons.account_circle_outlined,
        selectedIcon: Icons.account_circle_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.askCommunio,
        label: 'Ask Communio',
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome_rounded,
      ),
      AppNavigationItem(
        destination: AppDestination.settings,
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ],
  );

  static final communitySuperior = RoleNavigationConfiguration(
    role: AppRole.communitySuperior,
    roleLabel: 'Community Superior',
    items: member.items,
  );
}

bool destinationAllowed(
  RoleNavigationConfiguration configuration,
  AppDestination destination,
) =>
    configuration.items.any((item) => item.destination == destination) ||
    destination == AppDestination.congregationLeadership &&
        configuration.items.any(
          (item) => item.destination == AppDestination.congregationProfile,
        );

extension NavigationLookup on RoleNavigationConfiguration {
  AppNavigationItem itemFor(AppDestination destination) {
    if (destination == AppDestination.congregationLeadership &&
        destinationAllowed(this, destination)) {
      return const AppNavigationItem(
        destination: AppDestination.congregationLeadership,
        label: 'General Leadership',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups_rounded,
      );
    }
    return items.firstWhere((item) => item.destination == destination);
  }
}
