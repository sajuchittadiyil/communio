/*
===============================================================
COMMUNIO DESIGN SYSTEM
Border Radius
---------------------------------------------------------------
Standard border radius values used throughout the application.

Never use:

BorderRadius.circular(12)

Instead use:

BorderRadius.circular(AppRadius.md)

===============================================================
*/

class AppRadius {
  AppRadius._();

  /// No radius
  static const double none = 0;

  /// Very small
  static const double xs = 4;

  /// Small
  static const double sm = 8;

  /// Medium (Default)
  static const double md = 12;

  /// Large
  static const double lg = 16;

  /// Extra Large
  static const double xl = 20;

  /// Rounded Cards
  static const double xxl = 24;

  /// Floating Panels
  static const double xxxl = 32;

  /// Fully Rounded (Pills / Avatars)
  static const double full = 999;
}
