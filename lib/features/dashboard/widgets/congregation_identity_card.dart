import 'package:flutter/material.dart';

import '../../../app/shell/models/app_navigation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../organization_identity/data/organization_identity_repository.dart';
import '../../organization_identity/models/organization_identity_models.dart';
import '../models/daily_verse.dart';
import 'dashboard_card.dart';

class CongregationIdentityCard extends StatefulWidget {
  const CongregationIdentityCard({
    required this.repository,
    required this.onNavigate,
    this.today,
    super.key,
  });

  final OrganizationIdentityRepository repository;
  final ValueChanged<AppDestination> onNavigate;
  final DateTime? today;

  @override
  State<CongregationIdentityCard> createState() =>
      _CongregationIdentityCardState();
}

class _CongregationIdentityCardState extends State<CongregationIdentityCard> {
  late final Future<OrganizationIdentitySnapshot> _identity = widget.repository
      .fetchIdentity();

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<OrganizationIdentitySnapshot>(
    future: _identity,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final identity = snapshot.requireData;
      final congregation = identity.congregation;
      final verse = DailyVerseCalendar.forDate(widget.today ?? DateTime.now());
      final styles = AppTypography.responsive(context);
      return DashboardCard(
        key: const Key('province-pulse-identity-card'),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _FounderAvatar(profile: congregation),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          congregation.name,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: styles.sectionTitle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        identity.province.name,
                        textAlign: TextAlign.center,
                        style: styles.bodySecondary.copyWith(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_hasText(identity.province.motto))
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            identity.province.motto!,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: styles.bodySecondary.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VERSE FOR TODAY',
                    style: styles.labelMedium.copyWith(
                      color: AppColors.secondaryDark,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '“${verse.text}” '),
                        TextSpan(
                          text: '— ${verse.reference}',
                          style: styles.bodySecondary.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    style: styles.bodyPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _IdentityAction(
                    label: 'Congregation',
                    icon: Icons.church_outlined,
                    onTap: () =>
                        widget.onNavigate(AppDestination.congregationProfile),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _IdentityAction(
                    label: 'Leadership',
                    icon: Icons.groups_2_outlined,
                    onTap: () => widget.onNavigate(
                      AppDestination.congregationLeadership,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _IdentityAction(
                    label: 'Province',
                    icon: Icons.public_outlined,
                    onTap: () =>
                        widget.onNavigate(AppDestination.provinceProfile),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _FounderAvatar extends StatelessWidget {
  const _FounderAvatar({required this.profile});
  final CongregationProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = _hasText(profile.founderImageUrl)
        ? profile.founderImageUrl
        : profile.patronSaintImageUrl;
    return Semantics(
      label: url == null
          ? '${profile.patronSaintName ?? profile.founder ?? 'Congregation'} image placeholder'
          : '${profile.patronSaintName ?? profile.founder ?? 'Congregation'} image',
      child: CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.secondary.withValues(alpha: .13),
        foregroundImage: url != null
            ? NetworkImage(url)
            : const AssetImage('assets/images/st_antony.png'),
      ),
    );
  }
}

class _IdentityAction extends StatelessWidget {
  const _IdentityAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 15),
    label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      textStyle: AppTypography.responsive(context).labelSmall,
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.primary.withValues(alpha: .24)),
    ),
  );
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
