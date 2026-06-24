import 'package:chiplens_lite/ui/theme/app_icons.dart';
import 'navigation_item.dart';

/// Centralized predefined navigation destinations for the ChipLens workbench.
///
/// All constants are `static const` — zero runtime cost.
///
/// Destination groups:
/// - [workspaces]: the six primary engineering workspaces.
/// - [system]: utility destinations (Settings, Help).
/// - [all]: complete ordered list of every destination.
class NavigationDestinations {
  const NavigationDestinations._();

  // ── Primary workspaces ────────────────────────────────────────────────────

  static const NavigationItem dashboard = NavigationItem(
    id:      'dashboard',
    title:   'Dashboard',
    icon:    AppIcons.dashboard,
    tooltip: 'Go to Dashboard',
  );

  static const NavigationItem rtl = NavigationItem(
    id:      'rtl',
    title:   'RTL Workspace',
    icon:    AppIcons.folder,
    tooltip: 'Open RTL Workspace',
  );

  static const NavigationItem verification = NavigationItem(
    id:      'verification',
    title:   'Verification',
    icon:    AppIcons.verification,
    tooltip: 'Formal Verification',
  );

  static const NavigationItem coverage = NavigationItem(
    id:      'coverage',
    title:   'Coverage',
    icon:    AppIcons.coverage,
    tooltip: 'Coverage Analysis',
  );

  static const NavigationItem diagnostics = NavigationItem(
    id:      'diagnostics',
    title:   'Diagnostics',
    icon:    AppIcons.diagnostics,
    tooltip: 'Diagnostics Intelligence',
  );

  static const NavigationItem repair = NavigationItem(
    id:      'repair',
    title:   'Repair Planning',
    icon:    AppIcons.repair,
    tooltip: 'Repair Planning',
  );

  // ── System destinations ───────────────────────────────────────────────────

  static const NavigationItem settings = NavigationItem(
    id:      'settings',
    title:   'Settings',
    icon:    AppIcons.settings,
    tooltip: 'Application Settings',
  );

  static const NavigationItem help = NavigationItem(
    id:      'help',
    title:   'Help',
    icon:    AppIcons.help,
    tooltip: 'Help & Documentation',
  );

  // ── Destination groups ────────────────────────────────────────────────────

  /// Six primary engineering workspaces — the main workbench destinations.
  static const List<NavigationItem> workspaces = [
    dashboard,
    rtl,
    verification,
    coverage,
    diagnostics,
    repair,
  ];

  /// Utility destinations shown at the bottom of navigation chrome.
  static const List<NavigationItem> system = [settings, help];

  /// Ordered list of every destination (workspaces then system).
  static const List<NavigationItem> all = [
    dashboard,
    rtl,
    verification,
    coverage,
    diagnostics,
    repair,
    settings,
    help,
  ];
}
