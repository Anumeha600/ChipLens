import 'package:flutter/material.dart';
import 'package:chiplens_lite/ui/workspaces/workspace_host.dart';
import 'adaptive_navigation.dart';
import 'navigation_controller.dart';

/// Top-level shell for the ChipLens engineering workbench.
///
/// [WorkbenchShell] composes [AdaptiveNavigation] with workbench-level
/// conveniences:
///
/// - When [title] is omitted, the AppBar title is automatically derived from
///   [controller.selectedDestination.title].
/// - When [body] is omitted, the selected destination's id is resolved to a
///   workspace widget via [WorkspaceHost] — callers do not need to wire up
///   workspace widgets manually.
/// - Future extension: breadcrumbs, status bar, inspector panel can be wired
///   in here without touching individual workspace screens.
///
/// Minimal usage — no body required:
/// ```dart
/// WorkbenchShell(
///   controller: myController,
///   onDestinationSelected: (i) => setState(
///       () => myController = myController.selectDestination(i)),
/// )
/// ```
///
/// Override the resolved workspace widget when needed:
/// ```dart
/// WorkbenchShell(
///   controller: myController,
///   onDestinationSelected: ...,
///   body: const CustomView(),
/// )
/// ```
class WorkbenchShell extends StatelessWidget {
  /// Current navigation state.
  final NavigationController controller;

  /// Called with the zero-based index when the user activates a destination.
  final ValueChanged<int>? onDestinationSelected;

  /// Override for the workspace content area.
  ///
  /// When `null`, [WorkspaceHost] resolves the correct workspace widget from
  /// [controller.selectedDestination.id]. Requires [controller.destinations]
  /// to be non-empty in that case.
  final Widget? body;

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
    this.onDestinationSelected,
    this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
  });

  String get _resolvedTitle =>
      title ?? controller.selectedDestination.title;

  Widget _resolvedBody() => body ??
      WorkspaceHost(workspaceId: controller.selectedDestination.id);

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      controller:            controller,
      onDestinationSelected: onDestinationSelected,
      body:                  _resolvedBody(),
      title:                 _resolvedTitle,
      actions:               actions,
      floatingActionButton:  floatingActionButton,
      backgroundColor:       backgroundColor,
    );
  }
}
