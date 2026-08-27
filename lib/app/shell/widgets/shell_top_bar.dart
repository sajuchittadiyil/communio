import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/app_navigation.dart';
import 'shell_account_menu.dart';

class ShellTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellTopBar({
    required this.title,
    required this.displayName,
    required this.onNavigate,
    required this.onSignOut,
    required this.onSearch,
    this.mobile = false,
    this.mobileBranded = false,
    super.key,
  });

  final String title;
  final String displayName;
  final ValueChanged<AppDestination> onNavigate;
  final VoidCallback onSignOut;
  final VoidCallback onSearch;
  final bool mobile;
  final bool mobileBranded;

  static const double _mobileHeight = 38;

  @override
  Size get preferredSize =>
      Size.fromHeight(mobile ? _mobileHeight : AppSpacing.giant);

  @override
  Widget build(BuildContext context) {
    if (mobile) {
      if (mobileBranded) {
        return AppBar(
          toolbarHeight: _mobileHeight,
          titleSpacing: AppSpacing.lg,
          title: Row(
            children: [
              Image.asset(
                AppAssets.logo,
                width: AppSpacing.huge,
                height: AppSpacing.huge,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'COMMUNIO',
                  maxLines: 1,
                  style: AppTypography.responsive(context).titleMedium.copyWith(
                    color: AppColors.primary,
                    letterSpacing: AppSpacing.xxs,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _showComingSoon(context, 'Notifications'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            ShellAccountMenu(
              displayName: displayName,
              compact: true,
              onNavigate: onNavigate,
              onSignOut: onSignOut,
            ),
          ],
        );
      }
      return AppBar(
        toolbarHeight: _mobileHeight,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: title.length > 20
              ? AppTypography.responsive(context).titleSmall
              : AppTypography.responsive(context).titleMedium,
        ),
        actions: _actions(context, compact: true),
      );
    }

    return Material(
      color: AppColors.appBarSurface,
      child: Container(
        height: AppSpacing.ultra,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.mega * 3),
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.responsive(
                  context,
                ).titleLarge.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.max * 5,
                  ),
                  child: Semantics(
                    textField: true,
                    label: 'Global search',
                    child: TextField(
                      readOnly: true,
                      onTap: onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search Communio',
                        hintStyle: AppTypography.responsive(
                          context,
                        ).bodyMedium.copyWith(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Row(mainAxisSize: MainAxisSize.min, children: _actions(context)),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, {bool compact = false}) => [
    IconButton(
      tooltip: 'Search',
      onPressed: onSearch,
      icon: const Icon(Icons.search_rounded),
    ),
    IconButton(
      tooltip: 'Notifications',
      onPressed: () => _showComingSoon(context, 'Notifications'),
      icon: const Icon(Icons.notifications_none_rounded),
    ),
    if (!compact)
      IconButton(
        tooltip: 'Help',
        onPressed: () => _showComingSoon(context, 'Help'),
        icon: const Icon(Icons.help_outline_rounded),
      ),
    ShellAccountMenu(
      displayName: displayName,
      compact: compact,
      onNavigate: onNavigate,
      onSignOut: onSignOut,
    ),
  ];

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature will be available soon.')));
  }
}
