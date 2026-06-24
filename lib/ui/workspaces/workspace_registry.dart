import 'package:flutter/material.dart';
import 'coverage_workspace.dart';
import 'dashboard_workspace.dart';
import 'diagnostics_workspace.dart';
import 'repair_workspace.dart';
import 'rtl_workspace.dart';
import 'verification_workspace.dart';

/// Maps workspace IDs to their corresponding workspace widgets.
///
/// This is the single source of truth for workspace resolution. Navigation
/// code never references workspace widgets directly — it always goes through
/// [buildWorkspace].
///
/// Unknown IDs return a fallback widget rather than throwing, so navigation
/// transitions never crash on an unregistered workspace.
class WorkspaceRegistry {
  const WorkspaceRegistry._();

  /// Returns the workspace widget for [workspaceId].
  ///
  /// Returns a "Workspace Not Found" placeholder for unrecognized IDs.
  static Widget buildWorkspace(String workspaceId) {
    switch (workspaceId) {
      case 'dashboard':
        return const DashboardWorkspace();
      case 'rtl':
        return const RTLWorkspace();
      case 'verification':
        return const VerificationWorkspace();
      case 'coverage':
        return const CoverageWorkspace();
      case 'diagnostics':
        return const DiagnosticsWorkspace();
      case 'repair':
        return const RepairWorkspace();
      default:
        return const Center(child: Text('Workspace Not Found'));
    }
  }
}
