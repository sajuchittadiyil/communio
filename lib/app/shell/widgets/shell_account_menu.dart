import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/app_navigation.dart';
import 'user_identity.dart';

enum ShellAccountAction { profile, settings, signOut }

class ShellAccountMenu extends StatelessWidget {
  const ShellAccountMenu({
    required this.displayName,
    required this.onNavigate,
    required this.onSignOut,
    this.compact = false,
    super.key,
  });

  final String displayName;
  final ValueChanged<AppDestination> onNavigate;
  final VoidCallback onSignOut;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ShellAccountAction>(
      tooltip: 'Account menu',
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ShellAccountAction.profile,
          child: _MenuLabel(
            icon: Icons.person_outline_rounded,
            label: 'My Profile',
          ),
        ),
        PopupMenuItem(
          value: ShellAccountAction.settings,
          child: _MenuLabel(icon: Icons.settings_outlined, label: 'Settings'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: ShellAccountAction.signOut,
          child: _MenuLabel(icon: Icons.logout_rounded, label: 'Sign Out'),
        ),
      ],
      child: Semantics(
        button: true,
        label: 'Open account menu for $displayName',
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
          child: UserIdentityAvatar(
            displayName: displayName,
            radius: compact ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, ShellAccountAction action) {
    switch (action) {
      case ShellAccountAction.profile:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile will be available soon.')),
        );
      case ShellAccountAction.settings:
        onNavigate(AppDestination.settings);
      case ShellAccountAction.signOut:
        onSignOut();
    }
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.xl, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: AppTypography.responsive(context).bodyMedium),
      ],
    );
  }
}
