/// Material 3 elevation levels for the ChipLens design system.
///
/// Use these constants instead of hardcoded `double` values so every
/// elevation-bearing widget stays consistent and easy to tune globally.
///
/// M3 level mapping (tonal + shadow):
/// level0 = 0 dp (flat, no shadow)
/// level1 = 1 dp (e.g. cards at rest)
/// level2 = 3 dp (e.g. navigation bars)
/// level3 = 6 dp (e.g. menus, floating)
class AppElevation {
  const AppElevation._();

  // ── Tonal surface levels ──────────────────────────────────────────────────

  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;

  // ── Semantic elevations ───────────────────────────────────────────────────

  /// Elevation for modal / alert dialogs.
  static const double dialog   = 24.0;

  /// Elevation for dropdown menus and popups.
  static const double menu     =  8.0;

  /// Elevation for floating action buttons.
  static const double floating =  6.0;
}
