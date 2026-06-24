import 'package:flutter/material.dart';
import 'package:chiplens_lite/home_screen.dart';
import 'package:chiplens_lite/nl_to_rtl_screen.dart';

/// Bridge between the navigation layer and feature screens.
///
/// [WorkbenchScreen] resolves a workspace [id] to the corresponding
/// feature screen (or a "Coming Soon" placeholder when functionality
/// is not yet available).
///
/// This is the only file in the workbench layer that imports feature screens
/// directly. All other workbench files remain agnostic of application content.
///
/// | workspaceId     | Renders                    |
/// |-----------------|----------------------------|
/// | dashboard       | [HomeScreen]               |
/// | rtl             | [NlToRtlScreen]            |
/// | verification    | Coming Soon placeholder    |
/// | coverage        | Coming Soon placeholder    |
/// | diagnostics     | Coming Soon placeholder    |
/// | repair          | Coming Soon placeholder    |
/// | settings/help   | Coming Soon placeholder    |
/// | unknown         | "Workspace Not Found"      |
class WorkbenchScreen extends StatelessWidget {
  /// The workspace identifier driven by [NavigationController.selectedDestination.id].
  final String workspaceId;

  const WorkbenchScreen({super.key, required this.workspaceId});

  Widget _resolve() {
    switch (workspaceId) {
      case 'dashboard':
        return const HomeScreen();
      case 'rtl':
        return const NlToRtlScreen();
      case 'verification':
        return const _ComingSoon('Verification Workspace');
      case 'coverage':
        return const _ComingSoon('Coverage Workspace');
      case 'diagnostics':
        return const _ComingSoon('Diagnostics Workspace');
      case 'repair':
        return const _ComingSoon('Repair Workspace');
      case 'settings':
        return const _ComingSoon('Settings');
      case 'help':
        return const _ComingSoon('Help');
      default:
        return const Center(child: Text('Workspace Not Found'));
    }
  }

  @override
  Widget build(BuildContext context) => _resolve();
}

// ── Private placeholder ────────────────────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$label Coming Soon'));
  }
}
