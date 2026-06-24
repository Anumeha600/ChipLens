import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'design_tokens.dart';

/// Produces complete Material 3 [ThemeData] objects for the ChipLens app.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme:      AppTheme.light,
///   darkTheme:  AppTheme.dark,
///   themeMode:  ThemeMode.system,
/// )
/// ```
class AppTheme {
  const AppTheme._();

  // ── Light theme ───────────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
    useMaterial3:   true,
    colorScheme:    AppColors.lightScheme,
    textTheme:      AppTypography.textTheme,
    appBarTheme:    const AppBarTheme(
      elevation:              AppElevation.level0,
      scrolledUnderElevation: AppElevation.level1,
      centerTitle:            false,
      backgroundColor:        AppColors.lightSurface,
      foregroundColor:        AppColors.textPrimaryLight,
      iconTheme: IconThemeData(size: DesignTokens.iconMD),
    ),
    cardTheme: const CardThemeData(
      elevation: AppElevation.level1,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      space:     1.0,
      thickness: 1.0,
      color: AppColors.lightDivider,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide:   BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide:   BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.primary, width: 2.0),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMD,
        vertical:   DesignTokens.spacingSM,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation:   AppElevation.level1,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        minimumSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLG,
          vertical:   DesignTokens.spacingMD,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        minimumSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
        side: const BorderSide(color: AppColors.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        minimumSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      elevation: AppElevation.dialog,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      elevation:    AppElevation.level0,
      useIndicator: true,
      selectedIconTheme:   IconThemeData(size: DesignTokens.iconMD),
      unselectedIconTheme: IconThemeData(size: DesignTokens.iconMD),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      elevation:     AppElevation.level2,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
  );

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
    useMaterial3:   true,
    colorScheme:    AppColors.darkScheme,
    textTheme:      AppTypography.textTheme,
    appBarTheme:    const AppBarTheme(
      elevation:              AppElevation.level0,
      scrolledUnderElevation: AppElevation.level1,
      centerTitle:            false,
      backgroundColor:        AppColors.darkSurface,
      foregroundColor:        AppColors.textPrimaryDark,
      iconTheme: IconThemeData(size: DesignTokens.iconMD),
    ),
    cardTheme: const CardThemeData(
      elevation: AppElevation.level1,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      space:     1.0,
      thickness: 1.0,
      color: AppColors.darkDivider,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide:   BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide:   BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2.0),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMD,
        vertical:   DesignTokens.spacingSM,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation:   AppElevation.level1,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        minimumSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLG,
          vertical:   DesignTokens.spacingMD,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        minimumSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
        side: const BorderSide(color: AppColors.primaryLight),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        minimumSize: const Size(
          DesignTokens.minTouchTarget,
          DesignTokens.minTouchTarget,
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      elevation: AppElevation.dialog,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      elevation:    AppElevation.level0,
      useIndicator: true,
      selectedIconTheme:   IconThemeData(size: DesignTokens.iconMD),
      unselectedIconTheme: IconThemeData(size: DesignTokens.iconMD),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      elevation:     AppElevation.level2,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
  );
}
