import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/contact_action_button.dart';
import '../../../core/widgets/module_background.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../religious_directory/models/member_directory_entry.dart';
import '../data/province_repository.dart';
import '../models/province_models.dart';

typedef MemberOpener = void Function(MemberDirectoryEntry member);

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({
    required this.repository,
    required this.onMember,
    super.key,
  });
  final ProvinceRepository repository;
  final MemberOpener onMember;
  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  String query = '';
  String filter = 'all';
  @override
  Widget build(BuildContext context) => _Loader<List<CommunityRecord>>(
    load: widget.repository.fetchCommunities,
    emptyTitle: 'No communities available',
    builder: (items) {
      final visible = items.where((community) {
        final matchesQuery =
            '${community.name} ${community.superior ?? ''} ${community.accountant ?? ''}'
                .toLowerCase()
                .contains(query);
        final name = community.name.trim().toLowerCase();
        final type = (community.type ?? '').toLowerCase();

        final isFormation =
            const {
              'mary immaculate novitiate',
              'st. antony scholasticate',
              'vidhya deep theologate',
              'st. antony vocation house',
            }.contains(name) ||
            type.contains('formation') ||
            type.contains('novitiate') ||
            type.contains('scholastic') ||
            type.contains('theologate') ||
            type.contains('vocation');

        final isGovernance =
            name == 'provincial house' ||
            type.contains('governance') ||
            type.contains('provincial administration');

        final isMinistry =
            !isFormation && !isGovernance && community.ministries.isNotEmpty;

        final matchesFilter = switch (filter) {
          'formation' => isFormation,
          'ministry' => isMinistry,
          _ => true,
        };
        return matchesQuery && matchesFilter;
      }).toList();
      return _ListingPage(
        title: 'Communities',
        subtitle: '${visible.length} of ${items.length} communities',
        accent: AppColors.warning,
        queryHint: 'Search communities',
        onQuery: (value) => setState(() => query = value.trim().toLowerCase()),
        filters: [
          _FilterOption('all', 'All'),
          _FilterOption('formation', 'Formation\nCommunities'),
          _FilterOption('ministry', 'Ministry\nCommunities'),
        ],
        selectedFilter: filter,
        onFilter: (value) => setState(() => filter = value),
        emptyMessage: 'No communities match this search or filter.',
        children: visible
            .map(
              (community) => _CommunitySnapshotCard(
                community: community,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CommunityDetailScreen(
                      community: community,
                      onMember: (member) {
                        Navigator.of(context).pop();
                        widget.onMember(member);
                      },
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class CommunityDetailScreen extends StatelessWidget {
  const CommunityDetailScreen({
    required this.community,
    required this.onMember,
    super.key,
  });
  final CommunityRecord community;
  final MemberOpener onMember;
  @override
  Widget build(BuildContext context) {
    final leadership = _CommunityLeadershipSection(
      community: community,
      onMember: onMember,
    );
    final residents = _Section(
      title: 'Current Residents (${community.residents.length})',
      child: _PeopleList(
        people: community.residents,
        onMember: onMember,
        alternateColors: true,
      ),
    );
    final away = _CommunityAwaySection(
      movements: community.currentMovements,
      onMember: onMember,
    );
    final glance = _CommunityGlance(community: community);
    final ministries = _CommunityMinistriesSection(
      ministries: community.ministryRecords,
      onTap: (ministry) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MinistryDetailScreen(ministry: ministry, onMember: onMember),
        ),
      ),
    );
    return _DetailScaffold(
      title: community.name,
      children: [
        _ResponsiveCover(
          imageUrl: community.coverImageUrl,
          label: community.name,
          fallbackIcon: Icons.home_work_outlined,
        ),
        _CommunityHero(community: community),
        LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            if (!desktop) {
              return Column(
                children: [
                  glance,
                  const SizedBox(height: AppSpacing.md),
                  leadership,
                  if (community.currentMovements.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    away,
                  ],
                  const SizedBox(height: AppSpacing.md),
                  residents,
                  if (community.ministryRecords.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    ministries,
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      leadership,
                      if (community.currentMovements.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        away,
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      residents,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      glance,
                      if (community.ministryRecords.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        ministries,
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        _CommunityHistory(community: community, onMember: onMember),
      ],
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({required this.community});
  final CommunityRecord community;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.surface, AppColors.secondary.withValues(alpha: .07)],
      ),
      border: Border.all(color: AppColors.secondary.withValues(alpha: .22)),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              community.name,
              style: AppTypography.responsive(
                context,
              ).headlineMedium.copyWith(color: AppColors.primary),
            ),
            _StatusBadge(
              (community.communityCategory ?? community.type ?? 'Community')
                  .toUpperCase(),
              switch ((community.communityCategory ?? '').toLowerCase()) {
                'formation' => AppColors.cyan,
                'ministry' => AppColors.success,
                'governance' => AppColors.secondaryDark,
                _ => AppColors.primary,
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (_hasText(community.type))
              _SnapshotChip(
                Icons.category_outlined,
                community.type!,
                AppColors.primary,
              ),
            if (_hasText(community.location))
              _SnapshotChip(
                Icons.location_on_outlined,
                community.location!,
                AppColors.warning,
              ),
            if (community.establishedYear != null)
              _SnapshotChip(
                Icons.event_outlined,
                'Opened ${community.establishedYear}',
                AppColors.secondaryDark,
              ),
            _SnapshotChip(
              Icons.groups_2_outlined,
              '${community.residentCount} Residents',
              AppColors.info,
            ),
            _SnapshotChip(
              Icons.volunteer_activism_outlined,
              '${community.ministryRecords.length} Ministries',
              AppColors.success,
            ),
          ],
        ),
        if (_hasText(community.phone) || _hasText(community.email)) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (_hasText(community.phone))
                ContactActionButton(
                  type: ContactActionType.call,
                  value: community.phone!,
                  personName: community.name,
                ),
              if (_hasText(community.email))
                ContactActionButton(
                  type: ContactActionType.email,
                  value: community.email!,
                  personName: community.name,
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _CommunityLeadershipSection extends StatelessWidget {
  const _CommunityLeadershipSection({
    required this.community,
    required this.onMember,
  });
  final CommunityRecord community;
  final MemberOpener onMember;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Leadership',
    child: Column(
      children: [
        _CommunityLeadershipRow(
          label: 'Superior',
          name: community.superior,
          person: community.superiorPerson,
          color: AppColors.secondaryDark,
          onTap: community.superiorPerson == null
              ? null
              : () => onMember(_entry(community.superiorPerson!)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _CommunityLeadershipRow(
          label: 'Accountant',
          name: community.accountant,
          person: community.accountantPerson,
          color: AppColors.purple,
          onTap: community.accountantPerson == null
              ? null
              : () => onMember(_entry(community.accountantPerson!)),
        ),
      ],
    ),
  );
}

class _CommunityGlance extends StatelessWidget {
  const _CommunityGlance({required this.community});
  final CommunityRecord community;
  @override
  Widget build(BuildContext context) {
    final priests = community.residents
        .where((p) => p.name.startsWith('Fr.'))
        .length;
    final brothers = community.residents
        .where((p) => p.name.startsWith('Bro.'))
        .length;
    final years = community.establishedYear == null
        ? null
        : DateTime.now().year - community.establishedYear!;
    return _Section(
      title: 'At a Glance',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _SnapshotChip(
            Icons.groups_2_outlined,
            '${community.residentCount} Residents',
            AppColors.info,
          ),
          _SnapshotChip(
            Icons.person_outline,
            '$priests Priests',
            AppColors.primary,
          ),
          _SnapshotChip(
            Icons.person_2_outlined,
            '$brothers Brothers',
            AppColors.purple,
          ),
          _SnapshotChip(
            Icons.volunteer_activism_outlined,
            '${community.ministryRecords.length} Ministries',
            AppColors.success,
          ),
          if (community.currentMovements.isNotEmpty)
            _SnapshotChip(
              Icons.travel_explore_outlined,
              '${community.currentMovements.length} Away',
              AppColors.cyan,
            ),
          if (years != null)
            _SnapshotChip(
              Icons.history_outlined,
              '$years Years',
              AppColors.secondaryDark,
            ),
        ],
      ),
    );
  }
}

class _CommunityAwaySection extends StatelessWidget {
  const _CommunityAwaySection({
    required this.movements,
    required this.onMember,
  });
  final List<CommunityMovement> movements;
  final MemberOpener onMember;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Currently Away',
    child: Column(
      children: movements
          .map(
            (movement) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _movementIcon(movement.type),
                color: _movementColor(movement.type),
              ),
              title: Text(movement.person.name),
              subtitle: Text(
                '${movement.title}${movement.location == null ? '' : ' · ${movement.location}'}${movement.toDate == null ? '' : ' · Until ${_date(movement.toDate)}'}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onMember(_entry(movement.person)),
            ),
          )
          .toList(),
    ),
  );
}

class _CommunityMinistriesSection extends StatelessWidget {
  const _CommunityMinistriesSection({
    required this.ministries,
    required this.onTap,
  });
  final List<MinistryRecord> ministries;
  final ValueChanged<MinistryRecord> onTap;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Ministries',
    child: Column(
      children: ministries.map((ministry) {
        final leader = _operationalHeadAssignment(ministry);
        final figures = <String>[
          if (ministry.totalStudents case final value? when value > 0)
            '$value Students',
          if (ministry.totalBeneficiaries case final value? when value > 0)
            '$value Beneficiaries',
          if (ministry.totalStaff case final value? when value > 0)
            '$value Staff',
        ];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_ministryIcon(ministry.type), color: AppColors.success),
          title: Text(ministry.name),
          subtitle: Text(
            [
              if (ministry.type != null) ministry.type!,
              ...figures,
              if (leader != null)
                '${leader.role ?? 'Responsible'}: ${leader.person.name}',
            ].join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onTap(ministry),
        );
      }).toList(),
    ),
  );
}

class _CommunityHistory extends StatelessWidget {
  const _CommunityHistory({required this.community, required this.onMember});

  final CommunityRecord community;
  final MemberOpener onMember;

  bool get _hasIdentity =>
      _hasText(community.patronSaintName) ||
      community.feastDay != null ||
      community.feastMonth != null ||
      _hasText(community.motto) ||
      _hasText(community.missionStatement) ||
      _hasText(community.visionStatement) ||
      community.apostolicFocus.isNotEmpty ||
      community.communityValues.isNotEmpty;

  bool get _hasStory =>
      _hasText(community.foundingStory) || _hasText(community.historySummary);

  String? get _feastDay {
    final day = community.feastDay;
    final month = community.feastMonth;

    if (day == null || month == null || month < 1 || month > 12) {
      return null;
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '$day ${months[month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    // Preserve the complete residence history. Current residents already
    // appear in the Current Residents section, so membership history below
    // focuses on completed/past residence assignments.
    final membershipHistory = community.history
        .where((assignment) => !assignment.current)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasIdentity) ...[
          _Section(
            title: 'Community Identity & Mission',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasText(community.patronSaintName) || _feastDay != null)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (_hasText(community.patronSaintName))
                        _CommunityProfileChip(
                          icon: Icons.church_outlined,
                          label: 'Patron Saint',
                          value: community.patronSaintName!,
                          color: AppColors.secondaryDark,
                        ),
                      if (_feastDay != null)
                        _CommunityProfileChip(
                          icon: Icons.celebration_outlined,
                          label: 'Community Feast',
                          value: _feastDay!,
                          color: AppColors.purple,
                        ),
                    ],
                  ),

                if ((_hasText(community.patronSaintName) ||
                        _feastDay != null) &&
                    (_hasText(community.motto) ||
                        _hasText(community.missionStatement) ||
                        _hasText(community.visionStatement) ||
                        community.apostolicFocus.isNotEmpty ||
                        community.communityValues.isNotEmpty))
                  const SizedBox(height: AppSpacing.lg),

                if (_hasText(community.motto))
                  _CommunityProfileTextBlock(
                    title: 'Motto',
                    text: community.motto!,
                    icon: Icons.format_quote_rounded,
                    color: AppColors.secondaryDark,
                    italic: true,
                  ),

                if (_hasText(community.missionStatement)) ...[
                  if (_hasText(community.motto))
                    const SizedBox(height: AppSpacing.md),
                  _CommunityProfileTextBlock(
                    title: 'Mission',
                    text: community.missionStatement!,
                    icon: Icons.explore_outlined,
                    color: AppColors.info,
                  ),
                ],

                if (_hasText(community.visionStatement)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _CommunityProfileTextBlock(
                    title: 'Vision',
                    text: community.visionStatement!,
                    icon: Icons.visibility_outlined,
                    color: AppColors.purple,
                  ),
                ],

                if (community.apostolicFocus.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Apostolic Focus',
                    style: AppTypography.responsive(context).labelLarge
                        .copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: community.apostolicFocus
                        .map(
                          (value) => _CommunityValueChip(
                            value: value,
                            icon: Icons.volunteer_activism_outlined,
                            color: AppColors.success,
                          ),
                        )
                        .toList(),
                  ),
                ],

                if (community.communityValues.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Community Values',
                    style: AppTypography.responsive(context).labelLarge
                        .copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: community.communityValues
                        .map(
                          (value) => _CommunityValueChip(
                            value: value,
                            icon: Icons.favorite_outline_rounded,
                            color: AppColors.secondaryDark,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (_hasStory) ...[
          _Section(
            title: 'Our Story',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasText(community.foundingStory))
                  _CommunityStoryBlock(
                    title: 'Founding Story',
                    text: community.foundingStory!,
                    icon: Icons.auto_stories_outlined,
                  ),
                if (_hasText(community.foundingStory) &&
                    _hasText(community.historySummary))
                  const SizedBox(height: AppSpacing.lg),
                if (_hasText(community.historySummary))
                  _CommunityStoryBlock(
                    title: 'Historical Perspective',
                    text: community.historySummary!,
                    icon: Icons.history_edu_outlined,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        _Section(
          title: 'Community History',
          child: community.lifecycleEvents.isEmpty
              ? Text(
                  'No lifecycle events are recorded.',
                  style: AppTypography.responsive(
                    context,
                  ).bodySmall.copyWith(color: AppColors.textSecondary),
                )
              : Column(
                  children: community.lifecycleEvents.map((event) {
                    final when = event.datePrecisionCode == 'YEAR'
                        ? event.effectiveDate.year.toString()
                        : _date(event.effectiveDate);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        event.typeCode == 'CLOSED'
                            ? Icons.door_back_door_outlined
                            : event.typeCode == 'REOPENED'
                            ? Icons.lock_open_rounded
                            : Icons.history_toggle_off_rounded,
                        color: event.typeCode == 'CLOSED'
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      title: Text(event.typeLabel),
                      subtitle: Text(when),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        _Section(
          title: 'Community Membership History',
          child: membershipHistory.isEmpty
              ? Text(
                  'No previous community residence assignments are recorded.',
                  style: AppTypography.responsive(
                    context,
                  ).bodySmall.copyWith(color: AppColors.textSecondary),
                )
              : Column(
                  children: membershipHistory.map((assignment) {
                    final range = [
                      if (assignment.fromDate != null)
                        _date(assignment.fromDate),
                      if (assignment.toDate != null) _date(assignment.toDate),
                    ].join(' – ');

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: MemberAvatar(
                        name: assignment.person.name,
                        photoUrl: assignment.person.photoUrl,
                        radius: 25,
                        backgroundColor: AppColors.surface,
                      ),
                      title: Text(
                        assignment.person.name,
                        style: AppTypography.responsive(context).labelLarge
                            .copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      subtitle: Text(
                        [
                          if (_hasText(assignment.role)) assignment.role!,
                          if (range.isNotEmpty) range,
                        ].join(' · '),
                        style: AppTypography.responsive(
                          context,
                        ).bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.info,
                      ),
                      onTap: () => onMember(_entry(assignment.person)),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _CommunityProfileChip extends StatelessWidget {
  const _CommunityProfileChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: color.withValues(alpha: .14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.responsive(
                context,
              ).labelSmall.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: AppTypography.responsive(
                context,
              ).labelLarge.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CommunityProfileTextBlock extends StatelessWidget {
  const _CommunityProfileTextBlock({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
    this.italic = false,
  });

  final String title;
  final String text;
  final IconData icon;
  final Color color;
  final bool italic;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: color.withValues(alpha: .10)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.responsive(context).labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                text,
                style: AppTypography.responsive(context).bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.45,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CommunityValueChip extends StatelessWidget {
  const _CommunityValueChip({
    required this.value,
    required this.icon,
    required this.color,
  });

  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: AppTypography.responsive(
            context,
          ).labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _CommunityStoryBlock extends StatelessWidget {
  const _CommunityStoryBlock({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.secondaryDark, size: 20),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.responsive(context).labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              text,
              style: AppTypography.responsive(
                context,
              ).bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    ],
  );
}

IconData _movementIcon(String type) => switch (type) {
  'travel' => Icons.flight_outlined,
  'retreat' => Icons.self_improvement_outlined,
  'training' => Icons.workspace_premium_outlined,
  'study' => Icons.school_outlined,
  'home_leave' => Icons.home_outlined,
  _ => Icons.travel_explore_outlined,
};

Color _movementColor(String type) => switch (type) {
  'home_leave' => AppColors.warning,
  'retreat' => AppColors.secondaryDark,
  'travel' || 'training' || 'study' => AppColors.cyan,
  _ => AppColors.primary,
};

class MinistriesScreen extends StatefulWidget {
  const MinistriesScreen({
    required this.repository,
    required this.onMember,
    super.key,
  });
  final ProvinceRepository repository;
  final MemberOpener onMember;
  @override
  State<MinistriesScreen> createState() => _MinistriesScreenState();
}

class _MinistriesScreenState extends State<MinistriesScreen> {
  String query = '';
  String group = 'all';
  String? type;
  String? community;
  @override
  Widget build(BuildContext context) => _Loader<List<MinistryRecord>>(
    load: widget.repository.fetchMinistries,
    emptyTitle: 'No ministries available',
    builder: (items) {
      final types =
          items.map((e) => e.type).whereType<String>().toSet().toList()..sort();
      final communities =
          items.map((e) => e.community).whereType<String>().toSet().toList()
            ..sort();
      final visible = items.where((ministry) {
        final matchesQuery =
            '${ministry.name} ${ministry.type ?? ''} ${ministry.community ?? ''} ${ministry.location ?? ''} ${ministry.headName ?? ''} ${ministry.affiliationAuthority ?? ''} ${ministry.programsServices ?? ''} ${ministry.currentAssignments.map((e) => e.person.name).join(' ')}'
                .toLowerCase()
                .contains(query);
        final matchesGroup =
            group == 'all' || ministryListingGroup(ministry.type) == group;
        return matchesQuery &&
            matchesGroup &&
            (type == null || ministry.type == type) &&
            (community == null || ministry.community == community);
      }).toList();
      return _ListingPage(
        title: 'Ministries',
        subtitle: '${visible.length} of ${items.length} ministries',
        accent: AppColors.success,
        queryHint: 'Search ministries',
        onQuery: (value) => setState(() => query = value.trim().toLowerCase()),
        filters: const [
          _FilterOption('all', 'All'),
          _FilterOption('education', 'Education'),
          _FilterOption('pastoral', 'Pastoral'),
          _FilterOption('social_health', 'Social / Health'),
          _FilterOption('formation', 'Formation'),
        ],
        selectedFilter: group,
        onFilter: (value) => setState(() => group = value),
        extraFilters: [
          _CompactDropdown(
            label: 'Category',
            value: type,
            values: types,
            onChanged: (value) => setState(() => type = value),
          ),
          _CompactDropdown(
            label: 'Community',
            value: community,
            values: communities,
            onChanged: (value) => setState(() => community = value),
          ),
        ],
        emptyMessage: 'No ministries match this search or filter.',
        children: visible
            .map(
              (ministry) => _MinistrySnapshotCard(
                ministry: ministry,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MinistryDetailScreen(
                      ministry: ministry,
                      onMember: (member) {
                        Navigator.of(context).pop();
                        widget.onMember(member);
                      },
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class MinistryDetailScreen extends StatelessWidget {
  const MinistryDetailScreen({
    required this.ministry,
    required this.onMember,
    super.key,
  });
  final MinistryRecord ministry;
  final MemberOpener onMember;
  @override
  Widget build(BuildContext context) => _DetailScaffold(
    title: ministry.name,
    children: [
      _ResponsiveCover(
        imageUrl: ministry.coverImageUrl,
        label: ministry.name,
        fallbackIcon: _ministryIcon(ministry.type),
      ),
      _MinistryDetailOverview(ministry: ministry),
      _MinistryLeadershipPanel(ministry: ministry, onMember: onMember),
      _MinistryOperationsPanel(ministry: ministry),
      if (_hasText(ministry.programsServices))
        _Section(
          title: 'Programs & services',
          child: Text(ministry.programsServices!),
        ),
      if (_hasMinistryIdentity(ministry))
        _MinistryIdentityPanel(ministry: ministry),
      if (_hasMinistryStory(ministry)) _MinistryStoryPanel(ministry: ministry),
      if (_hasContact(ministry)) _MinistryContactPanel(ministry: ministry),
      _Section(
        title:
            'Religious currently assigned (${ministry.currentAssignments.length})',
        child: _AssignmentsList(
          assignments: ministry.currentAssignments,
          onMember: onMember,
        ),
      ),
      _Section(
        title: 'Ministry Assignment History',
        child: _AssignmentsList(
          assignments: ministry.assignments.where((a) => !a.current).toList(),
          onMember: onMember,
        ),
      ),
    ],
  );
}

class _MinistryDetailOverview extends StatelessWidget {
  const _MinistryDetailOverview({required this.ministry});
  final MinistryRecord ministry;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Ministry overview',
    child: Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        if (_isInactiveMinistry(ministry.status))
          _StatusBadge(
            ministry.status!,
            _operationalStatusColor(ministry.status),
          ),
        if (ministry.type != null)
          _SnapshotChip(
            _ministryIcon(ministry.type),
            ministry.type!,
            ministryListingAccent(ministry.type),
          ),
        if (ministry.community != null)
          _SnapshotChip(
            Icons.home_work_outlined,
            ministry.community!,
            AppColors.info,
          ),
        if (_hasText(ministry.location))
          _SnapshotChip(
            Icons.location_on_outlined,
            ministry.location!,
            AppColors.secondaryDark,
          ),
        if (ministry.yearEstablished != null)
          _SnapshotChip(
            Icons.event_outlined,
            'Established ${ministry.yearEstablished}',
            AppColors.purple,
          ),
      ],
    ),
  );
}

class _MinistryLeadershipPanel extends StatelessWidget {
  const _MinistryLeadershipPanel({
    required this.ministry,
    required this.onMember,
  });
  final MinistryRecord ministry;
  final MemberOpener onMember;
  @override
  Widget build(BuildContext context) {
    final leader = _operationalHeadAssignment(ministry);
    final headName = _displayedMinistryHead(ministry, leader);
    final headRole = leader?.role ?? ministry.headRole;
    return _Section(
      title: 'Leadership',
      child: headName == null
          ? const Text('No current head is recorded for this ministry.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final person = leader?.person ?? ministry.headPerson;
                final subtitle =
                    '${headRole ?? 'Responsible person'}${leader?.fromDate == null ? '' : ' · Since ${_date(leader!.fromDate)}'}';
                final avatar = leader == null && ministry.headPerson == null
                    ? MemberAvatar(
                        name: headName,
                        radius: 28,
                        backgroundColor: AppColors.success.withValues(
                          alpha: .1,
                        ),
                      )
                    : _Avatar(person!);
                if (constraints.maxWidth < 600) {
                  final actions = _contactActions(person);
                  return InkWell(
                    onTap: person == null
                        ? null
                        : () => onMember(_entry(person)),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          avatar,
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  headName,
                                  style: AppTypography.responsive(context)
                                      .titleSmall
                                      .copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  subtitle,
                                  style: AppTypography.responsive(context)
                                      .bodySmall
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                                if (actions.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: actions,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (person != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: avatar,
                  title: Text(headName),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._contactActions(person),
                      if (person != null) const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: person == null ? null : () => onMember(_entry(person)),
                );
              },
            ),
    );
  }
}

class _MinistryOperationsPanel extends StatelessWidget {
  const _MinistryOperationsPanel({required this.ministry});
  final MinistryRecord ministry;
  @override
  Widget build(BuildContext context) {
    final metrics = _operationalMetrics(ministry);
    return _Section(
      title: 'Operational statistics',
      child: metrics.isEmpty && !_hasText(ministry.affiliationAuthority)
          ? const Text('No operational statistics are currently recorded.')
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ...metrics.map(
                  (m) => _SnapshotChip(
                    m.icon,
                    '${m.label}: ${_number(m.value)}',
                    m.color,
                  ),
                ),
                if (_hasText(ministry.affiliationAuthority))
                  _SnapshotChip(
                    Icons.verified_outlined,
                    ministry.affiliationAuthority!,
                    AppColors.info,
                  ),
              ],
            ),
    );
  }
}

bool _hasMinistryIdentity(MinistryRecord ministry) =>
    _hasText(ministry.patronSaintName) ||
    (ministry.feastDay != null && ministry.feastMonth != null) ||
    _hasText(ministry.motto) ||
    _hasText(ministry.missionStatement) ||
    _hasText(ministry.visionStatement) ||
    ministry.apostolicFocus.isNotEmpty ||
    ministry.ministryValues.isNotEmpty;

bool _hasMinistryStory(MinistryRecord ministry) =>
    _hasText(ministry.foundingStory) || _hasText(ministry.historySummary);

String? _ministryFeastDay(MinistryRecord ministry) {
  final day = ministry.feastDay;
  final month = ministry.feastMonth;
  if (day == null || month == null || month < 1 || month > 12) return null;
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '$day ${months[month - 1]}';
}

class _MinistryIdentityPanel extends StatelessWidget {
  const _MinistryIdentityPanel({required this.ministry});
  final MinistryRecord ministry;

  @override
  Widget build(BuildContext context) {
    final feastDay = _ministryFeastDay(ministry);
    return _Section(
      title: 'Ministry Identity & Mission',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasText(ministry.patronSaintName) || feastDay != null)
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (_hasText(ministry.patronSaintName))
                    _MinistryPatronTile(
                      value: ministry.patronSaintName!,
                      maxWidth: constraints.maxWidth,
                    ),
                  if (feastDay != null)
                    _CommunityProfileChip(
                      icon: Icons.celebration_outlined,
                      label: 'Feast Day',
                      value: feastDay,
                      color: AppColors.purple,
                    ),
                ],
              ),
            ),
          if ((_hasText(ministry.patronSaintName) || feastDay != null) &&
              (_hasText(ministry.motto) ||
                  _hasText(ministry.missionStatement) ||
                  _hasText(ministry.visionStatement) ||
                  ministry.apostolicFocus.isNotEmpty ||
                  ministry.ministryValues.isNotEmpty))
            const SizedBox(height: AppSpacing.lg),
          if (_hasText(ministry.motto))
            _CommunityProfileTextBlock(
              title: 'Motto',
              text: ministry.motto!,
              icon: Icons.format_quote_rounded,
              color: AppColors.secondaryDark,
              italic: true,
            ),
          if (_hasText(ministry.missionStatement)) ...[
            if (_hasText(ministry.motto)) const SizedBox(height: AppSpacing.md),
            _CommunityProfileTextBlock(
              title: 'Mission',
              text: ministry.missionStatement!,
              icon: Icons.explore_outlined,
              color: AppColors.info,
            ),
          ],
          if (_hasText(ministry.visionStatement)) ...[
            const SizedBox(height: AppSpacing.md),
            _CommunityProfileTextBlock(
              title: 'Vision',
              text: ministry.visionStatement!,
              icon: Icons.visibility_outlined,
              color: AppColors.purple,
            ),
          ],
          if (ministry.apostolicFocus.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _MinistryValueGroup(
              title: 'Apostolic Focus',
              values: ministry.apostolicFocus,
              icon: Icons.explore_outlined,
              color: AppColors.info,
            ),
          ],
          if (ministry.ministryValues.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _MinistryValueGroup(
              title: 'Ministry Values',
              values: ministry.ministryValues,
              icon: Icons.favorite_outline_rounded,
              color: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _MinistryPatronTile extends StatelessWidget {
  const _MinistryPatronTile({required this.value, required this.maxWidth});

  final String value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryDark.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.secondaryDark.withValues(alpha: .16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.church_outlined,
                size: 18,
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Patron / Dedication',
                    style: AppTypography.responsive(
                      context,
                    ).labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    softWrap: true,
                    style: AppTypography.responsive(context).labelLarge
                        .copyWith(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MinistryValueGroup extends StatelessWidget {
  const _MinistryValueGroup({
    required this.title,
    required this.values,
    required this.icon,
    required this.color,
  });
  final String title;
  final List<String> values;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTypography.responsive(context).labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: values
            .map(
              (value) =>
                  _CommunityValueChip(value: value, icon: icon, color: color),
            )
            .toList(),
      ),
    ],
  );
}

class _MinistryStoryPanel extends StatelessWidget {
  const _MinistryStoryPanel({required this.ministry});
  final MinistryRecord ministry;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Our Story',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasText(ministry.foundingStory))
          _MinistryStoryBlock(
            title: 'Founding Story',
            text: ministry.foundingStory!,
            icon: Icons.auto_stories_outlined,
          ),
        if (_hasText(ministry.foundingStory) &&
            _hasText(ministry.historySummary))
          const SizedBox(height: AppSpacing.lg),
        if (_hasText(ministry.historySummary))
          _MinistryStoryBlock(
            title: 'Historical Perspective',
            text: ministry.historySummary!,
            icon: Icons.history_edu_outlined,
          ),
      ],
    ),
  );
}

class _MinistryStoryBlock extends StatelessWidget {
  const _MinistryStoryBlock({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.secondaryDark, size: 20),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.responsive(context).labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              style: AppTypography.responsive(context).bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MinistryContactPanel extends StatelessWidget {
  const _MinistryContactPanel({required this.ministry});
  final MinistryRecord ministry;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Contact details',
    child: Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        if (_hasText(ministry.phone))
          _SnapshotChip(Icons.phone_outlined, ministry.phone!, AppColors.info),
        if (_hasText(ministry.email))
          _SnapshotChip(
            Icons.email_outlined,
            ministry.email!,
            AppColors.purple,
          ),
        if (_hasText(ministry.website))
          _SnapshotChip(
            Icons.language_outlined,
            ministry.website!,
            AppColors.success,
          ),
      ],
    ),
  );
}

class FormationScreen extends StatelessWidget {
  const FormationScreen({
    required this.repository,
    required this.onMember,
    this.initialStage,
    super.key,
  });
  final ProvinceRepository repository;
  final MemberOpener onMember;
  final String? initialStage;
  @override
  Widget build(BuildContext context) => _Loader<List<Object?>>(
    load: () async {
      final results = await Future.wait([
        repository.fetchFormation(),
        repository.fetchMinistries(),
      ]);
      return results;
    },
    emptyTitle: 'No one is currently in formation',
    builder: (data) {
      final items = data[0] as List<FormationMember>;
      final ministries = data[1] as List<MinistryRecord>;
      final formationStaff = formationStaffFromMinistries(ministries);
      final stages = <String, List<FormationMember>>{};
      final houses = <String, List<FormationMember>>{};
      for (final item in items) {
        stages.putIfAbsent(item.stage, () => []).add(item);
        houses
            .putIfAbsent(item.house ?? 'Formation house not recorded', () => [])
            .add(item);
      }
      final visibleHouses =
          initialStage == null
                ? houses
                : {
                    for (final entry in houses.entries)
                      entry.key: entry.value
                          .where((m) => m.stage == initialStage)
                          .toList(),
                  }
            ..removeWhere((_, value) => value.isEmpty);
      final orderedHouses = visibleHouses.entries.toList()
        ..sort((a, b) {
          final priority = formationHouseDisplayPriority(
            a.key,
          ).compareTo(formationHouseDisplayPriority(b.key));
          return priority != 0 ? priority : 0;
        });
      final metrics = [
        (items.length, 'Total Formation'),
        (
          _formationStageCount(items, 'temporary professed'),
          'Temporary\nProfessed',
        ),
        (_formationStageCount(items, 'novice'), 'Novices'),
        (_formationStageCount(items, 'candidate'), 'Candidates'),
        (
          _formationStageCount(items, 'perpetual professed'),
          'Perpetual\nProfessed',
        ),
        (formationStaff.length, 'Formation\nStaff'),
      ];
      return _DirectoryPage(
        title: 'Formation',
        subtitle: 'The Province formation pipeline',
        header: _FormationSummary(metrics: metrics),
        children: orderedHouses
            .map(
              (entry) => Padding(
                key: Key(
                  'formation-house-spacing-${_formationHouseSlug(entry.key)}',
                ),
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _FormationHouseCard(
                  house: entry.key,
                  members: entry.value,
                  onMember: onMember,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

int formationHouseDisplayPriority(String house) =>
    switch (house.trim().toLowerCase()) {
      'vidhya deep theologate' => 0,
      'st. antony scholasticate' => 1,
      'mary immaculate novitiate' => 2,
      'st. antony vocation house' => 3,
      _ => 4,
    };

class _FormationHouseCard extends StatelessWidget {
  const _FormationHouseCard({
    required this.house,
    required this.members,
    required this.onMember,
  });

  final String house;
  final List<FormationMember> members;
  final MemberOpener onMember;

  @override
  Widget build(BuildContext context) {
    final style = _formationHouseStyle(house);
    final slug = _formationHouseSlug(house);
    return Container(
      key: Key('formation-house-card-$slug'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.color.withValues(alpha: .22)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                key: Key('formation-house-accent-$slug'),
                width: 4,
                color: style.color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormationHouseHeader(
                    house: house,
                    summary: _formationHouseSummary(members),
                    icon: style.icon,
                    accent: style.color,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Divider(height: 1, color: style.color.withValues(alpha: .16)),
                  for (var index = 0; index < members.length; index++) ...[
                    _FormationMemberRow(
                      member: members[index],
                      accent: style.color,
                      onMember: onMember,
                    ),
                    if (index < members.length - 1)
                      const Divider(height: 1, color: AppColors.divider),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationHouseHeader extends StatelessWidget {
  const _FormationHouseHeader({
    required this.house,
    required this.summary,
    required this.icon,
    required this.accent,
  });

  final String house;
  final String summary;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 21, color: accent),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              house,
              style: AppTypography.responsive(context).titleSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              summary,
              style: AppTypography.responsive(
                context,
              ).labelSmall.copyWith(color: accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FormationMemberRow extends StatelessWidget {
  const _FormationMemberRow({
    required this.member,
    required this.accent,
    required this.onMember,
  });

  final FormationMember member;
  final Color accent;
  final MemberOpener onMember;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: _Avatar(member.person),
    title: Text(
      member.person.name,
      style: AppTypography.responsive(context).bodyLarge.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(member.stage),
    trailing: Icon(Icons.chevron_right_rounded, color: accent),
    onTap: () => onMember(_entry(member.person)),
  );
}

({Color color, IconData icon}) _formationHouseStyle(String house) {
  final normalized = house.toLowerCase();
  if (normalized.contains('vocation')) {
    return (color: AppColors.warning, icon: Icons.person_search_outlined);
  }
  if (normalized.contains('novitiate')) {
    return (color: AppColors.purple, icon: Icons.self_improvement_outlined);
  }
  if (normalized.contains('scholasticate')) {
    return (color: AppColors.info, icon: Icons.school_outlined);
  }
  if (normalized.contains('theologate')) {
    return (color: AppColors.cyan, icon: Icons.menu_book_outlined);
  }
  return (color: AppColors.primary, icon: Icons.home_work_outlined);
}

String _formationHouseSummary(List<FormationMember> members) {
  final stages = members.map((member) => member.stage.trim()).toSet();
  if (stages.length != 1) return '${members.length} Members in Formation';
  final stage = stages.single;
  final label = switch (stage.toLowerCase()) {
    'candidate' => members.length == 1 ? 'Candidate' : 'Candidates',
    'novice' => members.length == 1 ? 'Novice' : 'Novices',
    _ => stage,
  };
  return '${members.length} $label';
}

String _formationHouseSlug(String house) => house
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

int _formationStageCount(List<FormationMember> members, String stage) =>
    members.where((member) => member.stage.toLowerCase() == stage).length;

List<ProvinceAssignment> formationStaffFromMinistries(
  List<MinistryRecord> ministries,
) {
  final staffByMember = <String, ProvinceAssignment>{};
  for (final ministry in ministries.where(_isFormationMinistry)) {
    for (final assignment in ministry.currentAssignments) {
      final memberId = assignment.person.id.trim();
      if (memberId.isEmpty || !_isFormationStaffRole(assignment.role)) continue;
      staffByMember.putIfAbsent(memberId, () => assignment);
    }
  }
  return staffByMember.values.toList()
    ..sort((a, b) => a.person.name.compareTo(b.person.name));
}

bool _isFormationMinistry(MinistryRecord ministry) {
  final identity = [
    ministry.name,
    ministry.type ?? '',
    ministry.community ?? '',
  ].join(' ').toLowerCase();
  return const [
    'formation',
    'aspiran',
    'postulan',
    'noviti',
    'scholastic',
    'vocation',
    'theolog',
  ].any(identity.contains);
}

bool _isFormationStaffRole(String? role) {
  final normalized = role
      ?.trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  return const {
    'formation director',
    'novice master',
    'scholastic master',
    'vocation promoter',
    'director',
    'administrator',
    'formation staff',
    'rector',
  }.contains(normalized);
}

class GovernanceScreen extends StatelessWidget {
  const GovernanceScreen({
    required this.repository,
    required this.onMember,
    super.key,
  });
  final ProvinceRepository repository;
  final MemberOpener onMember;
  @override
  Widget build(BuildContext context) => _Loader<List<Object?>>(
    load: () async {
      final current = await repository.fetchOfficeHolders();
      var past = <OfficeHolder>[];
      if (repository case final GovernanceHistoryRepository history) {
        try {
          past = await history.fetchPastProvincials();
        } catch (_) {
          past = const [];
        }
      }
      return [current, past];
    },
    emptyTitle: 'No current office holders',
    builder: (data) {
      final current = data[0] as List<OfficeHolder>;
      final past = pastProvincialsNewestFirst(data[1] as List<OfficeHolder>);
      final core = orderedCoreLeadership(current);
      final coreRecords = core.toSet();
      final other = current
          .where((office) => !coreRecords.contains(office))
          .toList();
      return _DirectoryPage(
        title: 'Governance',
        subtitle: 'Current leadership and institutional continuity',
        children: [
          _Section(
            title: 'Current Provincial Leadership',
            child: _GovernanceLeadershipList(offices: core, onMember: onMember),
          ),
          if (other.isNotEmpty)
            _Section(
              title: 'Other Provincial Offices',
              child: _GovernanceLeadershipList(
                offices: other,
                onMember: onMember,
                prominent: false,
              ),
            ),
          _Section(
            title: 'Past Provincials',
            child: _PastProvincialsList(offices: past, onMember: onMember),
          ),
        ],
      );
    },
  );
}

List<OfficeHolder> orderedCoreLeadership(List<OfficeHolder> offices) {
  final indexed =
      offices.indexed
          .where((entry) => governanceOfficePriority(entry.$2) < 6)
          .toList()
        ..sort((a, b) {
          final priority = governanceOfficePriority(
            a.$2,
          ).compareTo(governanceOfficePriority(b.$2));
          return priority != 0 ? priority : a.$1.compareTo(b.$1);
        });
  return indexed.map((entry) => entry.$2).toList();
}

int governanceOfficePriority(OfficeHolder office) {
  final value = (office.officeCode ?? office.office)
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  if (value == 'provincial') return 0;
  if (value.contains('assistant provincial')) return 1;
  if (value.contains('vice provincial')) return 2;
  if (value.contains('provincial councillor') ||
      value.contains('provincial councilor')) {
    return 3;
  }
  if (value.contains('provincial secretary')) return 4;
  if (value.contains('provincial bursar')) return 5;
  return 6;
}

List<OfficeHolder> pastProvincialsNewestFirst(List<OfficeHolder> offices) {
  final past = offices
      .where(
        (office) =>
            governanceOfficePriority(office) == 0 && office.toDate != null,
      )
      .toList();
  return past..sort(
    (a, b) => (b.toDate ?? DateTime(1)).compareTo(a.toDate ?? DateTime(1)),
  );
}

class _GovernanceLeadershipList extends StatelessWidget {
  const _GovernanceLeadershipList({
    required this.offices,
    required this.onMember,
    this.prominent = true,
  });

  final List<OfficeHolder> offices;
  final MemberOpener onMember;
  final bool prominent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 600;
      return Column(
        children: [
          for (var index = 0; index < offices.length; index++) ...[
            _GovernanceLeaderRow(
              office: offices[index],
              mobile: mobile,
              prominent: prominent,
              onTap: () => onMember(_entry(offices[index].person)),
            ),
            if (mobile && index < offices.length - 1)
              const Divider(height: AppSpacing.sm),
          ],
        ],
      );
    },
  );
}

class _GovernanceLeaderRow extends StatelessWidget {
  const _GovernanceLeaderRow({
    required this.office,
    required this.mobile,
    required this.prominent,
    required this.onTap,
  });

  final OfficeHolder office;
  final bool mobile;
  final bool prominent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _governanceOfficeAccent(office);
    if (!mobile) {
      return ListTile(
        leading: _Avatar(office.person),
        title: _GovernanceOfficeBadge(office: office, accent: accent),
        subtitle: Text(
          '${office.person.name}${office.fromDate == null ? '' : ' · Since ${_date(office.fromDate)}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._contactActions(office.person),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      );
    }

    final actions = _contactActions(office.person);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: prominent ? AppSpacing.md : AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(office.person),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office.office,
                        style: AppTypography.responsive(context).labelLarge
                            .copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        office.person.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.responsive(context).bodyMedium
                            .copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (office.fromDate != null)
                        Text(
                          'Since ${_date(office.fromDate)}',
                          style: AppTypography.responsive(
                            context,
                          ).bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: actions,
                        ),
                      ],
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GovernanceOfficeBadge extends StatelessWidget {
  const _GovernanceOfficeBadge({required this.office, required this.accent});
  final OfficeHolder office;
  final Color accent;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          office.office,
          style: AppTypography.responsive(
            context,
          ).labelSmall.copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

Color _governanceOfficeAccent(OfficeHolder office) =>
    switch (governanceOfficePriority(office)) {
      0 => AppColors.secondaryDark,
      1 || 2 => AppColors.primary,
      3 => AppColors.cyan,
      4 => AppColors.purple,
      5 => AppColors.success,
      _ => AppColors.textSecondary,
    };

class _PastProvincialsList extends StatelessWidget {
  const _PastProvincialsList({required this.offices, required this.onMember});
  final List<OfficeHolder> offices;
  final MemberOpener onMember;

  @override
  Widget build(BuildContext context) => offices.isEmpty
      ? const Text('No historical Provincial appointments available.')
      : Column(
          children: [
            for (var index = 0; index < offices.length; index++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _Avatar(offices[index].person),
                title: Text(
                  offices[index].person.name,
                  style: AppTypography.responsive(context).bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Provincial · ${_date(offices[index].fromDate)} – ${_date(offices[index].toDate)}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onMember(_entry(offices[index].person)),
              ),
              if (index < offices.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          ],
        );
}

class _EligibilityPanel extends StatefulWidget {
  const _EligibilityPanel({required this.repository, required this.onMember});
  final ProvinceRepository repository;
  final MemberOpener onMember;
  @override
  State<_EligibilityPanel> createState() => _EligibilityPanelState();
}

class _EligibilityPanelState extends State<_EligibilityPanel> {
  EligibilityRole? role;
  String status = 'ALL';
  @override
  Widget build(BuildContext context) => FutureBuilder<List<EligibilityRole>>(
    future: widget.repository.fetchEligibilityRoles(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const _Section(
          title: 'Leadership & Eligibility',
          child: LinearProgressIndicator(),
        );
      }
      if (snapshot.hasError) {
        return const _InfoPanel(
          title: 'Leadership & Eligibility',
          lines: ['Eligibility is temporarily unavailable. Please try again.'],
        );
      }
      final roles = snapshot.data!;
      role ??= roles.firstOrNull;
      if (role == null) {
        return const _InfoPanel(
          title: 'Leadership & Eligibility',
          lines: ['No eligibility roles are available.'],
        );
      }
      return _Section(
        title: 'Leadership & Eligibility',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: 280,
                  child: DropdownButton<EligibilityRole>(
                    isExpanded: true,
                    value: role,
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      role = value;
                      status = 'ALL';
                    }),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: status,
                    items:
                        const [
                              'ALL',
                              'ELIGIBLE',
                              'CONDITIONALLY ELIGIBLE',
                              'NOT ELIGIBLE',
                            ]
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s == 'ALL' ? 'All statuses' : _statusLabel(s),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => status = value!),
                  ),
                ),
              ],
            ),
            FutureBuilder<List<EligibilityRecord>>(
              future: widget.repository.fetchEligibility(
                role!.code,
                office: role!.office,
              ),
              builder: (context, results) {
                if (results.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: LinearProgressIndicator(),
                  );
                }
                if (results.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Candidate results are temporarily unavailable.',
                    ),
                  );
                }
                final records = results.data!
                    .where((r) => status == 'ALL' || r.status == status)
                    .toList();
                if (records.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('No candidates match this status.'),
                  );
                }
                return Column(
                  children: records
                      .map(
                        (r) => Card(
                          color: _statusColor(r.status).withValues(alpha: .06),
                          child: ListTile(
                            leading: _Avatar(r.person),
                            title: Text(
                              '${r.person.role == null ? '' : '${r.person.role} '}${r.person.name}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.reason ?? 'No reason supplied'),
                                ...r.indicators.map(
                                  (i) => Text(
                                    i,
                                    style: AppTypography.responsive(
                                      context,
                                    ).labelSmall,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(_statusLabel(r.status)),
                              backgroundColor: _statusColor(
                                r.status,
                              ).withValues(alpha: .14),
                            ),
                            onTap: () => widget.onMember(_entry(r.person)),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

// Retained as an isolated UI helper while compliance data remains available
// elsewhere; GovernanceScreen intentionally no longer instantiates it.
// ignore: unused_element
class _CompliancePanel extends StatelessWidget {
  const _CompliancePanel({required this.repository, required this.onMember});
  final ProvinceRepository repository;
  final MemberOpener onMember;
  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<AppointmentCompliance>>(
    future: repository.fetchAppointmentCompliance(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const _Section(
          title: 'Current Appointment Compliance',
          child: LinearProgressIndicator(),
        );
      }
      if (snapshot.hasError) {
        return const _InfoPanel(
          title: 'Current Appointment Compliance',
          lines: ['Compliance data is temporarily unavailable.'],
        );
      }
      final records = snapshot.data!;
      return _Section(
        title: 'Current Appointment Compliance · ${records.length}',
        child: Column(
          children: records
              .map(
                (r) => ListTile(
                  leading: Icon(
                    r.status == 'COMPLIANT'
                        ? Icons.verified_outlined
                        : Icons.warning_amber_rounded,
                    color: _statusColor(r.status),
                  ),
                  title: Text('${r.role} · ${r.person.name}'),
                  subtitle: Text(
                    '${_statusLabel(r.status)}${r.reason == null ? '' : ' · ${r.reason}'}',
                  ),
                  onTap: r.person.id.isEmpty
                      ? null
                      : () => onMember(_entry(r.person)),
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

String _statusLabel(String value) => value
    .split(' ')
    .map((p) => p.isEmpty ? p : '${p[0]}${p.substring(1).toLowerCase()}')
    .join(' ');
Color _statusColor(String value) => value == 'NOT ELIGIBLE'
    ? AppColors.error
    : value.contains('CONDITION') || value.contains('REVIEW')
    ? AppColors.warning
    : value == 'ELIGIBLE' || value == 'COMPLIANT'
    ? AppColors.success
    : AppColors.textSecondary;

class _Loader<T extends List<Object?>> extends StatefulWidget {
  const _Loader({
    required this.load,
    required this.builder,
    required this.emptyTitle,
  });
  final Future<T> Function() load;
  final Widget Function(T data) builder;
  final String emptyTitle;
  @override
  State<_Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T extends List<Object?>> extends State<_Loader<T>> {
  late Future<T> future = widget.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _StateMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load this section',
          message: 'Please check your connection and try again.',
          onRetry: () => setState(() => future = widget.load()),
        );
      }
      if (snapshot.data!.isEmpty) {
        return _StateMessage(
          icon: Icons.inbox_outlined,
          title: widget.emptyTitle,
          message: 'There is no current data to display.',
        );
      }
      return widget.builder(snapshot.data as T);
    },
  );
}

class _ListingPage extends StatelessWidget {
  const _ListingPage({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.queryHint,
    required this.onQuery,
    required this.filters,
    required this.selectedFilter,
    required this.onFilter,
    required this.children,
    required this.emptyMessage,
    this.extraFilters = const [],
  });
  final String title, subtitle, queryHint, selectedFilter, emptyMessage;
  final Color accent;
  final ValueChanged<String> onQuery, onFilter;
  final List<_FilterOption> filters;
  final List<Widget> extraFilters;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 680;
      final columns = constraints.maxWidth >= 1220
          ? 3
          : constraints.maxWidth >= 720
          ? 2
          : 1;
      final padding = mobile ? AppSpacing.lg : AppSpacing.xxxl;
      return Material(
        color: AppColors.transparent,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            padding,
            mobile ? AppSpacing.lg : AppSpacing.xxl,
            padding,
            AppSpacing.max,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: AppTypography.responsive(
                      context,
                    ).bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    title == 'Communities'
                        ? Icons.holiday_village_outlined
                        : Icons.volunteer_activism_outlined,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    onChanged: onQuery,
                    decoration: InputDecoration(
                      hintText: queryHint,
                      prefixIcon: Icon(Icons.search_rounded, color: accent),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.dashboardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...filters.map(
                        (f) => FilterChip(
                          label: Text(
                            f.label,
                            maxLines: 1,
                            style: AppTypography.responsive(
                              context,
                            ).labelSmall.copyWith(fontSize: mobile ? 13 : null),
                          ),
                          visualDensity: mobile
                              ? const VisualDensity(
                                  horizontal: -1,
                                  vertical: -1,
                                )
                              : null,
                          selected: selectedFilter == f.value,
                          onSelected: (_) => onFilter(f.value),
                          selectedColor: accent.withValues(alpha: .13),
                          checkmarkColor: accent,
                          side: BorderSide(
                            color: selectedFilter == f.value
                                ? accent.withValues(alpha: .35)
                                : AppColors.border,
                          ),
                        ),
                      ),
                      ...extraFilters,
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (children.isEmpty)
              _StateMessage(
                icon: Icons.search_off_rounded,
                title: 'No matches found',
                message: emptyMessage,
              )
            else if (columns == 1)
              ...children.map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: child,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: children
                    .map(
                      (child) => SizedBox(
                        width:
                            (constraints.maxWidth -
                                (padding * 2) -
                                (AppSpacing.lg * (columns - 1))) /
                            columns,
                        child: child,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );
    },
  );
}

class _CommunitySnapshotCard extends StatelessWidget {
  const _CommunitySnapshotCard({required this.community, required this.onTap});

  final CommunityRecord community;
  final VoidCallback onTap;

  bool get _isFormation {
    final name = community.name.trim().toLowerCase();
    final type = (community.type ?? '').toLowerCase();

    return const {
          'mary immaculate novitiate',
          'st. antony scholasticate',
          'vidhya deep theologate',
          'st. antony vocation house',
        }.contains(name) ||
        type.contains('formation') ||
        type.contains('novitiate') ||
        type.contains('scholastic') ||
        type.contains('theologate') ||
        type.contains('vocation');
  }

  bool get _isGovernance {
    final name = community.name.trim().toLowerCase();
    final type = (community.type ?? '').toLowerCase();

    return name == 'provincial house' ||
        type.contains('governance') ||
        type.contains('provincial administration');
  }

  bool get _isMinistry =>
      !_isFormation && !_isGovernance && community.ministries.isNotEmpty;

  static const List<Color> _communityPalette = [
    AppColors.success,
    AppColors.info,
    AppColors.purple,
    AppColors.secondaryDark,
    AppColors.cyan,
    AppColors.warning,
    AppColors.primary,
  ];

  int get _accentIndex {
    final source = community.code ?? community.name;
    final value = source.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return value % _communityPalette.length;
  }

  Color get _accent => _communityPalette[_accentIndex];

  IconData get _headerIcon {
    if (_isGovernance) return Icons.account_balance_outlined;
    if (_isFormation) return Icons.school_outlined;
    if (_isMinistry) return Icons.volunteer_activism_outlined;
    return Icons.holiday_village_outlined;
  }

  String get _classification {
    if (_isGovernance) return 'GOVERNANCE';
    if (_isFormation) return 'FORMATION';
    if (_isMinistry) return 'MINISTRY';
    return 'COMMUNITY';
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Community cards use a left category accent so they remain
              // visually distinct from Religious member cards.
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(_headerIcon, color: _accent, size: 23),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  community.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.responsive(context)
                                      .titleMedium
                                      .copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: .09),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.full,
                                    ),
                                  ),
                                  child: Text(
                                    _classification,
                                    style: AppTypography.responsive(context)
                                        .labelSmall
                                        .copyWith(
                                          color: _accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _SnapshotChip(
                            Icons.groups_2_outlined,
                            '${community.residentCount} ${community.residentCount == 1 ? 'Resident' : 'Residents'}',
                            AppColors.info,
                          ),
                          if (community.ministries.isNotEmpty)
                            _SnapshotChip(
                              Icons.volunteer_activism_outlined,
                              '${community.ministries.length} ${community.ministries.length == 1 ? 'Ministry' : 'Ministries'}',
                              AppColors.success,
                            ),
                          if (community.establishedYear != null)
                            _SnapshotChip(
                              Icons.event_outlined,
                              'Established ${community.establishedYear}',
                              AppColors.cyan,
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      if (_hasText(community.superior) ||
                          community.superiorPerson != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: _SnapshotRow(
                            Icons.manage_accounts_outlined,
                            'Superior',
                            community.superior ?? 'Not assigned',
                            AppColors.info,
                            actions: _contactActions(community.superiorPerson),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xs),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'View Community',
                            style: AppTypography.responsive(context).labelSmall
                                .copyWith(
                                  color: _accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: _accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CommunityLeadershipRow extends StatelessWidget {
  const _CommunityLeadershipRow({
    required this.label,
    required this.name,
    required this.person,
    required this.color,
    this.onTap,
  });
  final String label;
  final String? name;
  final ProvincePerson? person;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final actions = _contactActions(person);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackActions = constraints.maxWidth < 500;
            final identity = Row(
              children: [
                Container(
                  width: stackActions ? 56 : 48,
                  height: stackActions ? 56 : 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: MemberAvatar(
                    name: person?.name ?? name ?? label,
                    photoUrl: person?.photoUrl,
                    radius: stackActions ? 28 : 24,
                    backgroundColor: color.withValues(alpha: .1),
                    initialsStyle: AppTypography.responsive(
                      context,
                    ).labelSmall.copyWith(color: color),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.responsive(
                          context,
                        ).labelSmall.copyWith(color: color),
                      ),
                      Text(
                        name ?? 'Not assigned',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.responsive(context).bodyMedium
                            .copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!stackActions) ...actions,
              ],
            );
            if (!stackActions || actions.isEmpty) return identity;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: MemberAvatar(
                    name: person?.name ?? name ?? label,
                    photoUrl: person?.photoUrl,
                    radius: 28,
                    backgroundColor: color.withValues(alpha: .1),
                    initialsStyle: AppTypography.responsive(
                      context,
                    ).labelSmall.copyWith(color: color),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.responsive(
                          context,
                        ).labelSmall.copyWith(color: color),
                      ),
                      Text(
                        name ?? 'Not assigned',
                        style: AppTypography.responsive(
                          context,
                        ).bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: actions,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Widget> _contactActions(ProvincePerson? person) => [
  if (_hasText(person?.phone))
    ContactActionButton(
      type: ContactActionType.call,
      value: person!.phone!,
      personName: person.name,
    ),
  if (_hasText(person?.whatsApp))
    ContactActionButton(
      type: ContactActionType.whatsApp,
      value: person!.whatsApp!,
      personName: person.name,
    ),
  if (_hasText(person?.email))
    ContactActionButton(
      type: ContactActionType.email,
      value: person!.email!,
      personName: person.name,
    ),
];

class _MinistrySnapshotCard extends StatelessWidget {
  const _MinistrySnapshotCard({required this.ministry, required this.onTap});
  final MinistryRecord ministry;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final metrics = _operationalMetrics(ministry);
    final leader = _operationalHeadAssignment(ministry);
    final accent = ministryListingAccent(ministry.type);
    final displayedLeader = _displayedMinistryHead(ministry, leader);
    final inactive = _isInactiveMinistry(ministry.status);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: .32)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(_ministryIcon(ministry.type), color: accent),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ministry.name,
                          style: AppTypography.responsive(context).titleMedium
                              .copyWith(color: AppColors.primary, height: 1.25),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _MinistryTypeBadge(
                              ministryTypeBadge(ministry.type),
                              accent,
                            ),
                            if (inactive)
                              const _MinistryTypeBadge(
                                'INACTIVE',
                                AppColors.error,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_hasText(ministry.location)) ...[
                const SizedBox(height: AppSpacing.xs),
                _MinistrySupportingRow(
                  icon: Icons.location_on_outlined,
                  text: ministry.location!,
                  color: accent,
                ),
              ],
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: metrics
                      .map(
                        (metric) => _SnapshotChip(
                          metric.icon,
                          '${metric.label}: ${_number(metric.value)}',
                          metric.color,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (_hasText(ministry.community)) ...[
                const SizedBox(height: AppSpacing.xs),
                _MinistrySupportingRow(
                  icon: Icons.home_work_outlined,
                  text: 'Community: ${ministry.community}',
                  color: AppColors.info,
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              if (_hasText(displayedLeader))
                _MinistryLeaderRow(
                  role: leader?.role ?? ministry.headRole ?? 'Head',
                  name: displayedLeader!,
                  person: leader?.person ?? ministry.headPerson,
                  accent: accent,
                )
              else
                const _MinistrySupportingRow(
                  icon: Icons.person_off_outlined,
                  text: 'Leadership: No current head assigned',
                  color: AppColors.textSecondary,
                ),
              if (_hasText(ministry.affiliationAuthority)) ...[
                const SizedBox(height: AppSpacing.xs),
                _MinistrySupportingRow(
                  icon: Icons.verified_outlined,
                  text: ministry.affiliationAuthority!,
                  color: AppColors.warning,
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Ministry',
                    style: AppTypography.responsive(context).labelSmall
                        .copyWith(color: accent, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinistryTypeBadge extends StatelessWidget {
  const _MinistryTypeBadge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      text,
      style: AppTypography.responsive(context).labelSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: .45,
      ),
    ),
  );
}

class _MinistrySupportingRow extends StatelessWidget {
  const _MinistrySupportingRow({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          style: AppTypography.responsive(
            context,
          ).bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}

class _MinistryLeaderRow extends StatelessWidget {
  const _MinistryLeaderRow({
    required this.role,
    required this.name,
    required this.person,
    required this.accent,
  });
  final String role;
  final String name;
  final ProvincePerson? person;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.how_to_reg_outlined, size: 17, color: accent),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          '$role: $name',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.responsive(
            context,
          ).bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
      ..._contactActions(person),
    ],
  );
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow(
    this.icon,
    this.label,
    this.value,
    this.color, {
    this.actions = const [],
  });
  final IconData icon;
  final String label, value;
  final Color color;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          '$label: $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.responsive(
            context,
          ).bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
      ...actions,
    ],
  );
}

class _SnapshotChip extends StatelessWidget {
  const _SnapshotChip(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.responsive(
              context,
            ).labelSmall.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: AppTypography.responsive(
        context,
      ).labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class _FilterOption {
  const _FilterOption(this.value, this.label);
  final String value, label;
}

class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.sizeOf(context).width < 680 ? 150 : 164,
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        isExpanded: true,
        isDense: true,
        style: AppTypography.responsive(context).bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontSize: MediaQuery.sizeOf(context).width < 680 ? 13 : null,
          height: 1.2,
        ),
        value: value,
        hint: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'All $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...values.map(
            (v) => DropdownMenuItem<String?>(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}

ProvinceAssignment? _responsible(List<ProvinceAssignment> assignments) {
  const leadership = [
    'superior',
    'principal',
    'director',
    'administrator',
    'manager',
    'parish priest',
    'chaplain',
    'master',
    'coordinator',
    'bursar',
  ];
  for (final assignment in assignments) {
    final role = assignment.role?.toLowerCase() ?? '';
    if (leadership.any(role.contains)) return assignment;
  }
  return null;
}

ProvinceAssignment? _operationalHeadAssignment(MinistryRecord ministry) {
  final responsible = _responsible(ministry.currentAssignments);
  if (responsible != null) return responsible;
  final head = _normalizedPersonName(ministry.headName);
  if (head == null || head.isEmpty) return null;
  for (final assignment in ministry.currentAssignments) {
    if (_normalizedPersonName(assignment.person.name) == head) {
      return assignment;
    }
  }
  return null;
}

String? _displayedMinistryHead(
  MinistryRecord ministry,
  ProvinceAssignment? leader,
) {
  if (leader != null) return leader.person.name;
  final fallback = ministry.headName?.trim();
  if (!_hasText(fallback)) return null;
  if (_normalizedEntityName(fallback!) ==
      _normalizedEntityName(ministry.name)) {
    return null;
  }
  return fallback;
}

String _normalizedEntityName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

String? _normalizedPersonName(String? value) => value
    ?.trim()
    .toLowerCase()
    .replaceFirst(RegExp(r'^(fr|bro|dcn)\.?\s+'), '')
    .replaceAll(RegExp(r'\s+'), ' ');

String _number(int value) {
  final digits = value.toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

bool _hasContact(MinistryRecord ministry) =>
    _hasText(ministry.phone) ||
    _hasText(ministry.email) ||
    _hasText(ministry.website);

String ministryListingGroup(String? type) {
  final value = type?.trim().toLowerCase() ?? '';
  if (_containsAny(value, const [
    'formation',
    'aspirancy',
    'postulancy',
    'novitiate',
    'training',
    'theologate',
    'scholastic',
  ])) {
    return 'formation';
  }
  if (_containsAny(value, const [
    'school',
    'college',
    'education',
    'academy',
    'institute',
    'higher studies',
  ])) {
    return 'education';
  }
  if (_containsAny(value, const [
    'parish',
    'pastoral',
    'church',
    'retreat',
    'spiritual',
  ])) {
    return 'pastoral';
  }
  if (_containsAny(value, const [
    'health',
    'hospital',
    'social',
    'outreach',
    'ngo',
    'old age',
    'elder',
    'care home',
  ])) {
    return 'social_health';
  }
  return 'other';
}

String ministryTypeBadge(String? type) {
  final value = type?.trim().toLowerCase() ?? '';
  if (value.contains('health centre') || value.contains('health center')) {
    return 'HEALTH CENTRE';
  }
  if (value.contains('hospital')) return 'HOSPITAL';
  if (value.contains('school') || value.contains('academy')) return 'SCHOOL';
  if (value.contains('college')) return 'COLLEGE';
  if (value.contains('parish')) return 'PARISH';
  if (value.contains('retreat')) return 'RETREAT CENTRE';
  if (_containsAny(value, const ['old age', 'elder', 'care home'])) {
    return 'OLD AGE HOME';
  }
  if (_containsAny(value, const ['social', 'outreach', 'ngo'])) {
    return 'SOCIAL SERVICE';
  }
  if (value.contains('training')) return 'TRAINING INSTITUTE';
  if (_containsAny(value, const [
    'formation',
    'aspirancy',
    'postulancy',
    'novitiate',
    'theologate',
    'scholastic',
  ])) {
    return 'FORMATION';
  }
  if (_containsAny(value, const ['admin', 'governance', 'office'])) {
    return 'ADMINISTRATION';
  }
  return 'MINISTRY';
}

Color ministryListingAccent(String? type) =>
    switch (ministryListingGroup(type)) {
      'education' => AppColors.info,
      'formation' => AppColors.purple,
      'pastoral' => AppColors.secondaryDark,
      'social_health' when (type?.toLowerCase().contains('health') ?? false) =>
        AppColors.error,
      'social_health' => AppColors.success,
      _
          when _containsAny(type?.toLowerCase() ?? '', const [
            'admin',
            'governance',
            'office',
          ]) =>
        AppColors.primary,
      _ => AppColors.cyan,
    };

bool _containsAny(String value, List<String> terms) =>
    terms.any(value.contains);

bool _isInactiveMinistry(String? status) {
  final value = status?.trim().toLowerCase() ?? '';
  return value.contains('inactive') ||
      value.contains('closed') ||
      value.contains('suspended');
}

Color _operationalStatusColor(String? status) {
  final value = status?.toLowerCase() ?? '';
  if (value.contains('active') || value.contains('operational')) {
    return AppColors.success;
  }
  if (value.contains('closed') || value.contains('inactive')) {
    return AppColors.error;
  }
  return AppColors.textSecondary;
}

class _OperationalMetric {
  const _OperationalMetric(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final int value;
  final Color color;
}

List<_OperationalMetric> _operationalMetrics(MinistryRecord ministry) {
  final type = ministry.type?.toLowerCase() ?? '';
  final result = <_OperationalMetric>[];
  void add(int? value, IconData icon, String label, Color color) {
    if (value != null && value > 0) {
      result.add(_OperationalMetric(icon, label, value, color));
    }
  }

  final education =
      type.contains('school') ||
      type.contains('college') ||
      type.contains('training') ||
      type.contains('higher studies') ||
      type.contains('theological');
  final formation = type.contains('formation');
  final hostel = type.contains('hostel');
  final parish = type.contains('parish');
  final health = type.contains('health');
  final beneficiaryLed =
      parish ||
      health ||
      hostel ||
      type.contains('social') ||
      type.contains('youth') ||
      type.contains('retreat');

  if (education || formation) {
    add(
      ministry.totalStudents,
      Icons.school_outlined,
      formation ? 'Formees' : 'Students',
      AppColors.info,
    );
  } else if (beneficiaryLed) {
    final label = parish
        ? 'Parishioners'
        : health
        ? 'Patients'
        : hostel
        ? 'Residents'
        : 'Beneficiaries';
    add(
      ministry.totalBeneficiaries,
      Icons.people_alt_outlined,
      label,
      AppColors.info,
    );
  }
  add(
    ministry.totalStaff,
    Icons.badge_outlined,
    formation ? 'Formation staff' : 'Staff',
    AppColors.purple,
  );
  add(
    ministry.totalReligious,
    Icons.groups_2_outlined,
    'Religious',
    AppColors.success,
  );
  return result;
}

IconData _ministryIcon(String? type) {
  final value = type?.toLowerCase() ?? '';
  if (value.contains('school') ||
      value.contains('college') ||
      value.contains('education') ||
      value.contains('academy')) {
    return Icons.school_outlined;
  }
  if (value.contains('parish') || value.contains('church')) {
    return Icons.church_outlined;
  }
  if (value.contains('health') || value.contains('hospital')) {
    return Icons.local_hospital_outlined;
  }
  if (_containsAny(value, const [
    'formation',
    'aspirancy',
    'postulancy',
    'novitiate',
  ])) {
    return Icons.auto_stories_outlined;
  }
  if (value.contains('training')) return Icons.model_training_outlined;
  if (value.contains('hostel')) return Icons.bed_outlined;
  if (value.contains('retreat')) return Icons.self_improvement_outlined;
  if (value.contains('admin') || value.contains('office')) {
    return Icons.business_center_outlined;
  }
  if (value.contains('social')) return Icons.volunteer_activism_outlined;
  return Icons.handshake_outlined;
}

class _DirectoryPage extends StatelessWidget {
  const _DirectoryPage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.header,
  });
  final String title, subtitle;
  final List<Widget> children;
  final Widget? header;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final mobile = c.maxWidth < 700;
      return ColoredBox(
        color: AppColors.transparent,
        child: ListView(
          padding: EdgeInsets.all(mobile ? AppSpacing.lg : AppSpacing.xxxl),
          children: [
            Text(
              subtitle,
              style: AppTypography.responsive(
                context,
              ).bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            if (header != null) ...[
              const SizedBox(height: AppSpacing.xl),
              header!,
            ],
            const SizedBox(height: AppSpacing.xl),
            if (mobile)
              ...children.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: e,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: children
                    .map(
                      (e) => SizedBox(
                        width: children.length == 1 ? c.maxWidth : 360,
                        child: e,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );
    },
  );
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.transparent,
    appBar: AppBar(title: Text(title)),
    body: ModuleBackground(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: children
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: e,
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _ResponsiveCover extends StatelessWidget {
  const _ResponsiveCover({
    required this.imageUrl,
    required this.label,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final String label;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ratio = constraints.maxWidth < 600
          ? 2.4
          : constraints.maxWidth < 1000
          ? 2.8
          : 3.2;
      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      final cacheWidth = (constraints.maxWidth * pixelRatio).round().clamp(
        720,
        2400,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: ratio,
          child: !_hasText(imageUrl)
              ? _CoverFallback(icon: fallbackIcon, label: label)
              : Image.network(
                  imageUrl!,
                  semanticLabel: '$label cover image',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  cacheWidth: cacheWidth,
                  frameBuilder: (context, child, frame, loadedSync) {
                    if (loadedSync) return child;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _CoverLoading(icon: fallbackIcon),
                        AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 320),
                          child: child,
                        ),
                      ],
                    );
                  },
                  errorBuilder: (_, _, _) =>
                      _CoverFallback(icon: fallbackIcon, label: label),
                ),
        ),
      );
    },
  );
}

class _CoverLoading extends StatelessWidget {
  const _CoverLoading({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primary.withValues(alpha: .07),
    alignment: Alignment.center,
    child: Icon(
      icon,
      size: 44,
      color: AppColors.primary.withValues(alpha: .22),
    ),
  );
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.primary.withValues(alpha: .88),
          AppColors.secondaryDark,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    alignment: Alignment.center,
    child: Semantics(
      label: '$label cover image unavailable',
      child: Icon(
        icon,
        size: 54,
        color: AppColors.white.withValues(alpha: .88),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.responsive(
              context,
            ).titleMedium.copyWith(color: AppColors.primary),
          ),
          const Divider(height: AppSpacing.xl),
          child,
        ],
      ),
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.lines});
  final String title;
  final List<String> lines;
  @override
  Widget build(BuildContext context) => _Section(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(e),
            ),
          )
          .toList(),
    ),
  );
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({
    required this.people,
    required this.onMember,
    this.alternateColors = false,
  });
  final List<ProvincePerson> people;
  final MemberOpener onMember;
  final bool alternateColors;
  @override
  Widget build(BuildContext context) => people.isEmpty
      ? const Text('No current records available.')
      : Column(
          children: people.asMap().entries.map((entry) {
            final person = entry.value;
            final accent = entry.key.isEven ? AppColors.info : AppColors.purple;
            final details = [
              person.role,
              person.ministryAssignment,
              person.memberStatus,
            ].whereType<String>().where(_hasText).toList();
            final tile = ListTile(
              contentPadding: alternateColors
                  ? const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    )
                  : EdgeInsets.zero,
              leading: _Avatar(
                person,
                backgroundColor: alternateColors
                    ? accent.withValues(alpha: .16)
                    : null,
                foregroundColor: alternateColors ? accent : null,
              ),
              title: Text(
                person.name,
                style: alternateColors
                    ? AppTypography.responsive(context).bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      )
                    : null,
              ),
              subtitle: details.isEmpty ? null : Text(details.join(' · ')),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: alternateColors ? accent : null,
              ),
              onTap: () => onMember(_entry(person)),
            );
            if (!alternateColors) return tile;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: accent.withValues(alpha: .055),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: accent.withValues(alpha: .14)),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                clipBehavior: Clip.antiAlias,
                child: tile,
              ),
            );
          }).toList(),
        );
}

class _AssignmentsList extends StatelessWidget {
  const _AssignmentsList({required this.assignments, required this.onMember});
  final List<ProvinceAssignment> assignments;
  final MemberOpener onMember;
  @override
  Widget build(BuildContext context) => assignments.isEmpty
      ? const Text('No assignment records available.')
      : Column(
          children: assignments
              .map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _Avatar(a.person),
                  title: Text(
                    a.person.name,
                    style: AppTypography.responsive(context).bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (a.role != null) a.role!,
                      if (a.fromDate != null)
                        '${_date(a.fromDate)} – ${a.toDate == null ? 'Present' : _date(a.toDate)}',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onMember(_entry(a.person)),
                ),
              )
              .toList(),
        );
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.person, {this.backgroundColor, this.foregroundColor});
  final ProvincePerson person;
  final Color? backgroundColor;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) => MemberAvatar(
    name: person.name,
    photoUrl: person.photoUrl,
    radius: MediaQuery.sizeOf(context).width < 600 ? 28 : null,
    backgroundColor:
        backgroundColor ?? AppColors.secondary.withValues(alpha: .12),
    foregroundColor: foregroundColor,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    this.width = 180,
    this.icon,
    this.accent,
  });
  final int value;
  final String label;
  final double width;
  final IconData? icon;
  final Color? accent;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 100,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$value',
              style: AppTypography.responsive(
                context,
              ).titleLarge.copyWith(color: accent ?? AppColors.primary),
            ),
            if (icon != null) ...[
              const Spacer(),
              Icon(icon, size: 19, color: accent ?? AppColors.primary),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.responsive(context).labelSmall,
        ),
      ],
    ),
  );
}

class _FormationSummary extends StatelessWidget {
  const _FormationSummary({required this.metrics});

  final List<(int, String)> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: const Key('formation-summary'),
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 5
          : constraints.maxWidth >= 600
          ? 4
          : 3;
      const gap = AppSpacing.sm;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final metric in metrics)
            _Metric(
              value: metric.$1,
              label: metric.$2,
              width: width,
              icon: metric.$2 == 'Formation\nStaff'
                  ? Icons.manage_accounts_outlined
                  : null,
              accent: metric.$2 == 'Formation\nStaff' ? AppColors.purple : null,
            ),
        ],
      );
    },
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String title, message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.responsive(context).titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}

MemberDirectoryEntry _entry(ProvincePerson p) => MemberDirectoryEntry(
  id: p.id,
  religiousId: '',
  displayName: p.name,
  photoUrl: p.photoUrl,
  memberStatus: 'Active',
);
String _date(DateTime? d) => d == null
    ? 'Date unavailable'
    : '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
