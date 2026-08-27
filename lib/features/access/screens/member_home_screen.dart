import 'package:flutter/material.dart';

import '../../../app/shell/models/app_navigation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../data/member_celebrations_repository.dart';
import '../models/member_celebration.dart';
import '../../religious_directory/data/member_directory_repository.dart';
import '../../religious_directory/models/member_directory_entry.dart';
import '../../province_modules/data/province_repository.dart';

class MemberHomeScreen extends StatelessWidget {
  const MemberHomeScreen({
    required this.displayName,
    required this.onNavigate,
    required this.onMyProfile,
    required this.memberId,
    required this.directoryRepository,
    this.celebrationsRepository = const EmptyMemberCelebrationsRepository(),
    this.onCelebrationMember,
    this.onCommunity,
    this.onMinistry,
    this.communitySuperior = false,
    this.managedCommunityName,
    this.managedCommunityId,
    this.provinceRepository,
    this.onAddCommunityEvent,
    this.onPlanCommunityEvent,
    this.onCommunityMeetingMinutes,
    super.key,
  });

  final String displayName;
  final ValueChanged<AppDestination> onNavigate;
  final VoidCallback onMyProfile;
  final String memberId;
  final MemberDirectoryRepository directoryRepository;
  final MemberCelebrationsRepository celebrationsRepository;
  final ValueChanged<String>? onCelebrationMember;
  final ValueChanged<String>? onCommunity;
  final ValueChanged<String>? onMinistry;
  final bool communitySuperior;
  final String? managedCommunityName;
  final String? managedCommunityId;
  final ProvinceRepository? provinceRepository;
  final VoidCallback? onAddCommunityEvent;
  final VoidCallback? onPlanCommunityEvent;
  final VoidCallback? onCommunityMeetingMinutes;

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<MemberDirectoryEntry>>(
    future: directoryRepository.fetchMembers(),
    builder: (context, snapshot) {
      final member = snapshot.data
          ?.where((entry) => entry.id == memberId)
          .firstOrNull;
      final name =
          member?.displayName.split(RegExp(r'\s+')).first ?? displayName;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}, $name',
                    style: AppTypography.responsive(
                      context,
                    ).pageTitle.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _dateLabel(DateTime.now()),
                    style: AppTypography.responsive(
                      context,
                    ).bodySmall.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    communitySuperior ? 'Community Superior' : 'Member',
                    style: AppTypography.responsive(context).labelMedium
                        .copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (communitySuperior && managedCommunityName != null)
                    Text(
                      managedCommunityName!,
                      style: AppTypography.responsive(context).bodyMedium
                          .copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    communitySuperior
                        ? 'Your community, Province directory and shared institutional resources.'
                        : 'Your Province directory, community life and shared institutional resources.',
                    style: AppTypography.responsive(
                      context,
                    ).bodyMedium.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MemberCelebrationsCard(
              repository: celebrationsRepository,
              onMember: onCelebrationMember,
              title: communitySuperior
                  ? "TODAY'S CELEBRATIONS"
                  : 'CELEBRATIONS',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (communitySuperior && provinceRepository != null) ...[
              _CommunityTodayCard(
                repository: provinceRepository!,
                communityName: managedCommunityName,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if ((communitySuperior ? managedCommunityName : member?.community)
                case final community?) ...[
              _MemberShortcut(
                icon: Icons.home_work_outlined,
                title: 'My Community',
                subtitle: community,
                onTap:
                    (communitySuperior
                            ? managedCommunityId == null
                            : member?.communityId == null) ||
                        onCommunity == null
                    ? null
                    : () => onCommunity!(
                        communitySuperior
                            ? managedCommunityId!
                            : member!.communityId!,
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (member?.ministryAssignment case final ministry?) ...[
              _MemberShortcut(
                icon: Icons.volunteer_activism_outlined,
                title: 'My Ministry',
                subtitle: ministry,
                onTap: member?.ministryId == null || onMinistry == null
                    ? null
                    : () => onMinistry!(member!.ministryId!),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _MemberShortcut(
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              subtitle: 'View your identity, formation and assignment record',
              onTap: onMyProfile,
            ),
            if (communitySuperior) ...[
              const SizedBox(height: AppSpacing.sm),
              _CommunityAdministrationCard(
                onAddEvent: onAddCommunityEvent,
                onPlanEvent: onPlanCommunityEvent,
                onMinutes: onCommunityMeetingMinutes,
              ),
              const SizedBox(height: AppSpacing.sm),
              _MemberShortcut(
                icon: Icons.event_outlined,
                title: 'Community Calendar',
                subtitle: 'Community celebrations and approved events',
                onTap: () => onNavigate(AppDestination.calendar),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MemberShortcut(
                icon: Icons.folder_shared_outlined,
                title: 'Community Documents',
                subtitle: 'Shared community leadership documents',
                onTap: () => onNavigate(AppDestination.documents),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _MemberShortcut(
              icon: Icons.auto_awesome_outlined,
              title: 'Ask Communio',
              subtitle: 'Search member-safe institutional information',
              onTap: () => onNavigate(AppDestination.askCommunio),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MemberShortcut(
              icon: Icons.calendar_month_outlined,
              title: 'Shared Calendar',
              subtitle: 'Province events, celebrations and community feasts',
              onTap: () => onNavigate(AppDestination.calendar),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MemberShortcut(
              icon: Icons.church_outlined,
              title: 'Congregation & Province',
              subtitle: 'Identity, mission and current leadership',
              onTap: () => onNavigate(AppDestination.congregationProfile),
            ),
          ],
        ),
      );
    },
  );

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _dateLabel(DateTime date) =>
      '${const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1]}, '
      '${date.day} ${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1]} ${date.year}';
}

class _CommunityAdministrationCard extends StatelessWidget {
  const _CommunityAdministrationCard({
    this.onAddEvent,
    this.onPlanEvent,
    this.onMinutes,
  });
  final VoidCallback? onAddEvent;
  final VoidCallback? onPlanEvent;
  final VoidCallback? onMinutes;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMUNITY ADMINISTRATION',
          style: AppTypography.responsive(context).labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AdministrationAction(
          icon: Icons.event_available_outlined,
          label: 'Add Calendar Event',
          color: AppColors.info,
          onTap: onAddEvent,
        ),
        _AdministrationAction(
          icon: Icons.edit_calendar_outlined,
          label: 'Plan Community Event',
          color: AppColors.purple,
          onTap: onPlanEvent,
        ),
        _AdministrationAction(
          icon: Icons.description_outlined,
          label: 'Meeting Minutes',
          color: AppColors.secondaryDark,
          onTap: onMinutes,
        ),
      ],
    ),
  );
}

class _AdministrationAction extends StatelessWidget {
  const _AdministrationAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      minTileHeight: 52,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _MemberCelebrationsCard extends StatelessWidget {
  const _MemberCelebrationsCard({
    required this.repository,
    required this.title,
    this.onMember,
  });

  final MemberCelebrationsRepository repository;
  final ValueChanged<String>? onMember;
  final String title;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<MemberCelebration>>(
    future: repository.fetchToday(),
    builder: (context, snapshot) {
      final items = snapshot.data ?? const <MemberCelebration>[];
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.celebration_outlined,
                  color: AppColors.secondaryDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.responsive(context).labelLarge
                        .copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
              ],
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No celebrations today.',
                  style: AppTypography.responsive(
                    context,
                  ).bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              for (final item in items)
                _CelebrationRow(item: item, onMember: onMember),
          ],
        ),
      );
    },
  );
}

class _CommunityTodayCard extends StatelessWidget {
  const _CommunityTodayCard({required this.repository, this.communityName});
  final ProvinceRepository repository;
  final String? communityName;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: repository.fetchCommunities(),
    builder: (context, snapshot) {
      final communities = snapshot.data ?? const [];
      final community = communities
          .where((item) => item.name == communityName)
          .firstOrNull;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MY COMMUNITY TODAY',
              style: AppTypography.responsive(context).labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (community == null)
              Text(
                'Community information is unavailable.',
                style: AppTypography.responsive(context).bodyMedium,
              )
            else
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.sm,
                children: [
                  _TodayMetric(
                    label: 'Current residents',
                    value: '${community.residentCount}',
                  ),
                  _TodayMetric(
                    label: 'Linked ministries',
                    value: '${community.ministries.length}',
                  ),
                  const _TodayMetric(
                    label: 'Today’s celebrations',
                    value: 'See above',
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: AppTypography.responsive(
          context,
        ).titleLarge.copyWith(color: AppColors.primary),
      ),
      Text(
        label,
        style: AppTypography.responsive(
          context,
        ).bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _CelebrationRow extends StatelessWidget {
  const _CelebrationRow({required this.item, this.onMember});

  final MemberCelebration item;
  final ValueChanged<String>? onMember;

  IconData get _icon => switch (item.type) {
    MemberCelebrationType.birthday => Icons.cake_outlined,
    MemberCelebrationType.feastDay => Icons.auto_awesome_outlined,
    MemberCelebrationType.firstProfession => Icons.diamond_outlined,
    MemberCelebrationType.perpetualProfession =>
      Icons.workspace_premium_outlined,
    MemberCelebrationType.ordination => Icons.church_outlined,
  };

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.transparent,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.dashboardWarmCream,
        foregroundImage: item.photoUrl == null
            ? null
            : NetworkImage(item.photoUrl!),
        child: item.photoUrl == null
            ? const Icon(Icons.person_outline, color: AppColors.primary)
            : null,
      ),
      title: Text(item.displayName),
      subtitle: Row(
        children: [
          Icon(_icon, size: 16, color: AppColors.secondaryDark),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text('${item.typeLabel} · Today')),
        ],
      ),
      trailing: onMember == null
          ? null
          : const Icon(Icons.chevron_right_rounded),
      onTap: onMember == null ? null : () => onMember!(item.memberId),
    ),
  );
}

class _MemberShortcut extends StatelessWidget {
  const _MemberShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
