import 'package:flutter/material.dart';

/// ===============================================================
/// COMMUNIO DESIGN SYSTEM
/// Colors
/// ---------------------------------------------------------------
/// All application colors are defined here.
/// Never use Color(0xFF...) directly anywhere else in the app.
/// ===============================================================

class AppColors {
  AppColors._();

  // -----------------------------------------------------------------
  // Brand Colors
  // -----------------------------------------------------------------

  /// Primary Navy
  static const Color primary = Color(0xFF0E2F6B);

  /// Liturgical Gold
  static const Color secondary = Color(0xFFD4AF37);

  /// Deep gold used when brand-gold text needs stronger contrast.
  static const Color secondaryDark = Color(0xFF9A6B00);

  // -----------------------------------------------------------------
  // Backgrounds
  // -----------------------------------------------------------------

  /// Main application background
  static const Color background = Color(0xFFFAF6ED);

  /// Card / Surface background
  static const Color surface = Colors.white;

  /// Cool-white application chrome, distinct from the warm content canvas.
  static const Color appBarSurface = Color(0xFFF7F9FC);

  /// Barely navy-tinted navigation surface.
  static const Color navigationSurface = Color(0xFFFCFDFE);

  // -----------------------------------------------------------------
  // Text
  // -----------------------------------------------------------------

  static const Color textPrimary = Color(0xFF1D2939);

  static const Color textSecondary = Color(0xFF596579);

  static const Color textLight = Colors.white;

  // -----------------------------------------------------------------
  // Borders & Divider
  // -----------------------------------------------------------------

  static const Color border = Color(0xFFD0D5DD);

  static const Color divider = Color(0xFFEAECF0);

  /// Cool card outline used on authenticated operational surfaces.
  static const Color cardBorder = Color(0xFFE3E8EF);

  // -----------------------------------------------------------------
  // Status Colors
  // -----------------------------------------------------------------

  static const Color success = Color(0xFF16A34A);

  static const Color warning = Color(0xFFF59E0B);

  static const Color error = Color(0xFFDC2626);

  static const Color info = Color(0xFF2563EB);

  static const Color purple = Color(0xFF7C3EB5);

  static const Color cyan = Color(0xFF0891B2);

  /// Cool dashboard canvas for the authenticated Province Pulse experience.
  static const Color dashboardBackground = Color(0xFFF5F7FA);

  /// Warm login-inspired tones used only by the Province Pulse canvas.
  static const Color dashboardIvory = Color(0xFFFEFCFB);
  static const Color dashboardWarmCream = Color(0xFFFBF6F1);
  static const Color dashboardSoftBeige = Color(0xFFF8F1E9);

  // -----------------------------------------------------------------
  // Additional Neutral Shades
  // -----------------------------------------------------------------

  static const Color black = Colors.black;

  static const Color white = Colors.white;

  static const Color transparent = Colors.transparent;
}
