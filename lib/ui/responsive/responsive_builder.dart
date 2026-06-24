import 'package:flutter/material.dart';
import 'breakpoints.dart';

// ─── ResponsiveBuilder ────────────────────────────────────────────────────────

/// A widget that selects among four layout builders based on the available
/// width, measured via [LayoutBuilder] for accurate constraint propagation.
///
/// Usage:
/// ```dart
/// ResponsiveBuilder(
///   mobile:  (ctx) => const MobileLayout(),
///   tablet:  (ctx) => const TabletLayout(),
///   desktop: (ctx) => const DesktopLayout(),
/// )
/// ```
///
/// [largeDesktop] is optional; when omitted, [desktop] is used for screens
/// that are ≥ [ResponsiveBreakpoints.largeDesktopMinWidth].
///
/// No layout logic is duplicated between builders — selection delegates
/// entirely to [ResponsiveBreakpoints.getDeviceType].
class ResponsiveBuilder extends StatelessWidget {
  /// Builder invoked when the available width maps to [DeviceType.mobile].
  final WidgetBuilder mobile;

  /// Builder invoked when the available width maps to [DeviceType.tablet].
  final WidgetBuilder tablet;

  /// Builder invoked when the available width maps to [DeviceType.desktop].
  final WidgetBuilder desktop;

  /// Optional builder for [DeviceType.largeDesktop]; falls back to [desktop].
  final WidgetBuilder? largeDesktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType =
            ResponsiveBreakpoints.getDeviceType(constraints.maxWidth);
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile(context);
          case DeviceType.tablet:
            return tablet(context);
          case DeviceType.desktop:
            return desktop(context);
          case DeviceType.largeDesktop:
            return (largeDesktop ?? desktop)(context);
        }
      },
    );
  }
}
