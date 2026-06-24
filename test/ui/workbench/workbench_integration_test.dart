import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/ui/workbench/workbench.dart';
import 'package:chiplens_lite/ui/navigation/navigation.dart';
import 'package:chiplens_lite/ui/workspaces/workspaces.dart';
import 'package:chiplens_lite/home_screen.dart';
import 'package:chiplens_lite/nl_to_rtl_screen.dart';

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

/// Sets a comfortable default size (800×600 logical) and registers the teardown.
/// Use for tests that just need HomeScreen / NlToRtlScreen to render without overflow.
void _defaultSize(WidgetTester tester) {
  _setSize(tester, 800, 600);
  addTearDown(() => _resetSize(tester));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchScreen — construction (pure tests, no widget tree needed)
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchScreen — construction', () {
    test('workspaceId is stored', () {
      const screen = WorkbenchScreen(workspaceId: 'dashboard');
      expect(screen.workspaceId, 'dashboard');
    });

    test('const constructible', () {
      expect(() => const WorkbenchScreen(workspaceId: 'rtl'), returnsNormally);
    });

    test('different ids produce different workspaceId values', () {
      const a = WorkbenchScreen(workspaceId: 'dashboard');
      const b = WorkbenchScreen(workspaceId: 'rtl');
      expect(a.workspaceId, isNot(b.workspaceId));
    });

    test('all known workspace ids are accepted without error', () {
      const ids = [
        'dashboard', 'rtl', 'verification', 'coverage', 'diagnostics',
        'repair', 'settings', 'help', 'unknown',
      ];
      for (final id in ids) {
        expect(
          () => WorkbenchScreen(workspaceId: id),
          returnsNormally,
          reason: "'$id' should construct without error",
        );
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchScreen — workspace resolution
  // All widget tests use 800×600 logical size so feature screens don't overflow.
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchScreen — workspace resolution', () {
    testWidgets("'dashboard' renders HomeScreen", (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'dashboard')));
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets("'rtl' renders NlToRtlScreen", (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'rtl')));
      await tester.pump();
      expect(find.byType(NlToRtlScreen), findsOneWidget);
    });

    testWidgets("'verification' shows coming soon text", (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'verification')));
      await tester.pump();
      expect(find.text('Verification Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets("'coverage' shows coming soon text", (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'coverage')));
      await tester.pump();
      expect(find.text('Coverage Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets("'diagnostics' shows coming soon text", (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'diagnostics')));
      await tester.pump();
      expect(find.text('Diagnostics Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets("'repair' shows coming soon text", (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'repair')));
      await tester.pump();
      expect(find.text('Repair Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets("'settings' shows coming soon text", (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'settings')));
      await tester.pump();
      expect(find.text('Settings Coming Soon'), findsOneWidget);
    });

    testWidgets("'help' shows coming soon text", (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'help')));
      await tester.pump();
      expect(find.text('Help Coming Soon'), findsOneWidget);
    });

    testWidgets('unknown id shows workspace not found', (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'unknown_xyz')));
      await tester.pump();
      expect(find.text('Workspace Not Found'), findsOneWidget);
    });

    testWidgets('empty id shows workspace not found', (tester) async {
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: '')));
      await tester.pump();
      expect(find.text('Workspace Not Found'), findsOneWidget);
    });

    testWidgets("'dashboard' does not show NlToRtlScreen", (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'dashboard')));
      await tester.pump();
      expect(find.byType(NlToRtlScreen), findsNothing);
    });

    testWidgets("'rtl' does not show HomeScreen", (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(
          const WorkbenchScreen(workspaceId: 'rtl')));
      await tester.pump();
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('coming-soon IDs do not render HomeScreen', (tester) async {
      const ids = ['verification', 'coverage', 'diagnostics', 'repair'];
      for (final id in ids) {
        await tester.pumpWidget(_app(WorkbenchScreen(workspaceId: id)));
        await tester.pump();
        expect(find.byType(HomeScreen), findsNothing,
            reason: "'$id' should not show HomeScreen");
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchHome — initial state
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchHome — initial state', () {
    testWidgets('renders without error', (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorkbenchShell is in the widget tree', (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();
      expect(find.byType(WorkbenchShell), findsOneWidget);
    });

    testWidgets('WorkbenchScreen is in the widget tree', (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();
      expect(find.byType(WorkbenchScreen), findsOneWidget);
    });

    testWidgets('initial workspace is dashboard — HomeScreen visible',
        (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('initial WorkbenchScreen.workspaceId is dashboard',
        (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();
      final screen =
          tester.widget<WorkbenchScreen>(find.byType(WorkbenchScreen));
      expect(screen.workspaceId, 'dashboard');
    });

    testWidgets('NlToRtlScreen is absent from initial tree', (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();
      expect(find.byType(NlToRtlScreen), findsNothing);
    });

    testWidgets(
        'WorkspaceHost absent — WorkbenchScreen bypasses WorkspaceRegistry',
        (tester) async {
      _defaultSize(tester);
      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();
      expect(find.byType(WorkspaceHost), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchHome — navigation (all tests use 800×1024 tablet layout)
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchHome — navigation', () {
    testWidgets('selecting rtl shows NlToRtlScreen', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(find.byIcon(NavigationDestinations.rtl.icon).first);
      await tester.pump();

      expect(find.byType(NlToRtlScreen), findsOneWidget);
    });

    testWidgets('selecting verification shows coming soon', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.verification.icon).first);
      await tester.pump();

      expect(find.text('Verification Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets('selecting coverage shows coming soon', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.coverage.icon).first);
      await tester.pump();

      expect(find.text('Coverage Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets('selecting diagnostics shows coming soon', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.diagnostics.icon).first);
      await tester.pump();

      expect(find.text('Diagnostics Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets('selecting repair shows coming soon', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.repair.icon).first);
      await tester.pump();

      expect(find.text('Repair Workspace Coming Soon'), findsOneWidget);
    });

    testWidgets('navigating to rtl then back to dashboard restores HomeScreen',
        (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(find.byIcon(NavigationDestinations.rtl.icon).first);
      await tester.pump();
      expect(find.byType(NlToRtlScreen), findsOneWidget);

      await tester.tap(
          find.byIcon(NavigationDestinations.dashboard.icon).first);
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(NlToRtlScreen), findsNothing);
    });

    testWidgets('WorkbenchScreen.workspaceId updates after navigation',
        (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(find.byIcon(NavigationDestinations.rtl.icon).first);
      await tester.pump();

      final screen =
          tester.widget<WorkbenchScreen>(find.byType(WorkbenchScreen));
      expect(screen.workspaceId, 'rtl');
    });

    testWidgets('re-selecting the same destination is stable', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.dashboard.icon).first);
      await tester.pump();
      await tester.tap(
          find.byIcon(NavigationDestinations.dashboard.icon).first);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('sequential navigation through all workspaces completes',
        (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      final ordered = [
        NavigationDestinations.rtl,
        NavigationDestinations.verification,
        NavigationDestinations.coverage,
        NavigationDestinations.diagnostics,
        NavigationDestinations.repair,
        NavigationDestinations.dashboard,
      ];

      for (final dest in ordered) {
        await tester.tap(find.byIcon(dest.icon).first);
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'threw when selecting ${dest.id}');
      }

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigation from rtl to verification', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(find.byIcon(NavigationDestinations.rtl.icon).first);
      await tester.pump();
      expect(find.byType(NlToRtlScreen), findsOneWidget);

      await tester.tap(
          find.byIcon(NavigationDestinations.verification.icon).first);
      await tester.pump();
      expect(find.text('Verification Workspace Coming Soon'), findsOneWidget);
      expect(find.byType(NlToRtlScreen), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchHome — title
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchHome — title', () {
    // On tablet, NavigationRailLabelType.selected renders the selected
    // destination title inside the rail in addition to the AppBar title.
    // Scope text searches to the AppBar to avoid double-match failures.

    Finder inAppBar(String text) => find.descendant(
          of: find.byType(AppBar),
          matching: find.text(text),
        );

    testWidgets('initial AppBar title is Dashboard (mobile)', (tester) async {
      _setSize(tester, 480, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      // Mobile has no rail labels — AppBar title is the only match.
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('title updates to Verification after selection (tablet)',
        (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.verification.icon).first);
      await tester.pump();

      expect(inAppBar('Verification'), findsOneWidget);
    });

    testWidgets('title updates to Coverage after selection (tablet)',
        (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.coverage.icon).first);
      await tester.pump();

      expect(inAppBar('Coverage'), findsOneWidget);
    });

    testWidgets('title resets to Dashboard after navigating back (tablet)',
        (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.coverage.icon).first);
      await tester.pump();

      await tester.tap(
          find.byIcon(NavigationDestinations.dashboard.icon).first);
      await tester.pump();

      expect(inAppBar('Dashboard'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchHome — layout adaptation
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchHome — layout adaptation', () {
    testWidgets('mobile: Scaffold has a Drawer', (tester) async {
      _setSize(tester, 480, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      final scaffold =
          tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<Drawer>());
    });

    testWidgets('tablet: NavigationRail is visible', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('tablet: no Drawer on Scaffold', (tester) async {
      _setSize(tester, 800, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      final scaffold =
          tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull);
    });

    testWidgets('desktop: NavigationRail is extended', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      final rail =
          tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('mobile: body (HomeScreen) is still rendered', (tester) async {
      _setSize(tester, 480, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('desktop: body (HomeScreen) is still rendered', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchHome — mobile drawer navigation
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchHome — mobile drawer navigation', () {
    testWidgets('drawer can be opened programmatically', (tester) async {
      _setSize(tester, 480, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      final state =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('drawer lists all workspace destinations', (tester) async {
      _setSize(tester, 480, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      final state =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      state.openDrawer();
      await tester.pumpAndSettle();

      for (final dest in NavigationDestinations.workspaces) {
        expect(find.text(dest.title), findsAtLeastNWidgets(1),
            reason: '${dest.title} missing from drawer');
      }
    });

    testWidgets('tapping RTL Workspace in drawer shows NlToRtlScreen',
        (tester) async {
      // 560px: still mobile (< 600 breakpoint) but wide enough for
      // NlToRtlScreen's internal Row to avoid layout overflow.
      _setSize(tester, 560, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_app(const WorkbenchHome()));
      await tester.pump();

      final state =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      state.openDrawer();
      await tester.pumpAndSettle();

      // 'RTL Workspace' appears once in the drawer ListTile (DrawerHeader shows
      // the current title 'Dashboard').  Using .last is safe even if the
      // AppBar title were also visible behind the drawer.
      await tester.tap(find.text('RTL Workspace').last);
      await tester.pumpAndSettle();

      expect(find.byType(NlToRtlScreen), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Regression — WorkspaceRegistry untouched
  // ──────────────────────────────────────────────────────────────────────────

  group('Regression — WorkspaceRegistry untouched', () {
    test("'dashboard' → DashboardWorkspace (placeholder, not HomeScreen)", () {
      expect(WorkspaceRegistry.buildWorkspace('dashboard'),
          isA<DashboardWorkspace>());
      expect(WorkspaceRegistry.buildWorkspace('dashboard'),
          isNot(isA<HomeScreen>()));
    });

    test("'rtl' → RTLWorkspace (placeholder, not NlToRtlScreen)", () {
      expect(WorkspaceRegistry.buildWorkspace('rtl'), isA<RTLWorkspace>());
      expect(WorkspaceRegistry.buildWorkspace('rtl'),
          isNot(isA<NlToRtlScreen>()));
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

    testWidgets('WorkspaceHost still resolves to DashboardWorkspace',
        (tester) async {
      await tester.pumpWidget(_app(
          const WorkspaceHost(workspaceId: 'dashboard')));
      await tester.pump();
      expect(find.byType(DashboardWorkspace), findsOneWidget);
    });

    testWidgets('WorkbenchShell with null body still uses WorkspaceHost',
        (tester) async {
      await tester.pumpWidget(_app(WorkbenchShell(
        controller: NavigationController.workspaces(),
      )));
      await tester.pump();
      expect(find.byType(WorkspaceHost), findsOneWidget);
    });
  });
}
