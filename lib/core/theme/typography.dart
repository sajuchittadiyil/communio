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
