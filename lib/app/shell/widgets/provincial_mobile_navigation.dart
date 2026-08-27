import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/app_navigation.dart';

class ProvincialMobileNavigation extends StatelessWidget {
  const ProvincialMobileNavigation({
    required this.configuration,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final RoleNavigationConfiguration configuration;
  final AppDestination selected;
  final ValueChanged<AppDestination> onSelected;

  static const _primaryDestinations = [
    AppDestination.dashboard,
    AppDestination.religious,
    AppDestination.communities,
    AppDestination.calendar,
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = textScale >= 1.4
        ? 82.0
        : textScale >= 1.15
        ? 72.0
        : 64.0;
    final selectedIndex = _primaryDestinations.contains(selected)
        ? _primaryDestinations.indexOf(selected)
        : _primaryDestinations.length;
    final primaryItems = _primaryDestinations
        .map(configuration.itemFor)
        .toList(growable: false);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: NavigationBar(
        height: height,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index < primaryItems.length) {
            onSelected(primaryItems[index].destination);
          } else {
            _showMore(context);
          }
        },
        destinations: [
          ...primaryItems.map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Future<void> _showMore(BuildContext context) async {
    final remaining = configuration.items
        .where((item) => !_primaryDestinations.contains(item.destination))
        .toList(growable: false);
    final destination = await showModalBottomSheet<AppDestination>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.none,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'More',
                  style: AppTypography.responsive(context).titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: remaining
                      .map(
                        (item) => ListTile(
                          minTileHeight: AppSpacing.giant,
                          selected: item.destination == selected,
                          selectedColor: AppColors.primary,
                          leading: Icon(
                            item.destination == selected
                                ? item.selectedIcon
                                : item.icon,
                          ),
                          title: Text(item.label),
                          onTap: () => Navigator.pop(context, item.destination),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (destination != null) onSelected(destination);
  }
}
