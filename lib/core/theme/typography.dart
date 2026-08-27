/*
===============================================================
COMMUNIO DESIGN SYSTEM
Typography
---------------------------------------------------------------
Central typography definitions for the entire application.

Font Families

• Cormorant Garamond
  - Elegant headings
  - Splash Screen
  - Login
  - Major Page Titles

• Inter
  - Body Text
  - Forms
  - Tables
  - Navigation
  - Buttons

===============================================================
*/

import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static CommunioTextStyles responsive(BuildContext context) =>
      CommunioTextStyles(mobile: MediaQuery.sizeOf(context).width < 760);

  // Font Families
  static const String headingFont = 'Cormorant Garamond';
  static const String bodyFont = 'Inter';

  // ==========================
  // DISPLAY
  // ==========================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Prominent wordmark used on brand-led entry screens.
  static const TextStyle brandDisplay = TextStyle(
    fontFamily: headingFont,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: headingFont,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: headingFont,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // ==========================
  // HEADLINES
  // ==========================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: headingFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: headingFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Compact editorial heading for operational dashboard cards.
  static const TextStyle dashboardSectionTitle = TextStyle(
    fontFamily: headingFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ==========================
  // TITLES
  // ==========================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Brand wordmark used in the permanent Provincial sidebar.
  static const TextStyle sidebarWordmark = TextStyle(
    fontFamily: bodyFont,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // ==========================
  // BODY
  // ==========================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ==========================
  // LABELS
  // ==========================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}

class CommunioTextStyles {
  const CommunioTextStyles({required this.mobile});

  final bool mobile;

  TextStyle _mobile(TextStyle desktop, double size, {double? height}) => mobile
      ? desktop.copyWith(fontSize: size, height: height ?? desktop.height)
      : desktop;

  TextStyle get displayTitle =>
      _mobile(AppTypography.headlineLarge, 26, height: 1.25);
  TextStyle get pageTitle =>
      _mobile(AppTypography.headlineSmall, 25, height: 1.25);
  TextStyle get sectionTitle =>
      _mobile(AppTypography.titleMedium, 21, height: 1.3);
  TextStyle get cardTitle =>
      _mobile(AppTypography.titleSmall, 18, height: 1.35);
  TextStyle get bodyPrimary =>
      _mobile(AppTypography.bodyLarge, 17, height: 1.5);
  TextStyle get bodySecondary =>
      _mobile(AppTypography.bodyMedium, 15.5, height: 1.45);
  TextStyle get fieldLabel =>
      _mobile(AppTypography.labelSmall, 15.5, height: 1.4);
  TextStyle get fieldValue =>
      _mobile(AppTypography.labelMedium, 17.5, height: 1.4);
  TextStyle get caption => _mobile(AppTypography.labelSmall, 14, height: 1.35);
  TextStyle get buttonText =>
      _mobile(AppTypography.labelLarge, 16, height: 1.35);
  TextStyle get navigationLabel =>
      _mobile(AppTypography.labelMedium, 14, height: 1.3);
  TextStyle get badgeText => _mobile(AppTypography.labelSmall, 14, height: 1.3);
  TextStyle get statNumber =>
      _mobile(AppTypography.titleMedium, 22, height: 1.25);
  TextStyle get statLabel =>
      _mobile(AppTypography.labelSmall, 14.5, height: 1.3);

  TextStyle get displayLarge =>
      _mobile(AppTypography.displayLarge, 32, height: 1.2);
  TextStyle get brandDisplay =>
      _mobile(AppTypography.brandDisplay, 48, height: 1.1);
  TextStyle get displayMedium =>
      _mobile(AppTypography.displayMedium, 30, height: 1.2);
  TextStyle get displaySmall =>
      _mobile(AppTypography.displaySmall, 28, height: 1.2);
  TextStyle get headlineLarge => displayTitle;
  TextStyle get headlineMedium => pageTitle;
  TextStyle get headlineSmall => pageTitle;
  TextStyle get dashboardSectionTitle => sectionTitle;
  TextStyle get titleLarge =>
      _mobile(AppTypography.titleLarge, 22, height: 1.3);
  TextStyle get titleMedium => sectionTitle;
  TextStyle get titleSmall => cardTitle;
  TextStyle get sidebarWordmark => AppTypography.sidebarWordmark;
  TextStyle get bodyLarge => bodyPrimary;
  TextStyle get bodyMedium =>
      _mobile(AppTypography.bodyMedium, 16, height: 1.5);
  TextStyle get bodySmall => bodySecondary;
  TextStyle get labelLarge =>
      _mobile(AppTypography.labelLarge, 17, height: 1.35);
  TextStyle get labelMedium =>
      _mobile(AppTypography.labelMedium, 16, height: 1.35);
  TextStyle get labelSmall => caption;
}
