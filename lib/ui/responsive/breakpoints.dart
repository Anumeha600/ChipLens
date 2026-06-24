import 'package:flutter/foundation.dart';

// ─── DeviceType ───────────────────────────────────────────────────────────────

/// Detected device category derived from screen width.
enum DeviceType { mobile, tablet, desktop, largeDesktop }

// ─── ResponsiveBreakpoints ────────────────────────────────────────────────────

/// Immutable, stateless breakpoint constants and classification utilities.
///
/// Breakpoint table (logical pixels / dp):
/// ```
/// mobile       0   – 599
/// tablet       600 – 1023
/// desktop      1024 – 1439
/// largeDesktop 1440 +
/// ```
///
/// All members are `static`. The class cannot be instantiated.
@immutable
class ResponsiveBreakpoints {
  // Private constructor — purely static class.
  const ResponsiveBreakpoints._();

  // ── Min-inclusive widths for each tier above mobile ───────────────────────

  /// Minimum width (dp) for the tablet tier.
  static const double tabletMinWidth = 600.0;

  /// Minimum width (dp) for the desktop tier.
  static const double desktopMinWidth = 1024.0;

  /// Minimum width (dp) for the large-desktop tier.
  static const double largeDesktopMinWidth = 1440.0;

  // ── Classification ────────────────────────────────────────────────────────

  /// Returns the [DeviceType] for the given logical [width] in dp.
  static DeviceType getDeviceType(double width) {
    if (width >= largeDesktopMinWidth) return DeviceType.largeDesktop;
    if (width >= desktopMinWidth)      return DeviceType.desktop;
    if (width >= tabletMinWidth)       return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Returns `true` when [width] falls in the mobile tier (< 600 dp).
  static bool isMobile(double width) =>
      getDeviceType(width) == DeviceType.mobile;

  /// Returns `true` when [width] falls in the tablet tier (600–1023 dp).
  static bool isTablet(double width) =>
      getDeviceType(width) == DeviceType.tablet;

  /// Returns `true` when [width] falls in the desktop tier (1024–1439 dp).
  static bool isDesktop(double width) =>
      getDeviceType(width) == DeviceType.desktop;

  /// Returns `true` when [width] falls in the large-desktop tier (≥ 1440 dp).
  static bool isLargeDesktop(double width) =>
      getDeviceType(width) == DeviceType.largeDesktop;
}
