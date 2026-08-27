import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/app_navigation.dart';
import 'shell_account_menu.dart';
import 'user_identity.dart';

class ProvincialSidebar extends StatelessWidget {
  const ProvincialSidebar({
    required this.configuration,
    required this.selected,
    required this.displayName,
    required this.onSelected,
    required this.onSignOut,
    super.key,
  });

  final RoleNavigationConfiguration configuration;
  final AppDestination selected;
  final String displayName;
  final ValueChanged<AppDestination> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navigationSurface,
      child: SizedBox(
        width: AppSpacing.mega * 3,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            right: false,
            child: Column(
              children: [
                const _SidebarBrand(),
                const Divider(height: AppSpacing.xxs),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: configuration.items.length,
                    itemBuilder: (context, index) {
                      final item = configuration.items[index];
                      return _SidebarItem(
                        item: item,
                        selected: item.destination == selected,
                        onTap: () => onSelected(item.destination),
                      );
                    },
                  ),
                ),
                const Divider(height: AppSpacing.xxs),
                _SidebarProfile(
                  displayName: displayName,
                  roleLabel: configuration.roleLabel,
                  onSelected: onSelected,
                  onSignOut: onSignOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.logo,
            width: AppSpacing.massive + AppSpacing.md,
            height: AppSpacing.massive + AppSpacing.md,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'COMMUNIO',
              overflow: TextOverflow.ellipsis,
              style: AppTypography.responsive(context).sidebarWordmark.copyWith(
                color: AppColors.primary,
                letterSpacing: AppSpacing.xxs,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        selected: selected,
        button: true,
        child: ListTile(
          selected: selected,
          onTap: onTap,
          minTileHeight: AppSpacing.massive,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
          leading: Icon(
            selected ? item.selectedIcon : item.icon,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          title: Text(
            item.label,
            style: AppTypography.responsive(context).labelLarge.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          trailing: selected
              ? Container(
                  width: AppSpacing.xs,
                  height: AppSpacing.xxl,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _SidebarProfile extends StatelessWidget {
  const _SidebarProfile({
    required this.displayName,
    required this.roleLabel,
    required this.onSelected,
    required this.onSignOut,
  });

  final String displayName;
  final String roleLabel;
  final ValueChanged<AppDestination> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          UserIdentityAvatar(displayName: displayName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.responsive(context).labelLarge,
                ),
                Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.responsive(
                    context,
                  ).labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ShellAccountMenu(
            displayName: displayName,
            compact: true,
            onNavigate: onSelected,
            onSignOut: onSignOut,
          ),
        ],
      ),
    );
  }
}
