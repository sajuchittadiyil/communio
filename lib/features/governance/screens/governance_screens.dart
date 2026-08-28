import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/module_background.dart';
import '../data/governance_repository.dart';
import '../models/governance_models.dart';

typedef GovernanceMemberOpener = ValueChanged<GovernanceMembership>;

class GovernanceDirectoryScreen extends StatefulWidget {
  const GovernanceDirectoryScreen({
    required this.repository,
    required this.onMember,
    super.key,
  });

  final GovernanceRepository repository;
  final GovernanceMemberOpener onMember;

  @override
  State<GovernanceDirectoryScreen> createState() =>
      _GovernanceDirectoryScreenState();
}

class _GovernanceDirectoryScreenState extends State<GovernanceDirectoryScreen> {
  late Future<List<GovernanceBody>> _load;

  @override
  void initState() {
    super.initState();
    _load = widget.repository.fetchBodies();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GovernanceBody>>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _GovernanceMessage(
          title: 'Governance bodies could not be loaded',
          message: 'Please try again when a secure connection is available.',
          action: () => setState(() => _load = widget.repository.fetchBodies()),
        );
      }
      final bodies = snapshot.data ?? const [];
      if (bodies.isEmpty) {
        return const _GovernanceMessage(
          title: 'No governance bodies recorded',
          message: 'No governance bodies are available for this Province.',
        );
      }
      return _GovernanceDirectory(
        bodies: bodies,
        onBody: (body) => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => GovernanceBodyProfileScreen(
              body: body,
              onMember: widget.onMember,
            ),
          ),
        ),
      );
    },
  );
}

class _GovernanceDirectory extends StatelessWidget {
  const _GovernanceDirectory({required this.bodies, required this.onBody});

  final List<GovernanceBody> bodies;
  final ValueChanged<GovernanceBody> onBody;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth >= 900
          ? AppSpacing.xxxl
          : AppSpacing.lg;
      final columns = constraints.maxWidth >= 1200
          ? 3
          : constraints.maxWidth >= 680
          ? 2
          : 1;
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      return CustomScrollView(
        key: const Key('governance-directory-scroll'),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.xxl,
              horizontal,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Governance Bodies',
                    style: AppTypography.responsive(context).headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Councils and commissions serving the Province',
                    style: AppTypography.responsive(
                      context,
                    ).bodyLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.md,
              horizontal,
              AppSpacing.xxxl,
            ),
            sliver: SliverGrid.builder(
              itemCount: bodies.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
                mainAxisExtent: 310 + (textScale - 1).clamp(0, 1) * 200,
              ),
              itemBuilder: (context, index) => _GovernanceBodyCard(
                body: bodies[index],
                onTap: () => onBody(bodies[index]),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _GovernanceBodyCard extends StatelessWidget {
  const _GovernanceBodyCard({required this.body, required this.onTap});

  final GovernanceBody body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final members = body.currentMemberships();
    final leader = body.currentLeader();
    return Card(
      key: Key('governance-body-${body.code}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      body.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.responsive(context).titleLarge,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusBadge(label: body.statusLabel),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body.typeLabel,
                style: AppTypography.responsive(
                  context,
                ).labelLarge.copyWith(color: AppColors.secondaryDark),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                body.purpose ?? body.description ?? 'Purpose not recorded.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.responsive(
                  context,
                ).bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                leader == null
                    ? 'No chair is currently recorded.'
                    : '${leader.roleLabel}: ${leader.displayName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.responsive(context).labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    size: AppSpacing.xl,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      members.length == 1
                          ? '1 current member'
                          : '${members.length} current members',
                      style: AppTypography.responsive(context).bodyMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GovernanceBodyProfileScreen extends StatelessWidget {
  const GovernanceBodyProfileScreen({
    required this.body,
    required this.onMember,
    super.key,
  });

  final GovernanceBody body;
  final GovernanceMemberOpener onMember;

  @override
  Widget build(BuildContext context) {
    final current = body.currentMemberships();
    final history = body.historicalMemberships();
    final leaders = current.where((member) => member.isLeadership).toList();
    final secretaries = current
        .where((member) => member.roleCode == 'SECRETARY')
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(body.name)),
      body: ModuleBackground(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const Key('governance-profile-scroll'),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth >= 900
                  ? AppSpacing.xxxl
                  : AppSpacing.lg,
              vertical: AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(body: body),
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileSection(
                      title: 'Current Leadership',
                      child: leaders.isEmpty && secretaries.isEmpty
                          ? const Text('No chair is currently recorded.')
                          : Column(
                              children: [
                                ...leaders.map(
                                  (member) => _MembershipTile(
                                    membership: member,
                                    onTap: () => onMember(member),
                                  ),
                                ),
                                ...secretaries.map(
                                  (member) => _MembershipTile(
                                    membership: member,
                                    onTap: () => onMember(member),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileSection(
                      title: 'Current Members',
                      child: current.isEmpty
                          ? const Text(
                              'No current members are recorded for this governance body.',
                            )
                          : Column(
                              children: current
                                  .map(
                                    (member) => _MembershipTile(
                                      membership: member,
                                      onTap: () => onMember(member),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileSection(
                      title: 'Membership History',
                      child: history.isEmpty
                          ? const Text(
                              'No historical membership is recorded for this governance body.',
                            )
                          : Column(
                              children: history
                                  .map(
                                    (member) => _MembershipTile(
                                      membership: member,
                                      onTap: () => onMember(member),
                                      historical: true,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.body});
  final GovernanceBody body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                body.name,
                style: AppTypography.responsive(context).headlineSmall,
              ),
              _StatusBadge(label: body.statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body.typeLabel,
            style: AppTypography.responsive(
              context,
            ).labelLarge.copyWith(color: AppColors.secondaryDark),
          ),
          if (body.purpose case final purpose?) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(purpose, style: AppTypography.responsive(context).bodyLarge),
          ],
          if (body.description case final description?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTypography.responsive(
                context,
              ).bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.responsive(context).titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    ),
  );
}

class _MembershipTile extends StatelessWidget {
  const _MembershipTile({
    required this.membership,
    required this.onTap,
    this.historical = false,
  });
  final GovernanceMembership membership;
  final VoidCallback onTap;
  final bool historical;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: MemberAvatar(
      name: membership.displayName,
      photoUrl: membership.photoUrl,
      radius: AppSpacing.xl,
      backgroundColor: AppColors.primary.withValues(alpha: .08),
      foregroundColor: AppColors.primary,
    ),
    title: Text(membership.displayName),
    subtitle: Text(
      '${membership.roleLabel} · ${formatGovernanceTerm(membership)}',
      maxLines: 2,
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: membership.memberId.isEmpty ? null : onTap,
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.responsive(
          context,
        ).labelSmall.copyWith(color: AppColors.success),
      ),
    ),
  );
}

class _GovernanceMessage extends StatelessWidget {
  const _GovernanceMessage({
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_outlined, size: AppSpacing.massive),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.responsive(context).titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(
              onPressed: action,
              child: const Text('Try again'),
            ),
          ],
        ],
      ),
    ),
  );
}

String formatGovernanceTerm(GovernanceMembership membership) =>
    '${_formatDate(membership.startDate)} – '
    '${membership.endDate == null ? 'Present' : _formatDate(membership.endDate!)}';

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
