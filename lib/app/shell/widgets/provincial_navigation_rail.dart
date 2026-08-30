import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/app_navigation.dart';
import 'shell_account_menu.dart';

/// A scroll-safe compact rail for tablet and smaller desktop windows.
class ProvincialNavigationRail extends StatelessWidget {
  const ProvincialNavigationRail({
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
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 210,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppAssets.logo,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'COMMUNIO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.responsive(context)
                              .sidebarWordmark
                              .copyWith(
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: AppSpacing.xxs),
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: configuration.items.length,
                      itemBuilder: (context, index) {
                        final item = configuration.items[index];
                        return _CompactRailItem(
                          item: item,
                          selected: item.destination == selected,
                          onTap: () => onSelected(item.destination),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: AppSpacing.xxs),
                ShellAccountMenu(
                  displayName: displayName,
                  compact: true,
                  onSignOut: onSignOut,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactRailItem extends StatelessWidget {
  const _CompactRailItem({
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
      child: Tooltip(
        message: item.label,
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSpacing.massive),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.responsive(context).labelMedium
                          .copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
