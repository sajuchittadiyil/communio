/*
===============================================================
COMMUNIO DESIGN SYSTEM
Shadows
---------------------------------------------------------------
Standard elevation system used throughout the application.

Never use:

BoxShadow(...)

directly in widgets.

Instead use:

AppShadows.sm
AppShadows.md
AppShadows.lg

===============================================================
*/

import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  /// Small Shadow
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 40, 0.05),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium Shadow
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 40, 0.08),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Soft medium elevation for floating authentication cards.
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 40, 0.06),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Large Shadow
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 40, 0.12),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}
