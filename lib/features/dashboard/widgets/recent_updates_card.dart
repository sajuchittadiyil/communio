import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/member_avatar.dart';
import '../models/dashboard_models.dart';
import 'dashboard_card.dart';

class RecentUpdatesCard extends StatelessWidget {
  const RecentUpdatesCard({
    required this.items,
    required this.compact,
    required this.onViewAll,
    this.title = 'RECENT UPDATES',
    this.emptyMessage,
    this.onSelected,
    super.key,
  });

  final List<ProvinceUpdate> items;
  final bool compact;
  final VoidCallback onViewAll;
  final String title;
  final String? emptyMessage;
  final ValueChanged<ProvinceUpdate>? onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleItems = compact ? items.take(2) : items;
    return DashboardCard(
      child: Column(
        children: [
          DashboardSectionHeader(
            title: title,
            icon: Icons.new_releases_outlined,
            actionLabel: 'View All',
            onAction: onViewAll,
          ),
          if (items.isEmpty && emptyMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                emptyMessage!,
                style: AppTypography.responsive(
                  context,
                ).bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          for (var index = 0; index < visibleItems.length; index++)
            _UpdateRow(
              item: visibleItems.elementAt(index),
              featured: index == 0,
              onTap: () => onSelected?.call(visibleItems.elementAt(index)),
            ),
        ],
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.item,
    required this.featured,
    required this.onTap,
  });

  final ProvinceUpdate item;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.ultra),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          item.memberId == null
              ? Container(
                  width: featured ? AppSpacing.massive : AppSpacing.huge,
                  height: featured ? AppSpacing.massive : AppSpacing.huge,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Icon(item.icon, color: AppColors.primary),
                )
              : MemberAvatar(
                  name: _memberName(item.detail),
                  photoUrl: item.photoUrl,
                  radius: featured ? 27 : 23,
                  backgroundColor: AppColors.primary.withValues(alpha: .08),
                ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.responsive(context).labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.responsive(
                    context,
                  ).bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  item.date,
                  style: AppTypography.responsive(
                    context,
                  ).labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

String _memberName(String detail) => detail.split(' · ').first.trim();
