import 'package:flutter/material.dart';
import 'package:chiplens_lite/ui/responsive/responsive_layout.dart';
import 'navigation_controller.dart';
import 'navigation_item.dart';

/// Responsive navigation widget for the ChipLens workbench.
///
/// Renders the correct navigation chrome based on the current [DeviceType]:
///
/// | Device type       | Navigation pattern                              |
/// |-------------------|-------------------------------------------------|
/// | mobile            | [Drawer] opened via hamburger in [AppBar]       |
/// | tablet            | Compact [NavigationRail] (icon + selected label)|
/// | desktop / large   | Extended [NavigationRail] (persistent sidebar)  |
///
/// When [controller.destinations] is empty, no navigation chrome is shown.
///
/// Pass [onDestinationSelected] to receive zero-based index callbacks when a
/// destination is activated. The controller is NOT updated internally — the
/// caller is responsible for state management.
class AdaptiveNavigation extends StatelessWidget {
  /// Current navigation state (destinations + selected index).
  final NavigationController controller;

  /// Called with the new index when the user activates a destination.
  final ValueChanged<int>? onDestinationSelected;

  /// Primary content placed to the right of (or below) the navigation chrome.
  final Widget body;

  /// Text shown in the [AppBar] title slot. When both [title] and [actions]
  /// are `null`, no [AppBar] is rendered on desktop/tablet layouts.
  final String? title;

  /// Optional trailing widgets for the [AppBar].
  final List<Widget>? actions;

  /// Optional [FloatingActionButton] forwarded to [Scaffold].
  final Widget? floatingActionButton;

  /// Optional [Scaffold.backgroundColor] override.
  final Color? backgroundColor;

  const AdaptiveNavigation({
    super.key,
    required this.controller,
    required this.body,
    this.onDestinationSelected,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
  });

  // ── Private helpers ───────────────────────────────────────────────────────

  bool get _hasNav => controller.destinations.isNotEmpty;

  bool get _hasAppBar =>
      title != null || (actions != null && actions!.isNotEmpty);

  PreferredSizeWidget _buildAppBar() => AppBar(
        title:   title != null ? Text(title!) : null,
        actions: actions,
      );

  Widget _buildDrawer(BuildContext context) {
    final dests = controller.destinations;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (title != null)
            DrawerHeader(
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          for (var i = 0; i < dests.length; i++)
            _buildDrawerTile(context, i, dests[i]),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
      BuildContext context, int index, NavigationItem item) {
    final isSelected = index == controller.selectedIndex;
    return ListTile(
      leading: Icon(isSelected ? (item.selectedIcon ?? item.icon) : item.icon),
      title:   Text(item.title),
      selected: isSelected,
      enabled:  item.enabled,
      onTap: item.enabled
          ? () {
              Navigator.of(context).pop();
              onDestinationSelected?.call(index);
            }
          : null,
    );
  }

  NavigationRail _buildRail({required bool extended}) {
    return NavigationRail(
      destinations: controller.destinations.map((item) {
        return NavigationRailDestination(
          icon: Tooltip(
            message: item.tooltip,
            child: Icon(item.icon),
          ),
          selectedIcon: Tooltip(
            message: item.tooltip,
            child: Icon(item.selectedIcon ?? item.icon),
          ),
          label: Text(item.title),
        );
      }).toList(),
      selectedIndex:         controller.selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended:              extended,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layout = ResponsiveLayout.of(context);

    // No destinations — simple scaffold with no navigation chrome.
    if (!_hasNav) {
      return Scaffold(
        backgroundColor:      backgroundColor,
        appBar:               _hasAppBar ? _buildAppBar() : null,
        body:                 body,
        floatingActionButton: floatingActionButton,
      );
    }

    // Mobile: drawer-based navigation.
    if (layout.isMobile) {
      return Scaffold(
        backgroundColor:      backgroundColor,
        appBar:               _buildAppBar(),
        drawer:               _buildDrawer(context),
        body:                 body,
        floatingActionButton: floatingActionButton,
      );
    }

    // Tablet: compact rail.  Desktop / LargeDesktop: extended (persistent) rail.
    final extended = !layout.isTablet;

    return Scaffold(
      backgroundColor:      backgroundColor,
      appBar:               _hasAppBar ? _buildAppBar() : null,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          _buildRail(extended: extended),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
