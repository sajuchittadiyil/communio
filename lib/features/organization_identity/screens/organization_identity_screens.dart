import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/contact_action_button.dart';
import '../../../core/widgets/member_avatar.dart';
import '../data/organization_identity_repository.dart';
import '../models/organization_identity_models.dart';

enum OrganizationIdentityPage { congregation, leadership, province }

class OrganizationIdentityScreen extends StatefulWidget {
  const OrganizationIdentityScreen({
    required this.repository,
    required this.page,
    this.onProvinceLeader,
    super.key,
  });

  final OrganizationIdentityRepository repository;
  final OrganizationIdentityPage page;
  final ValueChanged<ProvinceLeader>? onProvinceLeader;

  @override
  State<OrganizationIdentityScreen> createState() =>
      _OrganizationIdentityScreenState();
}

class _OrganizationIdentityScreenState
    extends State<OrganizationIdentityScreen> {
  late Future<OrganizationIdentitySnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchIdentity();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<OrganizationIdentitySnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return _LoadFailure(
              onRetry: () =>
                  setState(() => _future = widget.repository.fetchIdentity()),
            );
          }
          final data = snapshot.requireData;
          return switch (widget.page) {
            OrganizationIdentityPage.congregation => _CongregationProfileView(
              profile: data.congregation,
              leaders: data.leaders,
              province: data.province,
            ),
            OrganizationIdentityPage.leadership => _LeadershipView(
              leaders: data.leaders,
            ),
            OrganizationIdentityPage.province => _ProvinceProfileView(
              profile: data.province,
              leaders: data.provincialLeaders,
              onLeader: widget.onProvinceLeader,
            ),
          };
        },
      );
}

class _PageCanvas extends StatelessWidget {
  const _PageCanvas({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: SelectionArea(child: child),
      ),
    ),
  );
}

class _CongregationProfileView extends StatelessWidget {
  const _CongregationProfileView({
    required this.profile,
    required this.leaders,
    required this.province,
  });
  final CongregationProfile profile;
  final List<CongregationLeader> leaders;
  final ProvinceProfile province;

  @override
  Widget build(BuildContext context) {
    final styles = AppTypography.responsive(context);
    return _PageCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityHero(
            eyebrow: profile.abbreviation,
            title: profile.name,
            motto: profile.motto,
            icon: Icons.church_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_present(profile.charism))
            _SectionCard(
              title: 'Charism & Mission',
              icon: Icons.auto_awesome_outlined,
              child: _CharismMissionBlock(
                text: profile.charism!,
                textStyle: styles.bodyPrimary,
              ),
            ),
          if (_present(profile.charism)) const SizedBox(height: AppSpacing.lg),
          if (_hasFoundation(profile)) ...[
            _SectionCard(
              title: 'Foundation',
              icon: Icons.history_edu_outlined,
              child: _FoundationDetails(profile: profile),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_hasGeneralAdministration(profile))
            _SectionCard(
              title: 'General Administration',
              icon: Icons.account_balance_outlined,
              child: _GeneralAdministration(profile: profile),
            ),
          if (leaders.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: 'General Leadership',
              icon: Icons.groups_outlined,
              child: _CongregationLeadershipList(leaders: leaders),
            ),
          ],
          if (_hasReliableCongregationMetrics(province)) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: 'Congregation at a Glance',
              icon: Icons.insights_outlined,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatChip(
                    label: 'Religious',
                    value: province.activeMembers,
                    color: AppColors.secondaryDark,
                    icon: Icons.groups_2_outlined,
                  ),
                  _StatChip(
                    label: 'Communities',
                    value: province.activeCommunities,
                    color: AppColors.purple,
                    icon: Icons.home_work_outlined,
                  ),
                  _StatChip(
                    label: 'Ministries',
                    value: province.activeMinistries,
                    color: AppColors.cyan,
                    icon: Icons.volunteer_activism_outlined,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CharismMissionBlock extends StatelessWidget {
  const _CharismMissionBlock({required this.text, required this.textStyle});
  final String text;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.secondary.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border(
        left: BorderSide(color: AppColors.secondaryDark, width: 4),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.local_fire_department_outlined,
          size: 22,
          color: AppColors.secondaryDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: textStyle.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

bool _hasFoundation(CongregationProfile profile) =>
    _present(profile.founder) ||
    _present(profile.patronSaintName) ||
    profile.foundedYear != null ||
    _present(profile.founderImageUrl) ||
    _present(profile.patronSaintImageUrl);

bool _hasGeneralAdministration(CongregationProfile profile) =>
    _present(profile.generalateCity) ||
    _present(profile.generalateAddress) ||
    _present(profile.country) ||
    _present(profile.email) ||
    _present(profile.phone) ||
    _present(profile.website);

bool _hasReliableCongregationMetrics(ProvinceProfile province) =>
    province.activeMembers >= 0 &&
    province.activeCommunities >= 0 &&
    province.activeMinistries >= 0;

class _FoundationDetails extends StatelessWidget {
  const _FoundationDetails({required this.profile});
  final CongregationProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (_present(profile.founder))
            _FoundationTile(
              label: 'Founder',
              value: profile.founder!,
              icon: Icons.person_outline_rounded,
              color: AppColors.secondaryDark,
            ),
          if (_present(profile.patronSaintName))
            _FoundationTile(
              label: 'Patron Saint',
              value: profile.patronSaintName!,
              icon: Icons.church_outlined,
              color: AppColors.purple,
            ),
          if (profile.foundedYear != null)
            _FoundationTile(
              label: 'Founded',
              value: profile.foundedYear.toString(),
              icon: Icons.calendar_today_outlined,
              color: AppColors.info,
            ),
        ],
      ),
      if (_present(profile.founderImageUrl) ||
          _present(profile.patronSaintImageUrl)) ...[
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            if (_present(profile.founderImageUrl))
              _FoundationPortrait(
                label: 'Founder',
                name: profile.founder,
                imageUrl: profile.founderImageUrl!,
              ),
            if (_present(profile.patronSaintImageUrl))
              _FoundationPortrait(
                label: 'Patron Saint',
                name: profile.patronSaintName,
                imageUrl: profile.patronSaintImageUrl!,
              ),
          ],
        ),
      ],
    ],
  );
}

class _FoundationTile extends StatelessWidget {
  const _FoundationTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 132, maxWidth: 260),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.responsive(
                    context,
                  ).labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTypography.responsive(context).labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FoundationPortrait extends StatelessWidget {
  const _FoundationPortrait({
    required this.label,
    required this.name,
    required this.imageUrl,
  });
  final String label;
  final String? name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipOval(
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.responsive(context).fieldLabel),
          if (_present(name))
            Text(name!, style: AppTypography.responsive(context).labelMedium),
        ],
      ),
    ],
  );
}

class _GeneralAdministration extends StatelessWidget {
  const _GeneralAdministration({required this.profile});
  final CongregationProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_present(profile.generalateCity))
        _AdministrationDetail(
          icon: Icons.location_city_outlined,
          label: 'City',
          value: profile.generalateCity!,
          color: AppColors.info,
        ),
      if (_present(profile.country)) ...[
        const SizedBox(height: AppSpacing.sm),
        _AdministrationDetail(
          icon: Icons.public_outlined,
          label: 'Country',
          value: profile.country!,
          color: AppColors.purple,
        ),
      ],
      if (_present(profile.generalateAddress)) ...[
        const SizedBox(height: AppSpacing.sm),
        _AdministrationDetail(
          icon: Icons.location_on_outlined,
          label: 'Generalate address',
          value: profile.generalateAddress!,
          color: AppColors.secondaryDark,
        ),
      ],
      if (_present(profile.email)) ...[
        const SizedBox(height: AppSpacing.md),
        _CongregationContactValue(
          icon: Icons.email_outlined,
          text: _breakableContactText(profile.email!),
        ),
      ],
      if (_present(profile.phone)) ...[
        const SizedBox(height: AppSpacing.sm),
        _CongregationContactValue(
          icon: Icons.phone_outlined,
          text: profile.phone!,
        ),
      ],
      if (_present(profile.website)) ...[
        const SizedBox(height: AppSpacing.sm),
        _CongregationWebsiteLink(url: profile.website!),
      ],
      if (_present(profile.phone) || _present(profile.email)) ...[
        const SizedBox(height: AppSpacing.md),
        ContactActionButtons(
          personName: 'General Administration',
          phone: profile.phone,
          email: profile.email,
          compact: false,
        ),
      ],
    ],
  );
}

class _AdministrationDetail extends StatelessWidget {
  const _AdministrationDetail({
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
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 18, color: color),
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
              ).fieldLabel.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: AppTypography.responsive(
                context,
              ).bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CongregationContactValue extends StatelessWidget {
  const _CongregationContactValue({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: AppColors.secondaryDark),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          softWrap: true,
          style: AppTypography.responsive(
            context,
          ).bodySecondary.copyWith(color: AppColors.textPrimary),
        ),
      ),
    ],
  );
}

String _breakableContactText(String value) => value
    .replaceAll('@', '@\u200B')
    .replaceAll('.', '.\u200B')
    .replaceAll('/', '/\u200B');

class _CongregationWebsiteLink extends StatelessWidget {
  const _CongregationWebsiteLink({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: _CongregationContactValue(
        icon: Icons.language_rounded,
        text: _breakableContactText(
          url.replaceFirst(RegExp(r'^https?://'), ''),
        ),
      ),
    ),
  );
}

List<CongregationLeader> orderedCongregationLeaders(
  List<CongregationLeader> leaders,
) {
  final indexed = leaders.indexed.toList()
    ..sort((a, b) {
      final order = a.$2.displayOrder.compareTo(b.$2.displayOrder);
      return order != 0 ? order : a.$1.compareTo(b.$1);
    });
  return indexed.map((entry) => entry.$2).toList();
}

class _CongregationLeadershipList extends StatelessWidget {
  const _CongregationLeadershipList({required this.leaders});
  final List<CongregationLeader> leaders;

  @override
  Widget build(BuildContext context) {
    final ordered = orderedCongregationLeaders(leaders);
    return Column(
      children: [
        for (var index = 0; index < ordered.length; index++) ...[
          _CongregationLeadershipRow(leader: ordered[index]),
          if (index < ordered.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _CongregationLeadershipRow extends StatelessWidget {
  const _CongregationLeadershipRow({required this.leader});
  final CongregationLeader leader;

  @override
  Widget build(BuildContext context) {
    final accent = _congregationLeaderAccent(leader.roleName);
    final location = [
      leader.countryOfOrigin,
      leader.administrationCity,
    ].whereType<String>().where(_present).join(' · ');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: .15)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: MemberAvatar(
          name: leader.displayName,
          photoUrl: leader.photoUrl,
          radius: 28,
          backgroundColor: accent.withValues(alpha: .12),
          foregroundColor: accent,
        ),
        title: Text(
          leader.roleName,
          style: AppTypography.responsive(
            context,
          ).labelLarge.copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leader.displayName,
              key: Key('congregation-leader-name-${leader.id}'),
              style: AppTypography.responsive(context).bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (location.isNotEmpty)
              Text(
                location,
                style: AppTypography.responsive(
                  context,
                ).bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            if (_present(leader.phone) || _present(leader.email)) ...[
              const SizedBox(height: AppSpacing.xs),
              ContactActionButtons(
                personName: leader.displayName,
                phone: leader.phone,
                email: leader.email,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

Color _congregationLeaderAccent(String role) {
  final value = role.toLowerCase();
  if (value.contains('superior general') && !value.contains('assistant')) {
    return AppColors.secondaryDark;
  }
  if (value.contains('assistant')) return AppColors.purple;
  if (value.contains('treasurer')) return AppColors.success;
  return AppColors.cyan;
}

class _LeadershipView extends StatelessWidget {
  const _LeadershipView({required this.leaders});
  final List<CongregationLeader> leaders;

  @override
  Widget build(BuildContext context) {
    final ordered = [...leaders]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return _PageCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IdentityHero(
            eyebrow: 'GENERAL ADMINISTRATION · ROME',
            title: 'Missionaries of St. Antony',
            motto: 'Leadership in service of communion and mission',
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (ordered.isNotEmpty)
            _LeaderCard(leader: ordered.first, prominent: true),
          for (final leader in ordered.skip(1)) ...[
            const SizedBox(height: AppSpacing.md),
            _LeaderCard(leader: leader),
          ],
        ],
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({required this.leader, this.prominent = false});
  final CongregationLeader leader;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final styles = AppTypography.responsive(context);
    final details = [
      if (_present(leader.countryOfOrigin)) 'From ${leader.countryOfOrigin}',
      if (_present(leader.administrationCity)) leader.administrationCity!,
    ];
    return Container(
      padding: EdgeInsets.all(prominent ? AppSpacing.xl : AppSpacing.lg),
      decoration: BoxDecoration(
        color: prominent
            ? AppColors.secondary.withValues(alpha: .1)
            : AppColors.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: prominent ? AppColors.secondary : AppColors.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MemberAvatar(
            name: leader.displayName,
            photoUrl: leader.photoUrl,
            radius: prominent ? 38 : 32,
            backgroundColor: AppColors.primary.withValues(alpha: .1),
            foregroundColor: AppColors.primary,
            initialsStyle: styles.titleMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader.roleName,
                  style: styles.cardTitle.copyWith(
                    color: prominent
                        ? AppColors.secondaryDark
                        : AppColors.purple,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  leader.displayName,
                  style: styles.sectionTitle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    details.join(' · '),
                    style: styles.bodySecondary.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_present(leader.email)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(leader.email!, style: styles.bodySecondary),
                ],
                if (_present(leader.phone))
                  Text(leader.phone!, style: styles.bodySecondary),
                if (_present(leader.phone) || _present(leader.email)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ContactActionButtons(
                    personName: leader.displayName,
                    phone: leader.phone,
                    email: leader.email,
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

class _ProvinceProfileView extends StatelessWidget {
  const _ProvinceProfileView({
    required this.profile,
    required this.leaders,
    required this.onLeader,
  });
  final ProvinceProfile profile;
  final List<ProvinceLeader> leaders;
  final ValueChanged<ProvinceLeader>? onLeader;

  @override
  Widget build(BuildContext context) {
    final coreLeadership = orderedProvincialLeaders(leaders);
    return _PageCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityHero(
            eyebrow: profile.congregationName,
            title: profile.name,
            motto: profile.motto,
            icon: Icons.public_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Province Details',
            icon: Icons.location_city_outlined,
            child: _ProvinceDetails(profile: profile),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Current Province Snapshot',
            icon: Icons.insights_outlined,
            child: _ProvinceSnapshot(profile: profile),
          ),
          if (coreLeadership.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: 'Provincial Leadership',
              icon: Icons.account_balance_outlined,
              child: _ProvincialLeadershipList(
                leaders: coreLeadership,
                onLeader: onLeader,
              ),
            ),
          ],
          if (_present(profile.email) ||
              _present(profile.phone) ||
              _present(profile.website)) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: 'Province Contact',
              icon: Icons.contact_phone_outlined,
              child: _ProvinceContact(profile: profile),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProvinceDetails extends StatelessWidget {
  const _ProvinceDetails({required this.profile});
  final ProvinceProfile profile;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      _ProvinceDetailTile(
        label: 'Congregation',
        value: profile.congregationName,
        icon: Icons.church_outlined,
        color: AppColors.primary,
      ),
      if (_present(profile.headquarters))
        _ProvinceDetailTile(
          label: 'Headquarters',
          value: profile.headquarters!,
          icon: Icons.account_balance_outlined,
          color: AppColors.secondaryDark,
        ),
      if (_present(profile.address))
        _ProvinceDetailTile(
          label: 'Address',
          value: profile.address!,
          icon: Icons.location_on_outlined,
          color: AppColors.cyan,
        ),
      if (_present(profile.country))
        _ProvinceDetailTile(
          label: 'Country',
          value: profile.country!,
          icon: Icons.public_outlined,
          color: AppColors.purple,
        ),
      if (profile.establishedDate != null)
        _ProvinceDetailTile(
          label: 'Established',
          value: _date(profile.establishedDate)!,
          icon: Icons.calendar_today_outlined,
          color: AppColors.info,
        ),
    ],
  );
}

class _ProvinceDetailTile extends StatelessWidget {
  const _ProvinceDetailTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 132, maxWidth: 360),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .065),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
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
                  style: AppTypography.responsive(context).bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProvinceSnapshot extends StatelessWidget {
  const _ProvinceSnapshot({required this.profile});
  final ProvinceProfile profile;

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, int value, IconData icon, Color color})>[
      (
        label: 'Active Members',
        value: profile.activeMembers,
        icon: Icons.groups_2_outlined,
        color: AppColors.primary,
      ),
      (
        label: 'Communities',
        value: profile.activeCommunities,
        icon: Icons.home_work_outlined,
        color: AppColors.purple,
      ),
      (
        label: 'Ministries',
        value: profile.activeMinistries,
        icon: Icons.volunteer_activism_outlined,
        color: AppColors.cyan,
      ),
      if (profile.activeFormationMembers case final value?)
        (
          label: 'Formation Members',
          value: value,
          icon: Icons.school_outlined,
          color: AppColors.info,
        ),
      if (profile.currentProvincialOffices case final value?)
        (
          label: 'Provincial Offices',
          value: value,
          icon: Icons.account_balance_outlined,
          color: AppColors.secondaryDark,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final columns = constraints.maxWidth >= 620 ? 3 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              _ProvinceMetricCard(metric: metric, width: width),
          ],
        );
      },
    );
  }
}

class _ProvinceMetricCard extends StatelessWidget {
  const _ProvinceMetricCard({required this.metric, required this.width});
  final ({String label, int value, IconData icon, Color color}) metric;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: metric.color.withValues(alpha: .065),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: metric.color.withValues(alpha: .14)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(metric.icon, size: 20, color: metric.color),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${metric.value}',
          style: AppTypography.responsive(context).titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          metric.label,
          maxLines: 2,
          style: AppTypography.responsive(
            context,
          ).labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

List<ProvinceLeader> orderedProvincialLeaders(List<ProvinceLeader> leaders) {
  final indexed =
      leaders.indexed
          .where((entry) => _provinceLeaderPriority(entry.$2) < 6)
          .toList()
        ..sort((a, b) {
          final order = _provinceLeaderPriority(
            a.$2,
          ).compareTo(_provinceLeaderPriority(b.$2));
          return order != 0 ? order : a.$1.compareTo(b.$1);
        });
  return indexed.map((entry) => entry.$2).toList();
}

int _provinceLeaderPriority(ProvinceLeader leader) {
  final value = leader.roleCode
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
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

class _ProvincialLeadershipList extends StatelessWidget {
  const _ProvincialLeadershipList({required this.leaders, this.onLeader});
  final List<ProvinceLeader> leaders;
  final ValueChanged<ProvinceLeader>? onLeader;

  @override
  Widget build(BuildContext context) {
    final ordered = orderedProvincialLeaders(leaders);
    return Column(
      children: [
        for (var index = 0; index < ordered.length; index++) ...[
          _ProvincialLeaderRow(
            leader: ordered[index],
            onTap: onLeader == null ? null : () => onLeader!(ordered[index]),
          ),
          if (index < ordered.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _ProvincialLeaderRow extends StatelessWidget {
  const _ProvincialLeaderRow({required this.leader, required this.onTap});
  final ProvinceLeader leader;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (_provinceLeaderPriority(leader)) {
      0 => AppColors.secondaryDark,
      1 || 2 => AppColors.primary,
      3 => AppColors.cyan,
      4 => AppColors.purple,
      5 => AppColors.success,
      _ => AppColors.textSecondary,
    };
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: MemberAvatar(
          name: leader.displayName,
          photoUrl: leader.photoUrl,
          radius: 28,
          backgroundColor: accent.withValues(alpha: .1),
          foregroundColor: accent,
        ),
        title: Text(
          leader.roleName,
          style: AppTypography.responsive(
            context,
          ).labelLarge.copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leader.displayName,
              style: AppTypography.responsive(context).bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (leader.fromDate != null)
              Text(
                'Since ${_date(leader.fromDate)}',
                style: AppTypography.responsive(
                  context,
                ).bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            if (_present(leader.phone) ||
                _present(leader.whatsApp) ||
                _present(leader.email)) ...[
              const SizedBox(height: AppSpacing.xs),
              ContactActionButtons(
                personName: leader.displayName,
                phone: leader.phone,
                whatsApp: leader.whatsApp,
                email: leader.email,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ProvinceContact extends StatelessWidget {
  const _ProvinceContact({required this.profile});
  final ProvinceProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_present(profile.email))
        _CongregationContactValue(
          icon: Icons.email_outlined,
          text: _breakableContactText(profile.email!),
        ),
      if (_present(profile.phone)) ...[
        const SizedBox(height: AppSpacing.sm),
        _CongregationContactValue(
          icon: Icons.phone_outlined,
          text: profile.phone!,
        ),
      ],
      if (_present(profile.website)) ...[
        const SizedBox(height: AppSpacing.sm),
        _CongregationWebsiteLink(url: profile.website!),
      ],
      if (_present(profile.phone) || _present(profile.email)) ...[
        const SizedBox(height: AppSpacing.md),
        ContactActionButtons(
          personName: profile.name,
          phone: profile.phone,
          email: profile.email,
          compact: false,
        ),
      ],
    ],
  );
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.title,
    required this.icon,
    this.eyebrow,
    this.motto,
  });
  final String title;
  final IconData icon;
  final String? eyebrow;
  final String? motto;

  @override
  Widget build(BuildContext context) {
    final styles = AppTypography.responsive(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .96),
            AppColors.primary.withValues(alpha: .82),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.jumbo,
            height: AppSpacing.jumbo,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: .18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary),
            ),
            child: Icon(
              icon,
              color: AppColors.secondary,
              size: AppSpacing.xxxl,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_present(eyebrow))
                  Text(
                    eyebrow!,
                    style: styles.labelMedium.copyWith(
                      color: AppColors.secondary,
                      letterSpacing: .7,
                    ),
                  ),
                Text(
                  title,
                  style: styles.pageTitle.copyWith(color: AppColors.textLight),
                ),
                if (_present(motto)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    motto!,
                    style: styles.bodySecondary.copyWith(
                      color: AppColors.textLight,
                    ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final styles = AppTypography.responsive(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondaryDark),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: styles.sectionTitle.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xxl),
          child,
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });
  final String label;
  final int value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final styles = AppTypography.responsive(context);
    final accent = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: color == null ? .06 : .07),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: color == null
            ? null
            : Border.all(color: accent.withValues(alpha: .13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: accent),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            '$value $label',
            style: styles.labelMedium.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          const Text('Unable to load organization identity.'),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

bool _present(String? value) => value != null && value.trim().isNotEmpty;

String? _date(DateTime? date) => date == null
    ? null
    : '${date.day.toString().padLeft(2, '0')} '
          '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} '
          '${date.year}';
