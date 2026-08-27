import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../features/province_modules/data/province_repository.dart';
import '../../../features/province_modules/models/province_models.dart';
import '../../../features/religious_directory/data/member_directory_repository.dart';
import '../../../features/religious_directory/models/member_directory_entry.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({
    required this.members,
    required this.province,
    required this.onMember,
    required this.onCommunity,
    required this.onMinistry,
    super.key,
  });
  final MemberDirectoryRepository members;
  final ProvinceRepository province;
  final ValueChanged<MemberDirectoryEntry> onMember;
  final ValueChanged<CommunityRecord> onCommunity;
  final ValueChanged<MinistryRecord> onMinistry;
  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  String query = '';
  late final future = Future.wait([
    widget.members.fetchMembers(),
    widget.province.fetchCommunities(),
    widget.province.fetchMinistries(),
  ]);
  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: (value) =>
                        setState(() => query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search Communio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Object>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Search is temporarily unavailable. Please try again.',
                    ),
                  );
                }
                if (query.length < 2) {
                  return const Center(
                    child: Text(
                      'Enter at least two characters to search Religious, Communities, and Ministries.',
                    ),
                  );
                }
                final members = (snapshot.data![0] as List<MemberDirectoryEntry>)
                    .where(
                      (m) =>
                          '${m.displayName} ${m.religiousId} ${m.community ?? ''} ${m.ministry ?? ''}'
                              .toLowerCase()
                              .contains(query),
                    )
                    .take(20)
                    .toList();
                final communities = (snapshot.data![1] as List<CommunityRecord>)
                    .where(
                      (c) =>
                          '${c.name} ${c.superior ?? ''} ${c.accountant ?? ''}'
                              .toLowerCase()
                              .contains(query),
                    )
                    .take(20)
                    .toList();
                final ministries = (snapshot.data![2] as List<MinistryRecord>)
                    .where(
                      (m) => '${m.name} ${m.type ?? ''} ${m.community ?? ''}'
                          .toLowerCase()
                          .contains(query),
                    )
                    .take(20)
                    .toList();
                if (members.isEmpty &&
                    communities.isEmpty &&
                    ministries.isEmpty) {
                  return const Center(
                    child: Text('No Communio records match this search.'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    if (members.isNotEmpty) ...[
                      _Header('Religious', members.length),
                      ...members.map(
                        (m) => ListTile(
                          leading: MemberAvatar(
                            name: m.displayName,
                            photoUrl: m.photoUrl,
                          ),
                          title: Text(m.displayName),
                          subtitle: Text(m.community ?? m.memberStatus),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onMember(m);
                          },
                        ),
                      ),
                    ],
                    if (communities.isNotEmpty) ...[
                      _Header('Communities', communities.length),
                      ...communities.map(
                        (c) => ListTile(
                          leading: const Icon(Icons.church_outlined),
                          title: Text(c.name),
                          subtitle: Text('${c.residentCount} residents'),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onCommunity(c);
                          },
                        ),
                      ),
                    ],
                    if (ministries.isNotEmpty) ...[
                      _Header('Ministries', ministries.length),
                      ...ministries.map(
                        (m) => ListTile(
                          leading: const Icon(
                            Icons.volunteer_activism_outlined,
                          ),
                          title: Text(m.name),
                          subtitle: Text(m.type ?? m.community ?? 'Ministry'),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onMinistry(m);
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header(this.label, this.count);
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(
      '$label · $count',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
    ),
  );
}
