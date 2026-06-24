import 'package:flutter/material.dart';
import 'workspace_registry.dart';

/// Rendering boundary between the navigation layer and workspace widgets.
///
/// [WorkspaceHost] accepts a [workspaceId] string and delegates resolution
/// entirely to [WorkspaceRegistry] — it contains no switch logic of its own.
/// This means navigation code never needs to import individual workspace files.
///
/// Usage:
/// ```dart
/// WorkspaceHost(workspaceId: controller.selectedDestination.id)
/// ```
class WorkspaceHost extends StatelessWidget {
  /// The ID of the workspace to render.
  final String workspaceId;

  const WorkspaceHost({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context) {
    return WorkspaceRegistry.buildWorkspace(workspaceId);
  }
}
