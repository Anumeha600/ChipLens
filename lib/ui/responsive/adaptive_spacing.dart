import 'package:flutter/material.dart';
import 'responsive_layout.dart';

// ─── AdaptiveSpacing ──────────────────────────────────────────────────────────

/// Centralised spacing constants and context-aware adaptive helpers.
///
/// Base constants follow an 8-point grid:
/// ```
/// xs  =  4 dp
/// sm  =  8 dp
/// md  = 16 dp
/// lg  = 24 dp
/// xl  = 32 dp
/// xxl = 48 dp
/// ```
///
/// Adaptive helpers ([pagePadding], [sectionSpacing], [cardPadding],
/// [buttonHeight]) read the current [DeviceType] from [ResponsiveLayout]
/// and return a device-appropriate value.
///
/// The class cannot be instantiated — all members are `static`.
class AdaptiveSpacing {
  const AdaptiveSpacing._();

  // ── Base spacing scale ────────────────────────────────────────────────────

  /// Extra-small spacing: 4 dp.
  static const double xs = 4.0;

  /// Small spacing: 8 dp.
  static const double sm = 8.0;

  /// Medium spacing: 16 dp.
  static const double md = 16.0;

  /// Large spacing: 24 dp.
  static const double lg = 24.0;

  /// Extra-large spacing: 32 dp.
  static const double xl = 32.0;

  /// Double-extra-large spacing: 48 dp.
  static const double xxl = 48.0;

  // ── Adaptive padding helpers ──────────────────────────────────────────────

  /// Outer page padding for top-level content areas.
  ///
  /// Returns `md` on mobile, `lg` on tablet, `xl` on desktop,
  /// `xxl` on large desktop.
  static EdgeInsets pagePadding(BuildContext context) {
    return ResponsiveLayout.of(context).value(
      mobile:       const EdgeInsets.all(md),
      tablet:       const EdgeInsets.all(lg),
      desktop:      const EdgeInsets.all(xl),
      largeDesktop: const EdgeInsets.all(xxl),
    );
  }

  /// Vertical gap between page-level sections.
  ///
  /// Returns `lg` on mobile, `xl` on tablet, `xxl` on desktop,
  /// `64` on large desktop.
  static double sectionSpacing(BuildContext context) {
    return ResponsiveLayout.of(context).value<double>(
      mobile:       lg,
      tablet:       xl,
      desktop:      xxl,
      largeDesktop: 64.0,
    );
  }

  /// Inner padding for card-like containers.
  ///
  /// Returns `md` on mobile, `lg` on tablet, `xl` on desktop and above.
  static EdgeInsets cardPadding(BuildContext context) {
    return ResponsiveLayout.of(context).value(
      mobile:  const EdgeInsets.all(md),
      tablet:  const EdgeInsets.all(lg),
      desktop: const EdgeInsets.all(xl),
    );
  }

  /// Minimum recommended height for tappable buttons.
  ///
  /// Returns 44 dp on mobile, 48 dp on tablet, 52 dp on desktop and above.
  static double buttonHeight(BuildContext context) {
    return ResponsiveLayout.of(context).value<double>(
      mobile:  44.0,
      tablet:  48.0,
      desktop: 52.0,
    );
  }
}
