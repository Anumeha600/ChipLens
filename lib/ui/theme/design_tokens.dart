import 'package:flutter/material.dart';

/// Single source of truth for all dimensionless design constants.
///
/// All values follow an 8-point grid. Nothing is hardcoded elsewhere —
/// every other design-system file references constants from here.
class DesignTokens {
  const DesignTokens._();

  // ── Spacing scale (8-pt grid) ─────────────────────────────────────────────

  static const double spacingXS   =  4.0;
  static const double spacingSM   =  8.0;
  static const double spacingMD   = 16.0;
  static const double spacingLG   = 24.0;
  static const double spacingXL   = 32.0;
  static const double spacingXXL  = 48.0;
  static const double spacingXXXL = 64.0;

  // ── Common EdgeInsets shortcuts ───────────────────────────────────────────

  static const EdgeInsets pagePaddingMobile  = EdgeInsets.all(spacingMD);
  static const EdgeInsets pagePaddingTablet  = EdgeInsets.all(spacingLG);
  static const EdgeInsets pagePaddingDesktop = EdgeInsets.all(spacingXL);
  static const EdgeInsets cardPadding        = EdgeInsets.all(spacingMD);

  // ── Animation durations ───────────────────────────────────────────────────

  static const Duration animationFast     = Duration(milliseconds: 100);
  static const Duration animationNormal   = Duration(milliseconds: 200);
  static const Duration animationSlow     = Duration(milliseconds: 300);
  static const Duration animationVerySlow = Duration(milliseconds: 500);

  /// Alias for the most commonly used animation duration.
  static const Duration defaultAnimation = animationNormal;

  // ── Icon sizes ────────────────────────────────────────────────────────────

  static const double iconXS = 12.0;
  static const double iconSM = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // ── Touch targets ─────────────────────────────────────────────────────────

  /// Minimum tap-target per Material / Apple HIG guidelines (44 × 44 dp).
  static const double minTouchTarget         = 44.0;
  static const double comfortableTouchTarget = 48.0;

  // ── Content / layout widths ───────────────────────────────────────────────

  static const double contentWidthNarrow =  480.0;
  static const double contentWidthNormal =  720.0;
  static const double contentWidthWide   = 1200.0;
  static const double contentWidthMax    = 1440.0;

  // ── Structural heights / widths ───────────────────────────────────────────

  static const double toolbarHeight             =  56.0;
  static const double toolbarHeightLarge        =  64.0;
  static const double navigationRailWidth       =  80.0;
  static const double navigationRailWidthExtended = 240.0;
  static const double navigationDrawerWidth     = 280.0;
}
