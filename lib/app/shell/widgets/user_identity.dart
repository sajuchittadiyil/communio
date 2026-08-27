import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class UserIdentityAvatar extends StatelessWidget {
  const UserIdentityAvatar({
    required this.displayName,
    this.radius = 18,
    super.key,
  });

  final String displayName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      child: Text(
        _initials(displayName),
        style: AppTypography.responsive(
          context,
        ).labelMedium.copyWith(color: AppColors.textLight),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
