import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/shadows.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/member_avatar.dart';
import '../models/dashboard_models.dart';
import 'dashboard_card.dart';

class TodaysFocusCard extends StatelessWidget {
  const TodaysFocusCard({
    required this.items,
    required this.onPlaceholder,
    this.title = "TODAY'S FOCUS",
    this.onSelected,
    super.key,
  });

  final List<FocusItem> items;
  final VoidCallback onPlaceholder;
  final String title;
  final ValueChanged<FocusItem>? onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final itemSpacing = compact ? AppSpacing.md : AppSpacing.lg;
    final sectionAccent = items.any((item) => item.emphasized)
        ? AppColors.error
        : AppColors.warning;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: sectionAccent, width: 3)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: DashboardCard(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardSectionHeader(
              title: title,
              icon: Icons.track_changes_rounded,
              accent: sectionAccent,
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = compact
                    ? 1
                    : constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - itemSpacing * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: itemSpacing,
                  runSpacing: compact ? AppSpacing.sm : AppSpacing.lg,
                  children: [
                    for (final item in items.take(3))
                      SizedBox(
                        width: width,
                        child: _FocusItemTile(
                          item: item,
                          onTap: () {
                            if (onSelected != null) {
                              onSelected!(item);
                            } else {
                              onPlaceholder();
                            }
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusItemTile extends StatelessWidget {
  const _FocusItemTile({required this.item, required this.onTap});

  final FocusItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: EdgeInsets.all(
          item.emphasized ? AppSpacing.sm : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: item.emphasized
              ? item.accent.withValues(alpha: .065)
              : AppColors.transparent,
          border: Border.all(
            color: item.emphasized
                ? item.accent.withValues(alpha: .18)
                : AppColors.transparent,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                item.memberId == null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundColor: item.accent.withValues(alpha: .1),
                        child: Icon(item.icon, color: item.accent, size: 20),
                      )
                    : MemberAvatar(
                        name: item.title,
                        photoUrl: item.photoUrl,
                        radius: 20,
                        backgroundColor: item.accent.withValues(alpha: .1),
                      ),
                if (item.memberId != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.surface,
                      child: Icon(item.icon, color: item.accent, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? AppTypography.responsive(
                            context,
                          ).labelMedium.copyWith(
                            color: item.accent,
                            fontWeight: FontWeight.w700,
                          )
                        : AppTypography.responsive(context).labelLarge.copyWith(
                            color: item.accent,
                            fontWeight: FontWeight.w700,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.primaryDetail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? AppTypography.responsive(context).labelSmall
                                : AppTypography.responsive(context).labelMedium)
                            .copyWith(color: item.accent),
                  ),
                  if (item.secondaryDetail != null)
                    Text(
                      item.secondaryDetail!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.responsive(
                        context,
                      ).labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
