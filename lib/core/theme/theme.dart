/*
===============================================================
COMMUNIO DESIGN SYSTEM
Application Theme
---------------------------------------------------------------
Central Material 3 Theme for the entire application.

This file combines:

• Colors
• Typography
• Buttons
• Inputs
• Cards
• AppBar
• Navigation

===============================================================
*/

import 'package:flutter/material.dart';

import 'colors.dart';
import 'radius.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get mobile {
    const typography = CommunioTextStyles(mobile: true);
    return light.copyWith(
      textTheme:
          TextTheme(
            displayLarge: typography.displayLarge,
            displayMedium: typography.displayMedium,
            displaySmall: typography.displaySmall,
            headlineLarge: typography.headlineLarge.copyWith(
              color: AppColors.primary,
            ),
            headlineMedium: typography.headlineMedium.copyWith(
              color: AppColors.primary,
            ),
            headlineSmall: typography.headlineSmall.copyWith(
              color: AppColors.primary,
            ),
            titleLarge: typography.titleLarge.copyWith(
              color: AppColors.primary,
            ),
            titleMedium: typography.titleMedium.copyWith(
              color: AppColors.primary,
            ),
            titleSmall: typography.titleSmall.copyWith(
              color: AppColors.primary,
            ),
            bodyLarge: typography.bodyLarge,
            bodyMedium: typography.bodyMedium,
            bodySmall: typography.bodySmall,
            labelLarge: typography.buttonText,
            labelMedium: typography.navigationLabel,
            labelSmall: typography.caption,
          ).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.secondary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.black
                : AppColors.textPrimary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return typography.navigationLabel.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
            height: 1.1,
            letterSpacing: -.15,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.info,
        titleTextStyle: typography.bodyLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: typography.bodySecondary.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: typography.buttonText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(textStyle: typography.buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: typography.buttonText,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.background,

      primaryColor: AppColors.primary,

      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      fontFamily: AppTypography.bodyFont,

      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,

        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,

        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,

        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,

        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,

          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),

          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,

          side: const BorderSide(color: AppColors.primary),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: AppColors.surface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      dividerColor: AppColors.divider,
    );
  }
}
