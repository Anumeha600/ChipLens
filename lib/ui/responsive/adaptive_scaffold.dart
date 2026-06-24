import 'package:flutter/material.dart';
import 'responsive_layout.dart';

// ─── AdaptiveDestination ──────────────────────────────────────────────────────

/// A navigation destination entry consumed by [AdaptiveScaffold].
@immutable
class AdaptiveDestination {
  /// Icon shown in an unselected state.
  final Widget icon;

  /// Icon shown in the selected state; falls back to [icon] when null.
  final Widget? selectedIcon;

  /// Human-readable label for this destination.
  final String label;

  const AdaptiveDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

// ─── AdaptiveScaffold ─────────────────────────────────────────────────────────

/// A [Scaffold] wrapper that automatically adapts its navigation pattern to
/// the current [DeviceType]:
///
/// | Device type       | Navigation pattern                         |
/// |-------------------|--------------------------------------------|
/// | mobile            | [Drawer] (hamburger in [AppBar])           |
/// | tablet            | Compact [NavigationRail] (icon + label)    |
/// | desktop / large   | Extended [NavigationRail] (persistent sidebar) |
///
/// When [destinations] is `null` or empty, no navigation chrome is rendered.
///
/// Parameters forwarded directly to the underlying [Scaffold]:
/// [title], [actions], [body], [floatingActionButton], [backgroundColor].
class AdaptiveScaffold extends StatelessWidget {
  /// Text displayed in the [AppBar] title.
  ///
  /// When both [title] and [actions] are `null`, no [AppBar] is rendered.
  final String? title;

  /// Trailing action widgets for the [AppBar].
  final List<Widget>? actions;

  /// Primary content of the screen.
  final Widget body;

  /// Optional floating action button forwarded to [Scaffold.floatingActionButton].
  final Widget? floatingActionButton;

  /// Optional override for [Scaffold.backgroundColor].
  final Color? backgroundColor;

  /// Navigation destinations for [Drawer] / [NavigationRail].
  ///
  /// Pass `null` or an empty list to suppress all navigation chrome.
  final List<AdaptiveDestination>? destinations;

  /// Index of the currently selected [AdaptiveDestination].
  final int selectedIndex;

  /// Callback invoked when a destination is tapped.
  final ValueChanged<int>? onDestinationSelected;

  const AdaptiveScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
    this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  // ── Private helpers ───────────────────────────────────────────────────────

  bool get _hasNav => destinations != null && destinations!.isNotEmpty;

  bool get _hasAppBar =>
      title != null || (actions != null && actions!.isNotEmpty);

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: title != null ? Text(title!) : null,
        actions: actions,
      );

  Widget _buildDrawer(BuildContext context) {
    final dests = destinations!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (title != null) DrawerHeader(child: Text(title!)),
          for (var i = 0; i < dests.length; i++)
            ListTile(
              leading: i == selectedIndex
                  ? (dests[i].selectedIcon ?? dests[i].icon)
                  : dests[i].icon,
              title: Text(dests[i].label),
              selected: i == selectedIndex,
              onTap: () {
                Navigator.of(context).pop();
                onDestinationSelected?.call(i);
              },
            ),
        ],
      ),
    );
  }

  List<NavigationRailDestination> _buildRailDestinations() =>
      destinations!
          .map(
            (d) => NavigationRailDestination(
              icon:         d.icon,
              selectedIcon: d.selectedIcon,
              label:        Text(d.label),
            ),
          )
          .toList();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layout = ResponsiveLayout.of(context);

    // No navigation destinations — simple scaffold.
    if (!_hasNav) {
      return Scaffold(
        backgroundColor:      backgroundColor,
        appBar:               _hasAppBar ? _buildAppBar() : null,
        body:                 body,
        floatingActionButton: floatingActionButton,
      );
    }

    // Mobile: Drawer opened via hamburger in AppBar.
    if (layout.isMobile) {
      return Scaffold(
        backgroundColor:      backgroundColor,
        appBar:               _hasAppBar ? _buildAppBar() : null,
        drawer:               _buildDrawer(context),
        body:                 body,
        floatingActionButton: floatingActionButton,
      );
    }

    // Tablet: compact NavigationRail (icons + selected label).
    // Desktop / LargeDesktop: extended NavigationRail (persistent sidebar).
    final extended = !layout.isTablet;

    return Scaffold(
      backgroundColor:      backgroundColor,
      appBar:               _hasAppBar ? _buildAppBar() : null,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            destinations:          _buildRailDestinations(),
            selectedIndex:         selectedIndex,
            onDestinationSelected: onDestinationSelected ?? (_) {},
            extended:              extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
