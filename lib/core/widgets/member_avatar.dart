import 'package:flutter/material.dart';

/// A circular member photo with initials as its empty/error fallback.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    required this.name,
    this.photoUrl,
    this.initials,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.initialsStyle,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final String? initials;
  final double? radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? initialsStyle;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final cacheWidth = radius == null
        ? null
        : (radius! * 2 * MediaQuery.devicePixelRatioOf(context)).round();
    final fallback = Center(
      child: Text(initials ?? _initials(name), style: initialsStyle),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: ClipOval(
        child: SizedBox.expand(
          child: url == null || url.isEmpty
              ? fallback
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0])
    .join()
    .toUpperCase();
