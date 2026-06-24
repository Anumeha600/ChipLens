import 'package:flutter/material.dart';

/// Corner-radius constants for the ChipLens design system.
///
/// Values are `static const` [BorderRadius] objects — use them directly in
/// `decoration`, `shape`, or any widget that accepts `BorderRadius`.
class AppRadius {
  const AppRadius._();

  // ── Raw Radius values (for ClipRRect, Chip borders, etc.) ────────────────

  static const Radius radiusNone = Radius.zero;
  static const Radius radiusXS   = Radius.circular(4.0);
  static const Radius radiusSM   = Radius.circular(8.0);
  static const Radius radiusMD   = Radius.circular(12.0);
  static const Radius radiusLG   = Radius.circular(16.0);
  static const Radius radiusXL   = Radius.circular(24.0);
  static const Radius radiusPill = Radius.circular(9999.0);

  // ── BorderRadius shorthands ───────────────────────────────────────────────

  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius xs   = BorderRadius.all(radiusXS);
  static const BorderRadius sm   = BorderRadius.all(radiusSM);
  static const BorderRadius md   = BorderRadius.all(radiusMD);
  static const BorderRadius lg   = BorderRadius.all(radiusLG);
  static const BorderRadius xl   = BorderRadius.all(radiusXL);

  /// Fully-rounded pill shape, suitable for chips, badges, and FABs.
  static const BorderRadius pill = BorderRadius.all(radiusPill);
}
