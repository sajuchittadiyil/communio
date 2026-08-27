import 'package:flutter/material.dart';

import '../../../app/shell/models/app_navigation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/contact_action_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_models.dart';
import '../state/dashboard_controller.dart';
import '../widgets/province_pulse_header.dart';
import '../widgets/quick_overview.dart';
import '../widgets/recent_updates_card.dart';
import '../widgets/todays_focus_card.dart';
import '../widgets/dashboard_card.dart';
import '../../ask_communio/widgets/ask_communio_entry_card.dart';
import '../../organization_identity/data/organization_identity_repository.dart';
import '../widgets/congregation_identity_card.dart';

class ProvincialDashboardScreen extends StatefulWidget {
  const ProvincialDashboardScreen({
    required this.displayName,
    required this.onNavigate,
    required this.repository,
    required this.onMemberId,
    required this.onFormationFilter,
    required this.organizationIdentityRepository,
    this.onAskCommunio,
    super.key,
  });

  final String displayName;
  final ValueChanged<AppDestination> onNavigate;
  final DashboardRepository repository;
  final ValueChanged<String> onMemberId;
  final ValueChanged<String?> onFormationFilter;
  final OrganizationIdentityRepository organizationIdentityRepository;
  final VoidCallback? onAskCommunio;

  @override
  State<ProvincialDashboardScreen> createState() =>
      _ProvincialDashboardScreenState();
}

class _ProvincialDashboardScreenState extends State<ProvincialDashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(widget.repository)
      ..addListener(_refresh)
      ..load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 600;
      final desktop = constraints.maxWidth >= 1100;
      final pagePadding = mobile ? AppSpacing.lg : AppSpacing.xxxl;

      return SingleChildScrollView(
        padding: mobile
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              )
            : EdgeInsets.all(pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProvincePulseHeader(displayName: widget.displayName),
                SizedBox(height: mobile ? AppSpacing.md : AppSpacing.lg),
                CongregationIdentityCard(
                  repository: widget.organizationIdentityRepository,
                  onNavigate: widget.onNavigate,
                ),
                SizedBox(height: mobile ? AppSpacing.md : AppSpacing.lg),
                if (widget.onAskCommunio != null) ...[
                  AskCommunioEntryCard(onTap: widget.onAskCommunio!),
                  SizedBox(height: mobile ? AppSpacing.md : AppSpacing.lg),
                ],
                _pulseContent(context, mobile: mobile, desktop: desktop),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _pulseContent(
    BuildContext context, {
    required bool mobile,
    required bool desktop,
  }) {
    if (_controller.status == DashboardStatus.loading) {
      return const _DashboardLoading();
    }
    if (_controller.status == DashboardStatus.error) {
      return _DashboardError(onRetry: _controller.load);
    }
    final snapshot = _controller.snapshot!;
    final attention = snapshot.attention
        .map(
          (event) => FocusItem(
            title: event.memberName,
            primaryDetail: event.title,
            secondaryDetail:
                '${event.timing.toUpperCase()} · ${_dateRange(event)}${event.location == null ? '' : ' · ${event.location}'}',
            memberId: event.memberId,
            photoUrl: event.photoUrl,
            emphasized: event.isHighPriority,
            icon: event.icon,
            accent: event.accent,
          ),
        )
        .toList();
    final overview = QuickOverview(
      metrics: snapshot.metrics,
      onSelected: (index) => _openOverview(index, context),
    );
    final recentUpdates = RecentUpdatesCard(
      title: 'RECENT UPDATES',
      emptyMessage: 'No recent Province updates available',
      items: snapshot.recentUpdates,
      compact: mobile,
      onViewAll: () => widget.onNavigate(AppDestination.documents),
    );
    final celebrations = _CelebrationsCard(
      items: snapshot.celebrations,
      onMember: widget.onMemberId,
      compact: mobile,
    );
    final movements = _EventListCard(
      title: 'MEMBER MOVEMENTS',
      icon: Icons.explore_outlined,
      sectionAccent: AppColors.cyan,
      items: snapshot.movements,
      emptyMessage: 'No members currently away from assignment.',
      onMember: widget.onMemberId,
      compact: mobile,
    );
    final attentionCard = TodaysFocusCard(
      title: 'PROVINCE ATTENTION',
      items: attention,
      onPlaceholder: () {},
      onSelected: (item) {
        if (item.memberId != null) widget.onMemberId(item.memberId!);
      },
    );
    final upcomingEvents = _EventListCard(
      title: 'UPCOMING EVENTS',
      icon: Icons.account_balance_outlined,
      sectionAccent: AppColors.secondaryDark,
      items: snapshot.upcomingEvents,
      emptyMessage: 'No upcoming governance or regulatory events.',
      onMember: widget.onMemberId,
      compact: mobile,
    );
    final gap = SizedBox(height: mobile ? AppSpacing.md : AppSpacing.lg);
    return Column(
      children: [
        _TodayAtAGlance(
          celebrations: snapshot.celebrations.length,
          movements: snapshot.movements.length,
          attention: snapshot.attention.length,
          events: snapshot.upcomingEvents.length,
          onCelebrations: () => widget.onNavigate(AppDestination.calendar),
          onEvents: () => widget.onNavigate(AppDestination.calendar),
        ),
        gap,
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: celebrations),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: movements),
            ],
          )
        else ...[
          celebrations,
          if (attention.isNotEmpty) ...[gap, attentionCard],
          gap,
          movements,
        ],
        if (desktop && attention.isNotEmpty) ...[gap, attentionCard],
        gap,
        upcomingEvents,
        gap,
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: overview),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: recentUpdates),
            ],
          )
        else ...[
          overview,
          gap,
          recentUpdates,
        ],
      ],
    );
  }

  void _openOverview(int index, BuildContext context) {
    final destination = switch (index) {
      0 => AppDestination.religious,
      1 => AppDestination.communities,
      2 => AppDestination.ministries,
      3 => AppDestination.formation,
      4 || 5 || 6 => AppDestination.formation,
      7 => AppDestination.governance,
      _ => null,
    };
    if (destination == null) {
      return;
    } else {
      if (index >= 4 && index <= 6) {
        widget.onFormationFilter(
          const ['Candidate', 'Novice', 'Temp. Professed'][index - 4],
        );
        return;
      }
      widget.onNavigate(destination);
    }
  }
}

class _CelebrationsCard extends StatelessWidget {
  const _CelebrationsCard({
    required this.items,
    required this.onMember,
    this.compact = false,
  });
  final List<CelebrationItem> items;
  final ValueChanged<String> onMember;
  final bool compact;

  @override
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      children: [
        const DashboardSectionHeader(
          title: 'CELEBRATIONS',
          icon: Icons.celebration_outlined,
          accent: AppColors.secondaryDark,
        ),
        if (items.isEmpty)
          const _CompactEmpty('No celebrations in the next 30 days.'),
        for (final item in items.take(compact ? 4 : 6))
          _CompactRow(
            icon: item.icon,
            accent: item.accent,
            title: item.memberName,
            memberId: item.memberId,
            photoUrl: item.photoUrl,
            detail:
                '${item.kind} ${_relativeDay(item.daysUntil)}${item.detail == null ? '' : ' · ${item.detail}'}',
            onTap: item.memberId == null
                ? null
                : () => onMember(item.memberId!),
            actions: [
              if (_hasText(item.mobile))
                ContactActionButton(
                  type: ContactActionType.call,
                  value: item.mobile!,
                  personName: item.memberName,
                ),
              if (_hasText(item.whatsApp))
                ContactActionButton(
                  type: ContactActionType.whatsApp,
                  value: item.whatsApp!,
                  personName: item.memberName,
                ),
            ],
          ),
      ],
    ),
  );
}

class _EventListCard extends StatelessWidget {
  const _EventListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.emptyMessage,
    required this.onMember,
    required this.sectionAccent,
    this.compact = false,
  });
  final String title;
  final IconData icon;
  final Color sectionAccent;
  final List<PulseEvent> items;
  final String emptyMessage;
  final ValueChanged<String> onMember;
  final bool compact;

  @override
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      children: [
        DashboardSectionHeader(title: title, icon: icon, accent: sectionAccent),
        if (items.isEmpty) _CompactEmpty(emptyMessage),
        for (final item in items.take(compact ? 4 : 6))
          _CompactRow(
            icon: item.icon,
            accent: item.accent,
            title: item.memberName,
            memberId: item.memberId,
            photoUrl: item.photoUrl,
            detail:
                '${item.title}${item.location == null ? '' : ' · ${item.location}'} · ${item.isCurrent ? 'Until ${_shortDate(item.toDate)}' : _shortDate(item.fromDate)}',
            onTap: item.memberId == null
                ? null
                : () => onMember(item.memberId!),
          ),
      ],
    ),
  );
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.detail,
    this.memberId,
    this.photoUrl,
    this.onTap,
    this.actions = const [],
  });
  final IconData icon;
  final Color accent;
  final String title;
  final String detail;
  final String? memberId;
  final String? photoUrl;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          memberId == null
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MemberAvatar(
                      name: title,
                      photoUrl: photoUrl,
                      radius: 22,
                      backgroundColor: accent.withValues(alpha: .1),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.surface,
                        child: Icon(icon, size: 11, color: accent),
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
                  title,
                  style: AppTypography.responsive(context).labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.responsive(
                    context,
                  ).labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ...actions,
          if (onTap != null && actions.isEmpty)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    ),
  );
}

class _TodayAtAGlance extends StatelessWidget {
  const _TodayAtAGlance({
    required this.celebrations,
    required this.movements,
    required this.attention,
    required this.events,
    required this.onCelebrations,
    required this.onEvents,
  });

  final int celebrations;
  final int movements;
  final int attention;
  final int events;
  final VoidCallback onCelebrations;
  final VoidCallback onEvents;

  @override
  Widget build(BuildContext context) => DashboardCard(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY AT A GLANCE',
          style: AppTypography.responsive(
            context,
          ).labelMedium.copyWith(color: AppColors.primary, letterSpacing: .4),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _GlanceItem(
                value: celebrations,
                label: 'Celebrations',
                accent: AppColors.purple,
                onTap: onCelebrations,
              ),
            ),
            Expanded(
              child: _GlanceItem(
                value: movements,
                label: 'Away',
                accent: AppColors.cyan,
              ),
            ),
            Expanded(
              child: _GlanceItem(
                value: attention,
                label: 'Attention',
                accent: attention > 0 ? AppColors.error : AppColors.success,
              ),
            ),
            Expanded(
              child: _GlanceItem(
                value: events,
                label: 'Events',
                accent: AppColors.secondaryDark,
                onTap: onEvents,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _GlanceItem extends StatelessWidget {
  const _GlanceItem({
    required this.value,
    required this.label,
    required this.accent,
    this.onTap,
  });

  final int value;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.responsive(
              context,
            ).titleSmall.copyWith(color: accent),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.responsive(
              context,
            ).labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: AppTypography.responsive(
          context,
        ).bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    ),
  );
}

String _dateRange(PulseEvent event) {
  final from = _shortDate(event.fromDate);
  final to = _shortDate(event.toDate);
  return event.toDate == null || from == to ? from : '$from–$to';
}

String _shortDate(DateTime? date) => date == null
    ? 'Date unavailable'
    : '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]}';

String _relativeDay(int days) => switch (days) {
  0 => 'today',
  1 => 'tomorrow',
  _ => 'in $days days',
};

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(
    key: Key('dashboard-loading'),
    height: 180,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      children: [
        const Text('Province data is temporarily unavailable.'),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          key: const Key('dashboard-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
