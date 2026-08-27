import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/contact_action_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../data/religious_profile_repository.dart';
import '../data/member_timeline_mapper.dart';
import '../models/religious_profile.dart';
import '../state/religious_profile_controller.dart';

class ReligiousProfileScreen extends StatefulWidget {
  const ReligiousProfileScreen({
    required this.memberId,
    required this.repository,
    required this.onBack,
    this.canEdit = false,
    this.onEdit,
    super.key,
  });
  final String memberId;
  final ReligiousProfileRepository repository;
  final VoidCallback onBack;
  final bool canEdit;
  final VoidCallback? onEdit;
  @override
  State<ReligiousProfileScreen> createState() => _ReligiousProfileScreenState();
}

class _ReligiousProfileScreenState extends State<ReligiousProfileScreen> {
  late final ReligiousProfileController controller;
  @override
  void initState() {
    super.initState();
    controller = ReligiousProfileController(widget.repository, widget.memberId)
      ..addListener(_refresh)
      ..load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.transparent,
    child: switch (controller.status) {
      ReligiousProfileStatus.loading => const _ProfileLoading(),
      ReligiousProfileStatus.error => _ProfileError(
        kind: controller.failureKind,
        onRetry: controller.load,
        onBack: widget.onBack,
      ),
      ReligiousProfileStatus.ready => _ProfileContent(
        profile: controller.profile!,
        onBack: widget.onBack,
        canEdit: widget.canEdit,
        onEdit: widget.onEdit,
      ),
    },
  );
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onBack,
    required this.canEdit,
    this.onEdit,
  });
  final ReligiousProfile profile;
  final VoidCallback onBack;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 760;
      final twoColumns = constraints.maxWidth >= 980;
      final gap = mobile ? AppSpacing.md : AppSpacing.lg;
      final left = Column(
        children: [
          _IdentityOverview(profile: profile, compact: mobile),
          SizedBox(height: gap),
          _AssignmentTimeline(profile: profile),
          if (_hasLeaveSection(profile)) ...[
            SizedBox(height: gap),
            _LeaveHistoryCard(profile: profile),
          ],
          if (profile.sections.vocationEvents.isNotEmpty) ...[
            SizedBox(height: gap),
            _VocationCard(profile: profile),
          ],
        ],
      );
      final right = Column(
        children: [
          _SummaryMetrics(profile: profile),
          SizedBox(height: gap),
          _ContactCard(profile: profile),
          if (profile.origin != null) ...[
            SizedBox(height: gap),
            _OriginCard(profile: profile),
          ],
          SizedBox(height: gap),
          _QualificationsCard(profile: profile),
          SizedBox(height: gap),
          _ResponsibilitiesCard(profile: profile),
          if (_hasSupplementary(profile)) ...[
            SizedBox(height: gap),
            _SupplementaryCard(profile: profile),
          ],
        ],
      );
      return CustomScrollView(
        key: const Key('religious-profile-scroll'),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              mobile ? AppSpacing.lg : AppSpacing.xxl,
              AppSpacing.md,
              mobile ? AppSpacing.lg : AppSpacing.xxl,
              AppSpacing.max + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                _Toolbar(onBack: onBack, canEdit: canEdit, onEdit: onEdit),
                SizedBox(height: gap),
                if (mobile) ...[
                  _IdentityOverview(profile: profile, compact: true),
                  SizedBox(height: gap),
                  _SummaryMetrics(profile: profile),
                  SizedBox(height: gap),
                  _ContactCard(profile: profile),
                  SizedBox(height: gap),
                  _QualificationsCard(profile: profile),
                  SizedBox(height: gap),
                  _ResponsibilitiesCard(profile: profile),
                  if (profile.sections.vocationEvents.isNotEmpty) ...[
                    SizedBox(height: gap),
                    _VocationCard(profile: profile),
                  ],
                  if (profile.origin != null) ...[
                    SizedBox(height: gap),
                    _OriginCard(profile: profile),
                  ],
                  if (_hasSupplementary(profile)) ...[
                    SizedBox(height: gap),
                    _SupplementaryCard(profile: profile),
                  ],
                  SizedBox(height: gap),
                  _AssignmentTimeline(profile: profile),
                  if (_hasLeaveSection(profile)) ...[
                    SizedBox(height: gap),
                    _LeaveHistoryCard(profile: profile),
                  ],
                ] else if (twoColumns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 58, child: left),
                      SizedBox(width: gap),
                      Expanded(flex: 42, child: right),
                    ],
                  )
                else ...[
                  left,
                  SizedBox(height: gap),
                  right,
                ],
              ],
            ),
          ),
        ],
      );
    },
  );

  bool _hasSupplementary(ReligiousProfile p) =>
      p.sections.homeContacts.isNotEmpty ||
      p.sections.family.isNotEmpty ||
      p.sections.documents.isNotEmpty;

  bool _hasLeaveSection(ReligiousProfile p) =>
      p.sections.leaveHistory.isNotEmpty ||
      p.memberStatus.toLowerCase() == 'on leave';
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onBack, required this.canEdit, this.onEdit});
  final VoidCallback onBack;
  final bool canEdit;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: _isMobileProfile(context) ? 48 : 40,
    child: Row(
      children: [
        IconButton(
          key: const Key('profile-back'),
          onPressed: onBack,
          tooltip: 'Back to Religious',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Religious Profile',
            style: AppTypography.responsive(
              context,
            ).titleLarge.copyWith(color: AppColors.primary),
          ),
        ),
        if (canEdit && onEdit != null)
          OutlinedButton.icon(
            key: const Key('profile-edit'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
      ],
    ),
  );
}

class _IdentityOverview extends StatelessWidget {
  const _IdentityOverview({required this.profile, required this.compact});
  final ReligiousProfile profile;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final details = <_InfoData>[
      if (profile.religiousId.isNotEmpty)
        _InfoData(
          Icons.numbers_outlined,
          'Religious ID',
          profile.religiousId,
          AppColors.info,
        ),
      if (profile.title != null)
        _InfoData(
          Icons.auto_awesome_outlined,
          'Ecclesiastical Title',
          profile.title!,
          AppColors.info,
        ),
      if (profile.dateOfBirth != null)
        _InfoData(
          Icons.cake_outlined,
          'Date of Birth',
          '${_date(profile.dateOfBirth)}${profile.age == null ? '' : ' (${profile.age})'}',
          AppColors.error,
        ),
      if (profile.nationality != null)
        _InfoData(
          Icons.public_rounded,
          'Nationality',
          profile.nationality!,
          AppColors.success,
        ),
      if (profile.canonicalStatus != null)
        _InfoData(
          Icons.verified_user_outlined,
          'Canonical Status',
          profile.canonicalStatus!,
          AppColors.success,
        ),
      if (_recordedSince(profile) case final since?)
        _InfoData(
          Icons.person_add_alt_outlined,
          'Recorded Since',
          _date(since),
          AppColors.info,
        ),
      if (profile.patronSaint != null)
        _InfoData(
          Icons.workspace_premium_outlined,
          'Patron Saint',
          profile.patronSaint!,
          AppColors.warning,
        ),
      if (profile.community != null)
        _InfoData(
          Icons.home_work_outlined,
          'Current Community',
          profile.community!,
          AppColors.error,
        ),
      if (profile.communityRole != null)
        _InfoData(
          Icons.badge_outlined,
          'Community Role',
          profile.communityRole!,
          AppColors.purple,
        ),
      _InfoData(
        Icons.groups_outlined,
        'Directory Status',
        profile.memberStatus,
        AppColors.secondary,
      ),
    ];
    return _Card(
      key: const Key('profile-header'),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .055),
                  AppColors.purple.withValues(alpha: .035),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(profile: profile, radius: compact ? 34 : 42),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.titledName,
                        maxLines: compact ? null : 2,
                        overflow: compact ? null : TextOverflow.ellipsis,
                        style:
                            (compact
                                    ? AppTypography.responsive(
                                        context,
                                      ).titleLarge
                                    : AppTypography.responsive(
                                        context,
                                      ).headlineMedium)
                                .copyWith(
                                  color: AppColors.primary,
                                  fontSize: compact ? 25 : null,
                                  height: compact ? 1.25 : null,
                                ),
                      ),
                      if (profile.community != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          profile.community!,
                          maxLines: compact ? null : 1,
                          overflow: compact ? null : TextOverflow.ellipsis,
                          style: AppTypography.responsive(context).bodyMedium
                              .copyWith(
                                color: _profileSecondary(context),
                                fontSize: compact ? 16.5 : null,
                                height: compact ? 1.45 : null,
                              ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _Pill(profile.memberStatus, AppColors.success),
                          if (profile.canonicalStatus != null &&
                              profile.canonicalStatus != profile.memberStatus)
                            _Pill(profile.canonicalStatus!, AppColors.purple),
                          if (profile.ministryRole != null)
                            _Pill(profile.ministryRole!, AppColors.info),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth >= 620
                    ? 3
                    : c.maxWidth >= 380
                    ? 2
                    : 1;
                final width =
                    (c.maxWidth - AppSpacing.md * (columns - 1)) / columns;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: details
                      .map((d) => SizedBox(width: width, child: _InfoCell(d)))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.profile});
  final ReligiousProfile profile;
  @override
  Widget build(BuildContext context) {
    final communities = profile.sections.communityAssignments
        .map((e) => e.name)
        .toSet()
        .length;
    final ministries = profile.sections.ministryAssignments
        .map((e) => e.name)
        .toSet()
        .length;
    final roles = {
      ...profile.sections.offices.map((e) => e.office),
      ...profile.sections.communityAssignments
          .map((e) => e.role)
          .whereType<String>(),
      ...profile.sections.ministryAssignments
          .map((e) => e.role)
          .whereType<String>(),
    }.length;
    final span = _serviceSpan(profile);
    final metrics = [
      _MetricData(
        Icons.groups_2_outlined,
        '$communities',
        'Communities',
        AppColors.info,
      ),
      _MetricData(
        Icons.volunteer_activism_outlined,
        '$ministries',
        'Ministries',
        AppColors.success,
      ),
      _MetricData(Icons.badge_outlined, '$roles', 'Roles', AppColors.warning),
      if (span != null)
        _MetricData(
          Icons.schedule_rounded,
          span,
          'Recorded service',
          AppColors.purple,
        ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final accessibleMobile =
            _isMobileProfile(context) &&
            MediaQuery.textScalerOf(context).scale(1) >= 1.3;
        if (accessibleMobile) {
          final width = (c.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: width,
                  child: _MetricCard(metric, accessible: true),
                ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              Expanded(child: _MetricCard(metrics[i])),
              if (i != metrics.length - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _AssignmentTimeline extends StatefulWidget {
  const _AssignmentTimeline({required this.profile});
  final ReligiousProfile profile;

  @override
  State<_AssignmentTimeline> createState() => _AssignmentTimelineState();
}

class _AssignmentTimelineState extends State<_AssignmentTimeline> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final events = MemberTimelineMapper.fromProfile(widget.profile);
    final visible = expanded ? events : events.take(9).toList();
    return _SectionCard(
      key: const Key('profile-assignments'),
      title: 'Life & Ministry Timeline',
      icon: Icons.account_tree_outlined,
      accent: AppColors.warning,
      child: events.isEmpty
          ? const _Empty('No dated life or ministry events available')
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++)
                  _MemberTimelineRow(
                    event: visible[i],
                    last: i == visible.length - 1,
                  ),
                if (events.length > 9) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    key: const Key('profile-timeline-toggle'),
                    onPressed: () => setState(() => expanded = !expanded),
                    icon: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    label: Text(
                      expanded ? 'Show Latest Only' : 'View Full Timeline',
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _MemberTimelineRow extends StatelessWidget {
  const _MemberTimelineRow({required this.event, required this.last});
  final MemberTimelineEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final style = _timelineCategoryStyle(event.category);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: style.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: style.color.withValues(alpha: .24),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timelineDateRange(event),
                    style: AppTypography.responsive(context).labelMedium
                        .copyWith(
                          color: _profileSecondary(context),
                          fontSize: _mobileFont(context, 15.5),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.title,
                    style: AppTypography.responsive(context).labelLarge
                        .copyWith(
                          color: AppColors.textPrimary,
                          fontSize: _mobileFont(context, 17.5),
                          height: _mobileHeight(context, 1.4),
                        ),
                  ),
                  if (event.context case final value?)
                    Text(
                      value,
                      style: AppTypography.responsive(context).bodyMedium
                          .copyWith(
                            fontSize: _mobileFont(context, 16),
                            height: _mobileHeight(context, 1.45),
                          ),
                    ),
                  if (event.location case final value?)
                    Text(
                      value,
                      style: AppTypography.responsive(context).bodySmall
                          .copyWith(
                            color: _profileSecondary(context),
                            fontSize: _mobileFont(context, 15.5),
                          ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    style.label,
                    style: AppTypography.responsive(context).labelSmall
                        .copyWith(
                          color: style.color,
                          fontSize: _mobileFont(context, 14.5),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.profile});
  final ReligiousProfile profile;
  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final values = <LabeledValue>[];
    for (final item in [
      ...profile.sections.contacts,
      ...profile.sections.homeContacts,
    ]) {
      final normalized = item.value.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      if (seen.add(normalized)) values.add(item);
    }
    final phone = values
        .where(
          (item) =>
              !item.label.toLowerCase().contains('whatsapp') &&
              (item.label.toLowerCase().contains('mobile') ||
                  item.label.toLowerCase().contains('phone')),
        )
        .firstOrNull
        ?.value;
    final whatsApp = values
        .where((item) => item.label.toLowerCase().contains('whatsapp'))
        .firstOrNull
        ?.value;
    return _SectionCard(
      key: const Key('profile-family'),
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      accent: AppColors.info,
      child: values.isEmpty
          ? const _Empty('No contact information available')
          : Column(
              children: values
                  .map(
                    (e) => _CompactRow(
                      icon: _contactIcon(e.label, e.value),
                      title: e.label,
                      subtitle: e.value,
                      color: AppColors.info,
                      trailing: ContactActionButtons(
                        personName: profile.displayName,
                        compact: !_isMobileProfile(context),
                        phone: e.value == phone ? e.value : null,
                        whatsApp: e.value == phone
                            ? whatsApp ?? phone
                            : phone == null && e.value == whatsApp
                            ? whatsApp
                            : null,
                        email: e.label.toLowerCase().contains('email')
                            ? e.value
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _QualificationsCard extends StatelessWidget {
  const _QualificationsCard({required this.profile});
  final ReligiousProfile profile;
  @override
  Widget build(BuildContext context) => _SectionCard(
    key: const Key('profile-qualifications'),
    title: 'Qualifications',
    icon: Icons.school_outlined,
    accent: AppColors.purple,
    child: _body(
      profile.sections.failures.contains(ProfileSection.qualifications),
      profile.sections.qualifications.isEmpty,
      'No qualification records available',
      Column(
        children: [
          for (
            var index = 0;
            index < profile.sections.qualifications.take(6).length;
            index++
          ) ...[
            _QualificationRow(
              qualification: profile.sections.qualifications[index],
            ),
            if (index < profile.sections.qualifications.take(6).length - 1)
              const Divider(height: 18),
          ],
        ],
      ),
    ),
  );
}

class _QualificationRow extends StatelessWidget {
  const _QualificationRow({required this.qualification});
  final QualificationRecord qualification;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if (qualification.category case final value?) 'Category: $value',
      if (qualification.level case final value?) 'Level: $value',
      if (qualification.specialization case final value?)
        'Specialization: $value',
      if (qualification.subject case final value?) 'Subject: $value',
      if (qualification.teachingSubjects.isNotEmpty)
        'Teaching subjects: ${qualification.teachingSubjects.join(', ')}',
      if (qualification.institution case final value?) 'Institution: $value',
      if (qualification.universityBoard case final value?)
        'University / Board: $value',
      if (qualification.year case final value?) 'Year: $value',
      if (qualification.year == null &&
          (qualification.startYear != null || qualification.endYear != null))
        'Years: ${qualification.startYear ?? '—'} – ${qualification.endYear ?? 'Present'}',
      if (qualification.country case final value?) 'Country: $value',
      if (qualification.notes case final value?) 'Notes: $value',
    ];
    return _CompactRow(
      icon: Icons.task_alt_rounded,
      title: qualification.qualification,
      subtitle: metadata.join('\n'),
      color: AppColors.purple,
    );
  }
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({required this.profile});

  final ReligiousProfile profile;

  @override
  Widget build(BuildContext context) {
    final origin = profile.origin!;
    final values = <({String label, String? value, IconData icon})>[
      (
        label: 'Native Place',
        value: origin.nativePlace,
        icon: Icons.place_outlined,
      ),
      (
        label: 'Home Parish',
        value: origin.homeParish,
        icon: Icons.church_outlined,
      ),
      (
        label: 'Diocese',
        value: origin.diocese,
        icon: Icons.account_balance_outlined,
      ),
      (
        label: 'District',
        value: origin.district,
        icon: Icons.location_city_outlined,
      ),
      (label: 'State', value: origin.state, icon: Icons.map_outlined),
      (label: 'Country', value: origin.country, icon: Icons.public_outlined),
    ].where((item) => item.value != null).toList();

    return _SectionCard(
      key: const Key('profile-origin'),
      title: 'Origin & Home Details',
      icon: Icons.home_outlined,
      accent: AppColors.secondary,
      child: Column(
        children: values
            .map(
              (item) => _CompactRow(
                icon: item.icon,
                title: item.label,
                subtitle: item.value!,
                color: AppColors.secondary,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ResponsibilitiesCard extends StatelessWidget {
  const _ResponsibilitiesCard({required this.profile});
  final ReligiousProfile profile;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final a in profile.sections.communityAssignments.where(
      (a) => a.isCurrent && a.role != null,
    )) {
      if (a.role != 'Member' && a.role != 'Community Member') {
        rows.add(
          _Responsibility(
            role: a.role!,
            place: a.name,
            since: a.fromDate,
            color: AppColors.warning,
            icon: Icons.home_work_outlined,
          ),
        );
      }
    }
    for (final a in profile.sections.ministryAssignments.where(
      (a) => a.isCurrent,
    )) {
      rows.add(
        _Responsibility(
          role: a.role ?? 'Ministry responsibility',
          place: a.name,
          since: a.fromDate,
          color: AppColors.success,
          icon: _isFormationRole(a.role)
              ? Icons.school_outlined
              : Icons.volunteer_activism_outlined,
        ),
      );
    }
    for (final o in profile.sections.offices.where((o) => o.isCurrent)) {
      rows.add(
        _Responsibility(
          role: o.office,
          place: o.context ?? 'Office appointment',
          since: o.fromDate,
          color: AppColors.info,
          icon: Icons.account_balance_outlined,
        ),
      );
    }
    return _SectionCard(
      title: 'Responsibilities (Current)',
      icon: Icons.how_to_reg_outlined,
      accent: AppColors.success,
      child: rows.isEmpty
          ? const _Empty('No current responsibilities recorded')
          : Column(children: rows),
    );
  }
}

class _LeaveHistoryCard extends StatelessWidget {
  const _LeaveHistoryCard({required this.profile});
  final ReligiousProfile profile;

  @override
  Widget build(BuildContext context) {
    final currentStatus = profile.memberStatus.toLowerCase() == 'on leave';
    final records = profile.sections.leaveHistory;
    return _SectionCard(
      key: const Key('profile-leave-history'),
      title: 'Leave & Sabbatical History',
      icon: Icons.event_busy_outlined,
      accent: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentStatus || records.any((record) => record.isCurrent)) ...[
            const _ContactBadge(
              label: 'Currently on Leave',
              color: AppColors.warning,
            ),
            if (records.isNotEmpty) const SizedBox(height: AppSpacing.md),
          ],
          if (records.isEmpty && currentStatus)
            Text(
              'No dated leave record is available.',
              style: AppTypography.responsive(
                context,
              ).bodySmall.copyWith(color: _profileSecondary(context)),
            ),
          for (var index = 0; index < records.length; index++) ...[
            _CompactRow(
              icon: Icons.free_cancellation_outlined,
              title: records[index].type,
              subtitle:
                  [
                        _dateRange(
                          records[index].fromDate,
                          records[index].toDate,
                        ),
                        records[index].location,
                        records[index].reason,
                        records[index].notes,
                      ]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
              color: AppColors.warning,
            ),
            if (index < records.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _VocationCard extends StatelessWidget {
  const _VocationCard({required this.profile});
  final ReligiousProfile profile;
  @override
  Widget build(BuildContext context) => _SectionCard(
    key: const Key('profile-vocation'),
    title: 'Vocation & Formation Milestones',
    icon: Icons.auto_stories_outlined,
    accent: AppColors.purple,
    child: Column(
      children: profile.sections.vocationEvents
          .map(
            (e) => _CompactRow(
              icon: Icons.stars_outlined,
              title: e.label,
              subtitle: [
                _date(e.date),
                e.place,
                e.notes,
              ].whereType<String>().where((s) => s != '—').join(' · '),
              color: AppColors.purple,
            ),
          )
          .toList(),
    ),
  );
}

class _SupplementaryCard extends StatelessWidget {
  const _SupplementaryCard({required this.profile});
  final ReligiousProfile profile;
  @override
  Widget build(BuildContext context) {
    final family = [...profile.sections.family]
      ..sort((a, b) {
        final relationship = _familyRank(a).compareTo(_familyRank(b));
        if (relationship != 0) return relationship;
        if (a.isEmergency != b.isEmergency) return a.isEmergency ? -1 : 1;
        if (a.isNextOfKin != b.isNextOfKin) return a.isNextOfKin ? -1 : 1;
        return 0;
      });
    final documents = profile.sections.documents;
    return _SectionCard(
      key: const Key('profile-documents'),
      title: 'Family Details',
      icon: Icons.folder_shared_outlined,
      accent: AppColors.secondary,
      child: family.isEmpty && documents.isEmpty
          ? const _Empty('No family or document records available')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (family.isNotEmpty) ...[
                  const _SubsectionLabel('FAMILY'),
                  const SizedBox(height: AppSpacing.sm),
                  for (var index = 0; index < family.length; index++) ...[
                    _FamilyContactRow(contact: family[index]),
                    if (index < family.length - 1) const Divider(height: 16),
                  ],
                ],
                if (family.isNotEmpty && documents.isNotEmpty)
                  const SizedBox(height: AppSpacing.lg),
                if (documents.isNotEmpty) ...[
                  const _SubsectionLabel('DOCUMENTS'),
                  const SizedBox(height: AppSpacing.sm),
                  ...documents.map(
                    (document) => _CompactRow(
                      icon: Icons.description_outlined,
                      title: document.type,
                      subtitle: [
                        document.number,
                        document.verificationStatus,
                      ].whereType<String>().join(' · '),
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _FamilyContactRow extends StatelessWidget {
  const _FamilyContactRow({required this.contact});

  final FamilyContact contact;

  @override
  Widget build(BuildContext context) {
    final phone = contact.phone?.trim().isNotEmpty == true
        ? contact.phone
        : contact.whatsApp;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_outline, size: 19, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.relationship ?? 'Family member',
                  style: AppTypography.responsive(context).bodySmall.copyWith(
                    color: _profileSecondary(context),
                    fontSize: _mobileFont(context, 15.5),
                    height: _mobileHeight(context, 1.45),
                  ),
                ),
                Text(
                  contact.displayName,
                  style: AppTypography.responsive(context).labelLarge.copyWith(
                    fontSize: _mobileFont(context, 17.5),
                    height: _mobileHeight(context, 1.4),
                  ),
                ),
                if (_familyLifeDetail(contact) case final detail?)
                  Text(
                    detail,
                    style: AppTypography.responsive(context).bodySmall.copyWith(
                      color: _profileSecondary(context),
                      fontSize: _mobileFont(context, 15.5),
                      height: _mobileHeight(context, 1.45),
                    ),
                  ),
                if (contact.isEmergency || contact.isNextOfKin) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (contact.isEmergency)
                        const _ContactBadge(
                          label: 'Emergency Contact',
                          color: AppColors.error,
                        ),
                      if (contact.isNextOfKin)
                        const _ContactBadge(
                          label: 'Next of Kin',
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ],
                if (contact.notes case final notes?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notes,
                    style: AppTypography.responsive(context).bodySmall.copyWith(
                      color: _profileSecondary(context),
                      fontSize: _mobileFont(context, 15.5),
                      height: _mobileHeight(context, 1.45),
                    ),
                  ),
                ],
                if (phone != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          phone,
                          style: AppTypography.responsive(context).bodySmall
                              .copyWith(
                                fontSize: _mobileFont(context, 17),
                                height: _mobileHeight(context, 1.45),
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ContactActionButtons(
                        personName: contact.name,
                        phone: contact.lifeStatus == FamilyLifeStatus.deceased
                            ? null
                            : contact.phone,
                        whatsApp:
                            contact.lifeStatus == FamilyLifeStatus.deceased
                            ? null
                            : contact.whatsApp,
                        compact: !_isMobileProfile(context),
                      ),
                    ],
                  ),
                ],
                if (contact.email case final email?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email,
                          style: AppTypography.responsive(context).bodySmall
                              .copyWith(
                                color: _profileSecondary(context),
                                fontSize: _mobileFont(context, 15.5),
                                height: _mobileHeight(context, 1.45),
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ContactActionButtons(
                        personName: contact.name,
                        email: contact.lifeStatus == FamilyLifeStatus.deceased
                            ? null
                            : email,
                        compact: !_isMobileProfile(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _familyRank(FamilyContact contact) =>
    switch (contact.relationship?.toLowerCase()) {
      'father' => 0,
      'mother' => 1,
      _ => 2,
    };

String? _familyLifeDetail(FamilyContact contact) {
  final death = contact.dateOfDeath;
  if (contact.lifeStatus == FamilyLifeStatus.deceased) {
    if (death != null) return 'Died: ${_date(death)}';
    if (contact.deathYear case final year?) return 'Died: $year';
  }
  return null;
}

class _ContactBadge extends StatelessWidget {
  const _ContactBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Text(
      label,
      style: AppTypography.responsive(
        context,
      ).labelSmall.copyWith(color: color),
    ),
  );
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTypography.responsive(context).labelSmall.copyWith(
      color: _profileSecondary(context),
      fontSize: _mobileFont(context, 15),
      letterSpacing: .8,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .035),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    super.key,
  });
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTypography.responsive(context).titleMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: _mobileFont(context, 21),
                  height: _mobileHeight(context, 1.3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

class _InfoCell extends StatelessWidget {
  const _InfoCell(this.data);
  final _InfoData data;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(data.icon, size: 19, color: data.color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.label,
              style: AppTypography.responsive(context).labelSmall.copyWith(
                color: _profileSecondary(context),
                fontSize: _mobileFont(context, 15.5),
                height: _mobileHeight(context, 1.4),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.value,
              maxLines: _isMobileProfile(context) ? null : 2,
              overflow: _isMobileProfile(context)
                  ? null
                  : TextOverflow.ellipsis,
              style: AppTypography.responsive(context).labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: _mobileFont(context, 17.5),
                height: _mobileHeight(context, 1.4),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.data, {this.accessible = false});
  final _MetricData data;
  final bool accessible;
  @override
  Widget build(BuildContext context) => Container(
    height: accessible ? 152 : 86,
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(data.icon, size: 20, color: data.color),
        const Spacer(),
        Text(
          data.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.responsive(context).titleMedium.copyWith(
            color: AppColors.primary,
            fontSize: _mobileFont(context, 18),
          ),
        ),
        Text(
          data.label,
          maxLines: accessible ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.responsive(context).labelSmall.copyWith(
            color: _profileSecondary(context),
            fontSize: _mobileFont(context, accessible ? 15 : 13),
            height: _mobileHeight(context, 1.3),
          ),
        ),
      ],
    ),
  );
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
  });
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.responsive(context).labelLarge.copyWith(
                  fontSize: _mobileFont(context, 17.5),
                  height: _mobileHeight(context, 1.4),
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: AppTypography.responsive(context).bodySmall.copyWith(
                    color: _profileSecondary(context),
                    fontSize: _mobileFont(context, 15.5),
                    height: _mobileHeight(context, 1.45),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing!,
        ],
      ],
    ),
  );
}

class _Responsibility extends StatelessWidget {
  const _Responsibility({
    required this.role,
    required this.place,
    required this.since,
    required this.color,
    required this.icon,
  });
  final String role, place;
  final DateTime? since;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _CompactRow(
    icon: icon,
    title: role,
    subtitle: '$place${since == null ? '' : ' · Since ${_date(since)}'}',
    color: color,
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.radius});
  final ReligiousProfile profile;
  final double radius;
  @override
  Widget build(BuildContext context) => MemberAvatar(
    name: profile.displayName,
    photoUrl: profile.photoUrl,
    initials: _profileInitials(profile.displayName),
    radius: radius,
    backgroundColor: AppColors.primary.withValues(alpha: .08),
    initialsStyle: AppTypography.responsive(
      context,
    ).headlineMedium.copyWith(color: AppColors.primary),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Text(
      text,
      maxLines: _isMobileProfile(context) ? null : 1,
      overflow: _isMobileProfile(context) ? null : TextOverflow.ellipsis,
      style: AppTypography.responsive(context).labelSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: _mobileFont(context, 13),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Text(
      message,
      style: AppTypography.responsive(context).bodySmall.copyWith(
        color: _profileSecondary(context),
        fontSize: _mobileFont(context, 15.5),
        height: _mobileHeight(context, 1.45),
      ),
    ),
  );
}

bool _isMobileProfile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 760;

double? _mobileFont(BuildContext context, double size) =>
    _isMobileProfile(context) ? size : null;

double? _mobileHeight(BuildContext context, double height) =>
    _isMobileProfile(context) ? height : null;

Color _profileSecondary(BuildContext context) => _isMobileProfile(context)
    ? Color.lerp(AppColors.textSecondary, AppColors.textPrimary, .2)!
    : AppColors.textSecondary;

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();
  @override
  Widget build(BuildContext context) => const Center(
    key: Key('profile-loading'),
    child: CircularProgressIndicator(),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({
    required this.kind,
    required this.onRetry,
    required this.onBack,
  });
  final ReligiousProfileFailureKind? kind;
  final VoidCallback onRetry, onBack;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load this profile',
            style: AppTypography.responsive(context).titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_failureMessage(kind), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(onPressed: onBack, child: const Text('Back')),
              FilledButton.icon(
                key: const Key('profile-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _body(bool failed, bool empty, String message, Widget child) => failed
    ? const _Empty('This information is temporarily unavailable.')
    : empty
    ? _Empty(message)
    : child;
String _failureMessage(ReligiousProfileFailureKind? kind) => switch (kind) {
  ReligiousProfileFailureKind.network =>
    'Please check your connection and try again.',
  ReligiousProfileFailureKind.authentication =>
    'Your session could not be verified. Please sign in again.',
  ReligiousProfileFailureKind.permission =>
    'Your account does not currently have access to this profile.',
  ReligiousProfileFailureKind.notFound =>
    'This member profile could not be found.',
  _ => 'The profile is temporarily unavailable. Please try again.',
};
IconData _contactIcon(String label, String value) {
  final text = '$label $value'.toLowerCase();
  if (text.contains('@')) return Icons.mail_outline_rounded;
  if (text.contains('address') || text.contains('home')) {
    return Icons.location_on_outlined;
  }
  return Icons.phone_outlined;
}

bool _isFormationRole(String? role) => const {
  'student',
  'novice master',
  'scholastic master',
  'formation staff',
}.contains(role?.toLowerCase());
DateTime? _recordedSince(ReligiousProfile p) {
  final dates = <DateTime>[
    ...p.sections.vocationEvents.map((e) => e.date).whereType<DateTime>(),
    ...p.sections.communityAssignments
        .map((e) => e.fromDate)
        .whereType<DateTime>(),
    ...p.sections.ministryAssignments
        .map((e) => e.fromDate)
        .whereType<DateTime>(),
    ...p.sections.offices.map((e) => e.fromDate).whereType<DateTime>(),
  ]..sort();
  return dates.firstOrNull;
}

String? _serviceSpan(ReligiousProfile p) {
  final start = _recordedSince(p);
  if (start == null) return null;
  final months = (DateTime.now().difference(start).inDays / 30.44).floor();
  return '${months ~/ 12}y ${months % 12}m';
}

String? _dateRange(DateTime? from, DateTime? to) {
  if (from == null && to == null) return null;
  return '${_date(from)} – ${to == null ? 'Present' : _date(to)}';
}

({String label, Color color}) _timelineCategoryStyle(
  MemberTimelineCategory category,
) => switch (category) {
  MemberTimelineCategory.vocation => (
    label: 'Vocation',
    color: AppColors.purple,
  ),
  MemberTimelineCategory.community => (
    label: 'Community',
    color: AppColors.info,
  ),
  MemberTimelineCategory.ministry => (
    label: 'Ministry',
    color: AppColors.success,
  ),
  MemberTimelineCategory.office => (
    label: 'Leadership',
    color: AppColors.warning,
  ),
  MemberTimelineCategory.leave => (label: 'Leave', color: AppColors.secondary),
};

String _timelineDateRange(MemberTimelineEvent event) {
  final start = event.startDate;
  final end = event.endDate;
  if (start == null && end == null) return 'Date not recorded';
  final startText = start == null
      ? null
      : _timelineDate(start, event.startPrecision);
  if (event.isCurrent && end == null) return '$startText – Present';
  if (end == null) return startText ?? _timelineDate(end!, event.endPrecision);
  final endText = _timelineDate(end, event.endPrecision);
  if (startText == null) return endText;
  if (startText == endText) return startText;
  return '$startText – $endText';
}

String _timelineDate(
  DateTime date,
  TimelineDatePrecision precision,
) => switch (precision) {
  TimelineDatePrecision.year => '${date.year}',
  TimelineDatePrecision.month =>
    '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1]} ${date.year}',
  TimelineDatePrecision.day =>
    '${date.day} ${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1]} ${date.year}',
};

String _date(DateTime? date) => date == null
    ? '—'
    : '${date.day.toString().padLeft(2, '0')} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
String _profileInitials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where(
      (word) =>
          word.isNotEmpty &&
          !RegExp(r'^(bro|fr|dcn)\.?$', caseSensitive: false).hasMatch(word),
    )
    .take(2)
    .map((word) => word[0])
    .join()
    .toUpperCase();

class _InfoData {
  const _InfoData(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label, value;
  final Color color;
}

class _MetricData {
  const _MetricData(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value, label;
  final Color color;
}
