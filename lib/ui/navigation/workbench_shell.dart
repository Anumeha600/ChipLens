import 'package:flutter/material.dart';
import 'adaptive_navigation.dart';
import 'navigation_controller.dart';

/// Top-level shell for the ChipLens engineering workbench.
///
/// [WorkbenchShell] composes [AdaptiveNavigation] with workbench-level
/// conveniences:
///
/// - When [title] is omitted, the AppBar title is automatically derived from
///   [controller.selectedDestination.title].
/// - Future extension: breadcrumbs, status bar, inspector panel can be wired
///   in here without touching individual workspace screens.
///
/// Usage — every future workspace screen simply provides a [body]:
/// ```dart
/// WorkbenchShell(
///   controller: myController,
///   onDestinationSelected: (i) => setState(() => myController = myController.selectDestination(i)),
///   body: const DashboardView(),
/// )
/// ```
class WorkbenchShell extends StatelessWidget {
  /// Current navigation state.
  final NavigationController controller;

  /// Called with the zero-based index when the user activates a destination.
  final ValueChanged<int>? onDestinationSelected;

  /// Primary workspace content.
  final Widget body;

  /// AppBar title. When `null`, derives the title from
  /// [controller.selectedDestination.title].
  final String? title;

  /// Optional trailing actions for the [AppBar].
  final List<Widget>? actions;

  /// Optional [FloatingActionButton] forwarded to the inner [Scaffold].
  final Widget? floatingActionButton;

  /// Optional [Scaffold.backgroundColor] override.
  final Color? backgroundColor;

  const WorkbenchShell({
    super.key,
    required this.controller,
    required this.body,
    this.onDestinationSelected,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
  });

  String get _resolvedTitle =>
      title ?? controller.selectedDestination.title;

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      controller:            controller,
      onDestinationSelected: onDestinationSelected,
      body:                  body,
      title:                 _resolvedTitle,
      actions:               actions,
      floatingActionButton:  floatingActionButton,
      backgroundColor:       backgroundColor,
    );
  }
}
