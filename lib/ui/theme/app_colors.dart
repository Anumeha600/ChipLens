import 'package:flutter/material.dart';

/// Centralized color constants for the ChipLens design system.
///
/// Primitive palette constants are `const Color` values — always stable.
/// [lightScheme] and [darkScheme] are `static final` `ColorScheme` objects
/// generated via [ColorScheme.fromSeed] with the [primary] seed, with key
/// semantic colors locked in via `copyWith`.
class AppColors {
  const AppColors._();

  // ── Brand / primary palette ───────────────────────────────────────────────

  static const Color primary          = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryLight     = Color(0xFF6366F1);
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color secondary        = Color(0xFF7C3AED); // Electric Purple
  static const Color secondaryContainer = Color(0xFFEDE9FE);

  // ── Status / semantic colors (theme-independent) ──────────────────────────

  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error   = Color(0xFFEF4444); // Red
  static const Color info    = Color(0xFF3B82F6); // Blue

  // ── Light theme surfaces ──────────────────────────────────────────────────

  static const Color lightBackground    = Color(0xFFF8FAFC);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightOutline       = Color(0xFFE8EAED);
  static const Color lightDivider       = Color(0xFFE8EAED);
  static const Color textPrimaryLight   = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color disabledLight      = Color(0xFF9CA3AF);
  static const Color hoverLight         = Color(0xFFF3F4F6);
  static const Color selectionLight     = Color(0xFFEEF2FF);

  // ── Dark theme surfaces ───────────────────────────────────────────────────

  static const Color darkBackground    = Color(0xFF0D0F17);
  static const Color darkSurface       = Color(0xFF161822);
  static const Color darkOutline       = Color(0xFF2A2D3E);
  static const Color darkDivider       = Color(0xFF2A2D3E);
  static const Color textPrimaryDark   = Color(0xFFE8EAED);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color disabledDark      = Color(0xFF6B7280);
  static const Color hoverDark         = Color(0xFF1E2030);
  static const Color selectionDark     = Color(0xFF252840);

  // ── Material 3 color schemes ──────────────────────────────────────────────

  /// Light-mode [ColorScheme] seeded from [primary]; error and surface locked.
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    error:   error,
    surface: lightSurface,
  );

  /// Dark-mode [ColorScheme] seeded from [primary]; error and surface locked.
  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
  ).copyWith(
    error:   error,
    surface: darkSurface,
  );
}
