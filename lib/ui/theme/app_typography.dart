import 'package:flutter/material.dart';

/// Material 3 type-scale constants for the ChipLens design system.
///
/// All styles are `static const` — no color is applied here; the framework
/// adapts text color from the active `ColorScheme` at build time.
///
/// Scale maps to M3 spec values:
/// https://m3.material.io/styles/typography/type-scale-tokens
class AppTypography {
  const AppTypography._();

  // ── Display ───────────────────────────────────────────────────────────────

  static const TextStyle displayLarge = TextStyle(
    fontSize: 57.0, fontWeight: FontWeight.w400, letterSpacing: -0.25);

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45.0, fontWeight: FontWeight.w400, letterSpacing: 0.0);

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36.0, fontWeight: FontWeight.w400, letterSpacing: 0.0);

  // ── Headline ──────────────────────────────────────────────────────────────

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32.0, fontWeight: FontWeight.w400, letterSpacing: 0.0);

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28.0, fontWeight: FontWeight.w400, letterSpacing: 0.0);

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24.0, fontWeight: FontWeight.w400, letterSpacing: 0.0);

  // ── Title ─────────────────────────────────────────────────────────────────

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0, fontWeight: FontWeight.w400, letterSpacing: 0.0);

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0, fontWeight: FontWeight.w500, letterSpacing: 0.15);

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1);

  // ── Body ──────────────────────────────────────────────────────────────────

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0, fontWeight: FontWeight.w400, letterSpacing: 0.5);

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0, fontWeight: FontWeight.w400, letterSpacing: 0.25);

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0, fontWeight: FontWeight.w400, letterSpacing: 0.4);

  // ── Label ─────────────────────────────────────────────────────────────────

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1);

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0, fontWeight: FontWeight.w500, letterSpacing: 0.5);

  /// Alias for [labelMedium]; retained for readability in UI code.
  static const TextStyle caption = TextStyle(
    fontSize: 12.0, fontWeight: FontWeight.w400, letterSpacing: 0.4);

  // ── TextTheme ─────────────────────────────────────────────────────────────

  /// A complete [TextTheme] mapping every M3 role to its [AppTypography] style.
  static const TextTheme textTheme = TextTheme(
    displayLarge:   displayLarge,
    displayMedium:  displayMedium,
    displaySmall:   displaySmall,
    headlineLarge:  headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall:  headlineSmall,
    titleLarge:     titleLarge,
    titleMedium:    titleMedium,
    titleSmall:     titleSmall,
    bodyLarge:      bodyLarge,
    bodyMedium:     bodyMedium,
    bodySmall:      bodySmall,
    labelLarge:     labelLarge,
    labelMedium:    labelMedium,
    labelSmall:     caption,
  );
}
