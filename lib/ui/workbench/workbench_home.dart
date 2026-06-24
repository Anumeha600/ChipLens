import 'package:flutter/material.dart';
import 'package:chiplens_lite/ui/navigation/navigation.dart';
import 'workbench_screen.dart';

/// Root application shell for the ChipLens workbench.
///
/// [WorkbenchHome] owns the [NavigationController] state and wires navigation
/// selection changes through to [WorkbenchScreen], which resolves workspace IDs
/// to their corresponding feature screens.
///
/// Architecture:
/// ```
/// WorkbenchHome   ← state owner (NavigationController)
///   └── WorkbenchShell  ← navigation chrome (AppBar, Rail, Drawer)
///         └── WorkbenchScreen  ← workspace-to-screen bridge
///               └── HomeScreen | NlToRtlScreen | _ComingSoon | …
/// ```
///
/// Set this as `home:` in [MaterialApp] after backend discovery completes.
class WorkbenchHome extends StatefulWidget {
  const WorkbenchHome({super.key});

  @override
  State<WorkbenchHome> createState() => _WorkbenchHomeState();
}

class _WorkbenchHomeState extends State<WorkbenchHome> {
  NavigationController _controller = NavigationController.workspaces();

  void _onDestinationSelected(int index) {
    setState(() {
      _controller = _controller.selectDestination(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WorkbenchShell(
      controller: _controller,
      onDestinationSelected: _onDestinationSelected,
      body: WorkbenchScreen(workspaceId: _controller.selectedDestination.id),
    );
  }
}
