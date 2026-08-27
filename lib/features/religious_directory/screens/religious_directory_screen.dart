import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/contact_action_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../data/member_directory_repository.dart';
import '../models/member_directory_entry.dart';
import '../state/member_directory_controller.dart';

class ReligiousDirectoryScreen extends StatefulWidget {
  const ReligiousDirectoryScreen({
    required this.repository,
    this.onMemberSelected,
    this.heading = 'Members of the Province',
    this.emptyTitle = 'The directory is empty',
    super.key,
  });

  final MemberDirectoryRepository repository;
  final ValueChanged<MemberDirectoryEntry>? onMemberSelected;
  final String heading;
  final String emptyTitle;

  @override
  State<ReligiousDirectoryScreen> createState() =>
      _ReligiousDirectoryScreenState();
}

class _ReligiousDirectoryScreenState extends State<ReligiousDirectoryScreen> {
  late final MemberDirectoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MemberDirectoryController(widget.repository)
      ..addListener(_refresh);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 768;
      final padding = mobile ? AppSpacing.lg : AppSpacing.xxxl;
      return ColoredBox(
        color: AppColors.transparent,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      mobile ? AppSpacing.lg : AppSpacing.xxl,
                      padding,
                      AppSpacing.max,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _Heading(
                          label: widget.heading,
                          count:
                              _controller.status == MemberDirectoryStatus.ready
                              ? _controller.visibleMembers.length
                              : null,
                          total:
                              _controller.status == MemberDirectoryStatus.ready
                              ? _controller.totalCount
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _Controls(
                          controller: _controller,
                          mobile: mobile,
                          onFilter: () => _showFilters(mobile),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _content(mobile),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _content(bool mobile) => switch (_controller.status) {
    MemberDirectoryStatus.loading => const _LoadingState(),
    MemberDirectoryStatus.error => _MessageState(
      icon: Icons.cloud_off_outlined,
      title: 'Unable to load the directory',
      message: _errorMessage,
      action: FilledButton.icon(
        onPressed: _controller.load,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    ),
    MemberDirectoryStatus.ready when _controller.visibleMembers.isEmpty =>
      _MessageState(
        icon: Icons.person_search_outlined,
        title:
            _controller.search.isNotEmpty || _controller.filters.activeCount > 0
            ? 'No members match your filters'
            : widget.emptyTitle,
        message: 'Try changing your search or clearing the active filters.',
        action: _controller.filters.activeCount > 0
            ? TextButton(
                onPressed: _controller.clearFilters,
                child: const Text('Clear filters'),
              )
            : null,
      ),
    MemberDirectoryStatus.ready =>
      mobile
          ? Column(
              children: _controller.visibleMembers
                  .map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _MobileMemberCard(
                        member: member,
                        onTap: () => _select(member),
                      ),
                    ),
                  )
                  .toList(),
            )
          : _DesktopMemberList(
              members: _controller.visibleMembers,
              onSelected: _select,
            ),
  };

  String get _errorMessage => switch (_controller.failureKind) {
    MemberDirectoryFailureKind.network =>
      'Please check your connection and try again.',
    MemberDirectoryFailureKind.authentication =>
      'Your session could not be verified. Please sign in again.',
    MemberDirectoryFailureKind.permission =>
      'Your account does not currently have access to the directory.',
    MemberDirectoryFailureKind.schemaQuery ||
    MemberDirectoryFailureKind.unexpected ||
    null => 'The directory is temporarily unavailable. Please try again.',
  };

  void _select(MemberDirectoryEntry member) {
    if (widget.onMemberSelected case final callback?) {
      callback(member);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MemberProfilePlaceholder(member: member),
      ),
    );
  }

  Future<void> _showFilters(bool mobile) async {
    final child = _FilterPanel(
      controller: _controller,
      onApply: (filters) {
        _controller.setFilters(filters);
        Navigator.pop(context);
      },
    );
    if (mobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          alignment: Alignment.topRight,
          insetPadding: const EdgeInsets.only(
            top: AppSpacing.max,
            right: AppSpacing.xxxl,
          ),
          child: SizedBox(width: 400, child: child),
        ),
      );
    }
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.label,
    required this.count,
    required this.total,
  });
  final String label;
  final int? count;
  final int? total;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.responsive(
            context,
          ).bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
      if (count != null)
        Text(
          count == total
              ? '$count ${count == 1 ? 'member' : 'members'}'
              : '$count of $total members',
          key: const Key('member-count'),
          style: AppTypography.responsive(
            context,
          ).labelLarge.copyWith(color: AppColors.secondaryDark),
        ),
    ],
  );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.mobile,
    required this.onFilter,
  });
  final MemberDirectoryController controller;
  final bool mobile;
  final VoidCallback onFilter;
  @override
  Widget build(BuildContext context) {
    final search = TextField(
      key: const Key('directory-search'),
      onChanged: controller.setSearch,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search_rounded),
        hintText: 'Search members, community, assignment or state',
      ),
    );
    final buttons = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        Badge(
          isLabelVisible: controller.filters.activeCount > 0,
          label: Text('${controller.filters.activeCount}'),
          child: OutlinedButton.icon(
            key: const Key('filter-button'),
            onPressed: onFilter,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Filters'),
          ),
        ),
        DropdownButton<MemberDirectorySort>(
          key: const Key('sort-control'),
          value: controller.sort,
          underline: const SizedBox(),
          icon: const Icon(Icons.sort_rounded),
          onChanged: (value) {
            if (value != null) controller.setSort(value);
          },
          items: const [
            DropdownMenuItem(
              value: MemberDirectorySort.nameAscending,
              child: Text('Name A–Z'),
            ),
            DropdownMenuItem(
              value: MemberDirectorySort.nameDescending,
              child: Text('Name Z–A'),
            ),
            DropdownMenuItem(
              value: MemberDirectorySort.community,
              child: Text('Community'),
            ),
            DropdownMenuItem(
              value: MemberDirectorySort.memberStatus,
              child: Text('Member Status'),
            ),
          ],
        ),
      ],
    );
    return mobile
        ? Column(
            children: [
              search,
              const SizedBox(height: AppSpacing.md),
              Align(alignment: Alignment.centerRight, child: buttons),
            ],
          )
        : Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: AppSpacing.lg),
              buttons,
            ],
          );
  }
}

class _DesktopMemberList extends StatelessWidget {
  const _DesktopMemberList({required this.members, required this.onSelected});
  final List<MemberDirectoryEntry> members;
  final ValueChanged<MemberDirectoryEntry> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      children: [
        const _DirectoryRow(header: true),
        for (final member in members)
          _DirectoryRow(member: member, onTap: () => onSelected(member)),
      ],
    ),
  );
}

class _DirectoryRow extends StatelessWidget {
  const _DirectoryRow({this.member, this.header = false, this.onTap});
  final MemberDirectoryEntry? member;
  final bool header;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    Widget cell(String value, int flex) => Expanded(
      flex: flex,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: header
            ? AppTypography.responsive(
                context,
              ).labelMedium.copyWith(color: AppColors.textSecondary)
            : AppTypography.responsive(context).bodyMedium,
      ),
    );
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: header
            ? [
                cell('MEMBER', 4),
                cell('COMMUNITY', 3),
                cell('COMMUNITY ROLE', 3),
                cell('MINISTRY / ASSIGNMENT', 4),
                cell('STATUS', 2),
                const SizedBox(width: AppSpacing.xxl),
              ]
            : [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      _Avatar(member: member!),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          member!.titledName,
                          style: AppTypography.responsive(context).labelLarge
                              .copyWith(
                                color: member!.isDeceased
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._contactActions(member!),
                    ],
                  ),
                ),
                cell(member!.community ?? '—', 3),
                cell(member!.communityRole ?? '—', 3),
                cell(member!.ministryAssignment ?? '—', 4),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusChip(status: member!.directoryStatus),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
      ),
    );
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        key: member == null ? null : Key('member-row-${member!.id}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: member == null
                ? null
                : LinearGradient(
                    colors: [
                      _memberAccent(member!).withValues(alpha: .03),
                      AppColors.surface,
                    ],
                  ),
            border: const Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: row,
        ),
      ),
    );
  }
}

class _MobileMemberCard extends StatelessWidget {
  const _MobileMemberCard({required this.member, required this.onTap});
  final MemberDirectoryEntry member;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.transparent,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: InkWell(
      key: Key('member-card-${member.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _memberAccent(member).withValues(alpha: .045),
              AppColors.dashboardIvory,
              AppColors.dashboardWarmCream,
            ],
            stops: const [0, .42, 1],
          ),
          border: Border.all(
            color: _memberAccent(member).withValues(alpha: .38),
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: _memberAccent(member).withValues(alpha: .07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(member: member),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.titledName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.responsive(context).labelLarge
                        .copyWith(
                          color: member.isDeceased
                              ? AppColors.textSecondary
                              : _memberNameColor(member),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_contactActions(member).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: _contactActions(member),
                    ),
                  ],
                  if (member.community != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      member.community!,
                      style: AppTypography.responsive(
                        context,
                      ).bodyMedium.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (member.communityRole != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      member.communityRole!,
                      style: AppTypography.responsive(
                        context,
                      ).bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (member.ministryAssignment case final assignment?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      assignment,
                      style: AppTypography.responsive(
                        context,
                      ).bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  _StatusChip(status: member.directoryStatus),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _memberAccent(member).withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: _memberAccent(member),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

List<Widget> _contactActions(MemberDirectoryEntry member) => [
  if (_hasText(member.mobile))
    ContactActionButton(
      type: ContactActionType.call,
      value: member.mobile!,
      personName: member.titledName,
    ),
  if (_hasText(member.whatsApp))
    ContactActionButton(
      type: ContactActionType.whatsApp,
      value: member.whatsApp!,
      personName: member.titledName,
    ),
  if (_hasText(member.officialEmail))
    ContactActionButton(
      type: ContactActionType.email,
      value: member.officialEmail!,
      personName: member.titledName,
    ),
];

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

Color _memberAccent(MemberDirectoryEntry member) {
  final role = member.communityRole?.toLowerCase() ?? '';
  final status = member.directoryStatus.toLowerCase();
  if (member.isDeceased) return AppColors.textSecondary;
  if (role.contains('superior')) return AppColors.purple;
  if (role.contains('accountant') || role.contains('bursar')) {
    return AppColors.secondaryDark;
  }
  if (status.contains('formation') ||
      status.contains('novice') ||
      status.contains('professed')) {
    return AppColors.cyan;
  }
  return AppColors.primary;
}

Color _memberNameColor(MemberDirectoryEntry member) {
  final role = member.communityRole?.toLowerCase() ?? '';
  final status = member.directoryStatus.toLowerCase();

  if (member.isDeceased) return AppColors.textSecondary;

  if (role.contains('superior')) {
    return AppColors.secondaryDark;
  }

  if (role.contains('accountant') || role.contains('bursar')) {
    return AppColors.purple;
  }

  // Formation cards already use cyan as their visual accent.
  // Keep member names dark for stronger contrast and readability.
  if (status.contains('formation') ||
      status.contains('novice') ||
      status.contains('candidate') ||
      status.contains('professed')) {
    return AppColors.primary;
  }

  return AppColors.primary;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});
  final MemberDirectoryEntry member;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: _memberAccent(member),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: _memberAccent(member).withValues(alpha: .14),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: MemberAvatar(
      name: member.displayName,
      photoUrl: member.photoUrl,
      initials: member.initials,
      radius: 25,
      backgroundColor: AppColors.surface,
      initialsStyle: AppTypography.responsive(context).labelLarge.copyWith(
        color: _memberAccent(member),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final color = lower.contains('deceased')
        ? AppColors.textSecondary
        : lower.contains('active')
        ? AppColors.success
        : lower.contains('leave')
        ? AppColors.warning
        : AppColors.primary;
    return Container(
      key: Key('status-${lower.replaceAll(' ', '-')}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status,
        style: AppTypography.responsive(
          context,
        ).labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Column(
    key: const Key('directory-loading'),
    children: List.generate(
      5,
      (_) => Container(
        height: AppSpacing.ultra,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.jumbo),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: AppSpacing.massive, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.responsive(context).titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.responsive(
              context,
            ).bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({required this.controller, required this.onApply});
  final MemberDirectoryController controller;
  final ValueChanged<MemberDirectoryFilters> onApply;
  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late MemberDirectoryFilters value = widget.controller.filters;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xxl),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter members',
                  style: AppTypography.responsive(context).titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          _dropdown(
            'Member Status',
            value.memberStatus,
            widget.controller.options((m) => m.memberStatus),
            (v) => value = MemberDirectoryFilters(
              memberStatus: v,
              canonicalStatus: value.canonicalStatus,
              community: value.community,
              state: value.state,
              ministry: value.ministry,
            ),
          ),
          _dropdown(
            'Canonical Status',
            value.canonicalStatus,
            widget.controller.options((m) => m.canonicalStatus ?? ''),
            (v) => value = MemberDirectoryFilters(
              memberStatus: value.memberStatus,
              canonicalStatus: v,
              community: value.community,
              state: value.state,
              ministry: value.ministry,
            ),
          ),
          _dropdown(
            'Community',
            value.community,
            widget.controller.options((m) => m.community ?? ''),
            (v) => value = MemberDirectoryFilters(
              memberStatus: value.memberStatus,
              canonicalStatus: value.canonicalStatus,
              community: v,
              state: value.state,
              ministry: value.ministry,
            ),
          ),
          _dropdown(
            'State',
            value.state,
            widget.controller.options((m) => m.nativeState ?? ''),
            (v) => value = MemberDirectoryFilters(
              memberStatus: value.memberStatus,
              canonicalStatus: value.canonicalStatus,
              community: value.community,
              state: v,
              ministry: value.ministry,
            ),
          ),
          _dropdown(
            'Current Assignment / Ministry',
            value.ministry,
            widget.controller.options((m) => m.ministryAssignment ?? ''),
            (v) => value = MemberDirectoryFilters(
              memberStatus: value.memberStatus,
              canonicalStatus: value.canonicalStatus,
              community: value.community,
              state: value.state,
              ministry: v,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    setState(() => value = const MemberDirectoryFilters()),
                child: const Text('Clear filters'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => widget.onApply(value),
                child: const Text('Apply filters'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _dropdown(
    String label,
    String? selected,
    List<String> options,
    ValueChanged<String?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...options.map(
          (option) => DropdownMenuItem(value: option, child: Text(option)),
        ),
      ],
      onChanged: (v) {
        changed(v);
        setState(() {});
      },
    ),
  );
}

class _MemberProfilePlaceholder extends StatelessWidget {
  const _MemberProfilePlaceholder({required this.member});
  final MemberDirectoryEntry member;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Member profile')),
    body: Center(
      child: Semantics(
        label: 'Member ID ${member.id}',
        child: Text(
          member.titledName,
          textAlign: TextAlign.center,
          style: AppTypography.responsive(context).titleLarge,
        ),
      ),
    ),
  );
}
