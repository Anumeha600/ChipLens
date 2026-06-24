import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/ui/navigation/navigation.dart';
import 'package:chiplens_lite/ui/workspaces/workspaces.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _app(Widget home) => MaterialApp(home: home);

void _setSize(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
}

void _resetSize(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Workspace value object
  // ──────────────────────────────────────────────────────────────────────────

  group('Workspace —', () {
    const ws = Workspace(id: 'test', title: 'Test');

    test('id is stored', () => expect(ws.id, 'test'));
    test('title is stored', () => expect(ws.title, 'Test'));
    test('icon defaults to null', () => expect(ws.icon, isNull));
    test('description defaults to null', () => expect(ws.description, isNull));

    test('icon is stored when provided', () {
      const w = Workspace(id: 'x', title: 'X', icon: Icons.home);
      expect(w.icon, Icons.home);
    });

    test('description is stored when provided', () {
      const w = Workspace(id: 'x', title: 'X', description: 'A workspace');
      expect(w.description, 'A workspace');
    });

    test('equality: same values → equal', () {
      const a = Workspace(id: 'test', title: 'Test');
      const b = Workspace(id: 'test', title: 'Test');
      expect(a, b);
    });

    test('equality: different id → not equal', () {
      const a = Workspace(id: 'a', title: 'Test');
      const b = Workspace(id: 'b', title: 'Test');
      expect(a, isNot(b));
    });

    test('equality: different title → not equal', () {
      const a = Workspace(id: 'x', title: 'A');
      const b = Workspace(id: 'x', title: 'B');
      expect(a, isNot(b));
    });

    test('equality: different icon → not equal', () {
      const a = Workspace(id: 'x', title: 'X', icon: Icons.home);
      const b = Workspace(id: 'x', title: 'X', icon: Icons.star);
      expect(a, isNot(b));
    });

    test('equality: different description → not equal', () {
      const a = Workspace(id: 'x', title: 'X', description: 'desc a');
      const b = Workspace(id: 'x', title: 'X', description: 'desc b');
      expect(a, isNot(b));
    });

    test('hashCode consistent for same values', () {
      const a = Workspace(id: 'test', title: 'Test');
      const b = Workspace(id: 'test', title: 'Test');
      expect(a.hashCode, b.hashCode);
    });

    test('hashCode differs for different id', () {
      const a = Workspace(id: 'a', title: 'Test');
      const b = Workspace(id: 'b', title: 'Test');
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('identical instance equals itself', () {
      expect(ws, ws);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkspaceRegistry — type resolution
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkspaceRegistry — type resolution', () {
    test("'dashboard' → DashboardWorkspace", () {
      expect(WorkspaceRegistry.buildWorkspace('dashboard'),
          isA<DashboardWorkspace>());
    });

    test("'rtl' → RTLWorkspace", () {
      expect(WorkspaceRegistry.buildWorkspace('rtl'), isA<RTLWorkspace>());
    });

    test("'verification' → VerificationWorkspace", () {
      expect(WorkspaceRegistry.buildWorkspace('verification'),
          isA<VerificationWorkspace>());
    });

    test("'coverage' → CoverageWorkspace", () {
      expect(WorkspaceRegistry.buildWorkspace('coverage'),
          isA<CoverageWorkspace>());
    });

    test("'diagnostics' → DiagnosticsWorkspace", () {
      expect(WorkspaceRegistry.buildWorkspace('diagnostics'),
          isA<DiagnosticsWorkspace>());
    });

    test("'repair' → RepairWorkspace", () {
      expect(WorkspaceRegistry.buildWorkspace('repair'),
          isA<RepairWorkspace>());
    });

    test('unknown id returns Center widget', () {
      expect(WorkspaceRegistry.buildWorkspace('unknown'), isA<Center>());
    });

    test('empty string returns Center widget', () {
      expect(WorkspaceRegistry.buildWorkspace(''), isA<Center>());
    });

    test('case-sensitive: Dashboard (capital D) is not found', () {
      expect(WorkspaceRegistry.buildWorkspace('Dashboard'), isNot(isA<DashboardWorkspace>()));
    });

    test('all known IDs return non-null widgets', () {
      const ids = [
        'dashboard', 'rtl', 'verification', 'coverage', 'diagnostics', 'repair',
      ];
      for (final id in ids) {
        expect(WorkspaceRegistry.buildWorkspace(id), isNotNull,
            reason: "'$id' returned null");
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkspaceHost — widget rendering
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkspaceHost — rendering', () {
    testWidgets("renders DashboardWorkspace for 'dashboard'", (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'dashboard')));
      expect(find.byType(DashboardWorkspace), findsOneWidget);
    });

    testWidgets("renders RTLWorkspace for 'rtl'", (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'rtl')));
      expect(find.byType(RTLWorkspace), findsOneWidget);
    });

    testWidgets("renders VerificationWorkspace for 'verification'", (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'verification')));
      expect(find.byType(VerificationWorkspace), findsOneWidget);
    });

    testWidgets("renders CoverageWorkspace for 'coverage'", (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'coverage')));
      expect(find.byType(CoverageWorkspace), findsOneWidget);
    });

    testWidgets("renders DiagnosticsWorkspace for 'diagnostics'", (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'diagnostics')));
      expect(find.byType(DiagnosticsWorkspace), findsOneWidget);
    });

    testWidgets("renders RepairWorkspace for 'repair'", (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'repair')));
      expect(find.byType(RepairWorkspace), findsOneWidget);
    });

    testWidgets("renders fallback text for unknown id", (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'unknown')));
      expect(find.text('Workspace Not Found'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      expect(
        () async => tester.pumpWidget(_app(
            const WorkspaceHost(workspaceId: 'dashboard'))),
        returnsNormally,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Individual workspace content
  // ──────────────────────────────────────────────────────────────────────────

  group('DashboardWorkspace —', () {
    testWidgets('shows Dashboard Workspace text', (tester) async {
      await tester.pumpWidget(_app(const DashboardWorkspace()));
      expect(find.text('Dashboard Workspace'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_app(const DashboardWorkspace()));
      expect(tester.takeException(), isNull);
    });
  });

  group('RTLWorkspace —', () {
    testWidgets('shows RTL Workspace text', (tester) async {
      await tester.pumpWidget(_app(const RTLWorkspace()));
      expect(find.text('RTL Workspace'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_app(const RTLWorkspace()));
      expect(tester.takeException(), isNull);
    });
  });

  group('VerificationWorkspace —', () {
    testWidgets('shows Verification Workspace text', (tester) async {
      await tester.pumpWidget(_app(const VerificationWorkspace()));
      expect(find.text('Verification Workspace'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_app(const VerificationWorkspace()));
      expect(tester.takeException(), isNull);
    });
  });

  group('CoverageWorkspace —', () {
    testWidgets('shows Coverage Workspace text', (tester) async {
      await tester.pumpWidget(_app(const CoverageWorkspace()));
      expect(find.text('Coverage Workspace'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_app(const CoverageWorkspace()));
      expect(tester.takeException(), isNull);
    });
  });

  group('DiagnosticsWorkspace —', () {
    testWidgets('shows Diagnostics Workspace text', (tester) async {
      await tester.pumpWidget(_app(const DiagnosticsWorkspace()));
      expect(find.text('Diagnostics Workspace'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_app(const DiagnosticsWorkspace()));
      expect(tester.takeException(), isNull);
    });
  });

  group('RepairWorkspace —', () {
    testWidgets('shows Repair Workspace text', (tester) async {
      await tester.pumpWidget(_app(const RepairWorkspace()));
      expect(find.text('Repair Workspace'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_app(const RepairWorkspace()));
      expect(tester.takeException(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchShell integration
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchShell — workspace integration', () {
    testWidgets('default body resolves dashboard workspace', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
      )));
      await tester.pump();
      expect(find.text('Dashboard Workspace'), findsOneWidget);
    });

    testWidgets('verification selection shows verification workspace', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(selectedIndex: 2),
      )));
      await tester.pump();
      expect(find.text('Verification Workspace'), findsOneWidget);
    });

    testWidgets('coverage selection shows coverage workspace', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(selectedIndex: 3),
      )));
      await tester.pump();
      expect(find.text('Coverage Workspace'), findsOneWidget);
    });

    testWidgets('diagnostics selection shows diagnostics workspace', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(selectedIndex: 4),
      )));
      await tester.pump();
      expect(find.text('Diagnostics Workspace'), findsOneWidget);
    });

    testWidgets('repair selection shows repair workspace', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(selectedIndex: 5),
      )));
      await tester.pump();
      expect(find.text('Repair Workspace'), findsOneWidget);
    });

    testWidgets('rtl selection shows RTL workspace', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(selectedIndex: 1),
      )));
      await tester.pump();
      // RTLWorkspace type check avoids text collision with the AppBar title
      // ('RTL Workspace') which auto-derives from the destination title.
      expect(find.byType(RTLWorkspace), findsOneWidget);
    });

    testWidgets('explicit body overrides workspace resolution', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const Text('custom-body'),
      )));
      await tester.pump();
      expect(find.text('custom-body'), findsOneWidget);
      expect(find.text('Dashboard Workspace'), findsNothing);
    });

    testWidgets('title auto-derives from selected destination', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(selectedIndex: 2),
      )));
      await tester.pump();

      expect(find.text('Verification'), findsOneWidget);
    });

    testWidgets('workspace visible on mobile layout', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
      )));
      await tester.pump();

      expect(find.text('Dashboard Workspace'), findsOneWidget);
    });

    testWidgets('workspace visible on tablet layout', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
      )));
      await tester.pump();

      expect(find.text('Dashboard Workspace'), findsOneWidget);
    });

    testWidgets('workspace visible on desktop layout', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
      )));
      await tester.pump();

      expect(find.text('Dashboard Workspace'), findsOneWidget);
    });

    testWidgets('WorkspaceHost is in the tree when body is null', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
      )));
      await tester.pump();

      expect(find.byType(WorkspaceHost), findsOneWidget);
    });

    testWidgets('WorkspaceHost is absent when body is provided', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      expect(find.byType(WorkspaceHost), findsNothing);
    });

    testWidgets('navigation chrome still present with auto workspace', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
      )));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<Drawer>());
    });

    testWidgets('shell renders without error with all destinations', (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.all(),
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
