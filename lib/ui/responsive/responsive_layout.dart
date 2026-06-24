import 'package:flutter/material.dart';
import 'breakpoints.dart';

// ─── ResponsiveLayout ─────────────────────────────────────────────────────────

/// Immutable snapshot of the responsive context at a given [BuildContext].
///
/// Obtain via [ResponsiveLayout.of]:
/// ```dart
/// final layout = ResponsiveLayout.of(context);
/// if (layout.isMobile) { ... }
/// ```
///
/// No state is stored after construction. Each [of] call reads [MediaQuery]
/// afresh — subscribe with `MediaQuery.of` if you need reactive rebuilds.
@immutable
class ResponsiveLayout {
  /// Current screen width in logical pixels.
  final double screenWidth;

  /// Current screen height in logical pixels.
  final double screenHeight;

  /// Device category inferred from [screenWidth].
  final DeviceType deviceType;

  const ResponsiveLayout({
    required this.screenWidth,
    required this.screenHeight,
    required this.deviceType,
  });

  /// Creates a [ResponsiveLayout] snapshot from [context]'s [MediaQuery].
  factory ResponsiveLayout.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ResponsiveLayout(
      screenWidth:  size.width,
      screenHeight: size.height,
      deviceType:   ResponsiveBreakpoints.getDeviceType(size.width),
    );
  }

  // ── Device-type booleans ──────────────────────────────────────────────────

  /// `true` on phones and narrow viewports (< 600 dp).
  bool get isMobile       => deviceType == DeviceType.mobile;

  /// `true` on tablets (600–1023 dp).
  bool get isTablet       => deviceType == DeviceType.tablet;

  /// `true` on desktop viewports (1024–1439 dp).
  bool get isDesktop      => deviceType == DeviceType.desktop;

  /// `true` on wide desktop monitors (≥ 1440 dp).
  bool get isLargeDesktop => deviceType == DeviceType.largeDesktop;

  // ── Adaptive value selection ──────────────────────────────────────────────

  /// Returns the value appropriate for the current [deviceType].
  ///
  /// [largeDesktop] is optional; when omitted, [desktop] is returned for
  /// screens that are ≥ [ResponsiveBreakpoints.largeDesktopMinWidth].
  T value<T>({
    required T mobile,
    required T tablet,
    required T desktop,
    T? largeDesktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop;
    }
  }

  // ── Percentage-based dimensions ───────────────────────────────────────────

  /// Returns [percent]% of [screenWidth] in logical pixels.
  ///
  /// Example: `layout.widthPercent(50)` → half the screen width.
  double widthPercent(double percent) => screenWidth * percent / 100.0;

  /// Returns [percent]% of [screenHeight] in logical pixels.
  ///
  /// Example: `layout.heightPercent(25)` → quarter of the screen height.
  double heightPercent(double percent) => screenHeight * percent / 100.0;
}
