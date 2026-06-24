import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/ui/navigation/navigation.dart';
import 'package:chiplens_lite/ui/theme/app_icons.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

void _setSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
}

void _resetSize(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Widget _testApp(Widget home) => MaterialApp(home: home);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // NavigationItem
  // ──────────────────────────────────────────────────────────────────────────

  group('NavigationItem —', () {
    const item = NavigationItem(
      id:    'test',
      title: 'Test',
      icon:  Icons.home,
    );

    test('id is stored', () => expect(item.id, 'test'));
    test('title is stored', () => expect(item.title, 'Test'));
    test('icon is stored', () => expect(item.icon, Icons.home));

    test('tooltip defaults to title when omitted', () {
      expect(item.tooltip, 'Test');
    });

    test('explicit tooltip overrides title default', () {
      const i = NavigationItem(
          id: 'x', title: 'X', icon: Icons.home, tooltip: 'Custom tip');
      expect(i.tooltip, 'Custom tip');
    });

    test('enabled defaults to true', () => expect(item.enabled, isTrue));
    test('badgeCount defaults to null', () => expect(item.badgeCount, isNull));
    test('routeName defaults to null', () => expect(item.routeName, isNull));

    test('disabled item created correctly', () {
      const d = NavigationItem(
          id: 'x', title: 'X', icon: Icons.home, enabled: false);
      expect(d.enabled, isFalse);
    });

    test('badgeCount stored correctly', () {
      const b = NavigationItem(
          id: 'x', title: 'X', icon: Icons.home, badgeCount: 5);
      expect(b.badgeCount, 5);
    });

    test('copyWith changes id', () {
      final copy = item.copyWith(id: 'new');
      expect(copy.id, 'new');
    });

    test('copyWith changes enabled to false', () {
      final copy = item.copyWith(enabled: false);
      expect(copy.enabled, isFalse);
    });

    test('copyWith preserves other fields', () {
      final copy = item.copyWith(id: 'new');
      expect(copy.title, item.title);
      expect(copy.icon, item.icon);
      expect(copy.tooltip, item.tooltip);
      expect(copy.enabled, item.enabled);
    });

    test('identical content → equal', () {
      const other = NavigationItem(
          id: 'test', title: 'Test', icon: Icons.home);
      expect(item, other);
    });

    test('different id → not equal', () {
      const other = NavigationItem(
          id: 'other', title: 'Test', icon: Icons.home);
      expect(item, isNot(other));
    });

    test('different enabled → not equal', () {
      const other = NavigationItem(
          id: 'test', title: 'Test', icon: Icons.home, enabled: false);
      expect(item, isNot(other));
    });

    test('hashCode consistent for same values', () {
      const other = NavigationItem(
          id: 'test', title: 'Test', icon: Icons.home);
      expect(item.hashCode, other.hashCode);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // NavigationDestinations
  // ──────────────────────────────────────────────────────────────────────────

  group('NavigationDestinations —', () {
    test('dashboard.id', () {
      expect(NavigationDestinations.dashboard.id, 'dashboard');
    });
    test('dashboard.title', () {
      expect(NavigationDestinations.dashboard.title, 'Dashboard');
    });
    test('dashboard.icon is AppIcons.dashboard', () {
      expect(NavigationDestinations.dashboard.icon, AppIcons.dashboard);
    });
    test('rtl.id', () {
      expect(NavigationDestinations.rtl.id, 'rtl');
    });
    test('rtl.title', () {
      expect(NavigationDestinations.rtl.title, 'RTL Workspace');
    });
    test('verification.id', () {
      expect(NavigationDestinations.verification.id, 'verification');
    });
    test('coverage.id', () {
      expect(NavigationDestinations.coverage.id, 'coverage');
    });
    test('diagnostics.id', () {
      expect(NavigationDestinations.diagnostics.id, 'diagnostics');
    });
    test('repair.id', () {
      expect(NavigationDestinations.repair.id, 'repair');
    });
    test('settings.id', () {
      expect(NavigationDestinations.settings.id, 'settings');
    });
    test('help.id', () {
      expect(NavigationDestinations.help.id, 'help');
    });
    test('all has 8 destinations', () {
      expect(NavigationDestinations.all.length, 8);
    });
    test('workspaces has 6 destinations', () {
      expect(NavigationDestinations.workspaces.length, 6);
    });
    test('system has 2 destinations', () {
      expect(NavigationDestinations.system.length, 2);
    });
    test('workspaces contains dashboard', () {
      expect(NavigationDestinations.workspaces,
          contains(NavigationDestinations.dashboard));
    });
    test('workspaces does not contain settings', () {
      expect(NavigationDestinations.workspaces,
          isNot(contains(NavigationDestinations.settings)));
    });
    test('workspaces does not contain help', () {
      expect(NavigationDestinations.workspaces,
          isNot(contains(NavigationDestinations.help)));
    });
    test('all destinations are enabled', () {
      expect(NavigationDestinations.all.every((d) => d.enabled), isTrue);
    });
    test('all destination IDs are unique', () {
      final ids = NavigationDestinations.all.map((d) => d.id).toSet();
      expect(ids.length, NavigationDestinations.all.length);
    });
    test('all destinations have non-empty titles', () {
      expect(NavigationDestinations.all.every((d) => d.title.isNotEmpty),
          isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // NavigationController
  // ──────────────────────────────────────────────────────────────────────────

  group('NavigationController —', () {
    final all = NavigationDestinations.all;

    test('default selectedIndex is 0', () {
      final ctrl = NavigationController(destinations: all);
      expect(ctrl.selectedIndex, 0);
    });

    test('selectedDestination returns dashboard initially', () {
      final ctrl = NavigationController(destinations: all);
      expect(ctrl.selectedDestination, NavigationDestinations.dashboard);
    });

    test('selectDestination(2) changes selectedIndex', () {
      final ctrl = NavigationController(destinations: all);
      final next = ctrl.selectDestination(2);
      expect(next.selectedIndex, 2);
    });

    test('selectDestination with same index returns identical instance', () {
      final ctrl = NavigationController(destinations: all);
      final same = ctrl.selectDestination(0);
      expect(identical(ctrl, same), isTrue);
    });

    test('selectById changes to matching destination', () {
      final ctrl = NavigationController(destinations: all);
      final next = ctrl.selectById('verification');
      expect(next.selectedDestination.id, 'verification');
    });

    test('selectById with unknown id returns same instance', () {
      final ctrl = NavigationController(destinations: all);
      final same = ctrl.selectById('nonexistent');
      expect(identical(ctrl, same), isTrue);
    });

    test('selectById dashboard → index 0', () {
      final ctrl = NavigationController(destinations: all, selectedIndex: 3);
      final next = ctrl.selectById('dashboard');
      expect(next.selectedIndex, 0);
    });

    test('selectById settings → correct index', () {
      final ctrl = NavigationController(destinations: all);
      final next = ctrl.selectById('settings');
      expect(next.selectedDestination.id, 'settings');
    });

    test('selectDestination does not mutate original', () {
      final ctrl = NavigationController(destinations: all);
      ctrl.selectDestination(3);
      expect(ctrl.selectedIndex, 0); // original unchanged
    });

    test('chained selections accumulate correctly', () {
      final ctrl = NavigationController(destinations: all)
          .selectDestination(1)
          .selectDestination(4);
      expect(ctrl.selectedIndex, 4);
    });

    test('equality: same state → equal', () {
      final a = NavigationController(destinations: all, selectedIndex: 2);
      final b = NavigationController(destinations: all, selectedIndex: 2);
      expect(a, b);
    });

    test('equality: different index → not equal', () {
      final a = NavigationController(destinations: all, selectedIndex: 0);
      final b = NavigationController(destinations: all, selectedIndex: 1);
      expect(a, isNot(b));
    });

    test('equality: different destinations → not equal', () {
      final a = NavigationController(destinations: NavigationDestinations.workspaces);
      final b = NavigationController(destinations: NavigationDestinations.all);
      expect(a, isNot(b));
    });

    test('hashCode consistent for same state', () {
      final a = NavigationController(destinations: all, selectedIndex: 2);
      final b = NavigationController(destinations: all, selectedIndex: 2);
      expect(a.hashCode, b.hashCode);
    });

    test('destinations list preserved in order', () {
      final ctrl = NavigationController(destinations: all);
      expect(ctrl.destinations, all);
    });

    test('custom destinations list is supported', () {
      const custom = [
        NavigationItem(id: 'a', title: 'A', icon: Icons.home),
        NavigationItem(id: 'b', title: 'B', icon: Icons.star),
      ];
      final ctrl = NavigationController(destinations: custom, selectedIndex: 1);
      expect(ctrl.selectedDestination.id, 'b');
    });

    test('hasValidSelection is true for valid state', () {
      final ctrl = NavigationController(destinations: all);
      expect(ctrl.hasValidSelection, isTrue);
    });

    test('hasValidSelection is false for empty destinations', () {
      final ctrl = NavigationController(destinations: const []);
      expect(ctrl.hasValidSelection, isFalse);
    });

    test('factory workspaces initialises with workspace destinations', () {
      final ctrl = NavigationController.workspaces();
      expect(ctrl.destinations, NavigationDestinations.workspaces);
    });

    test('factory all initialises with all destinations', () {
      final ctrl = NavigationController.all();
      expect(ctrl.destinations.length, 8);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AdaptiveNavigation — widget tests
  // ──────────────────────────────────────────────────────────────────────────

  group('AdaptiveNavigation — mobile', () {
    testWidgets('Scaffold has Drawer on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const Text('body'),
        title: 'Workbench',
      )));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<Drawer>());
    });

    testWidgets('NavigationRail absent on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
        title: 'Workbench',
      )));
      await tester.pump();

      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('body is rendered on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const Text('mobile-body'),
        title: 'Workbench',
      )));
      await tester.pump();

      expect(find.text('mobile-body'), findsOneWidget);
    });

    testWidgets('title appears in AppBar on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
        title: 'My Title',
      )));
      await tester.pump();

      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('drawer shows destinations when opened', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
        title: 'Workbench',
      )));
      await tester.pump();

      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('RTL Workspace'), findsOneWidget);
      expect(find.text('Verification'), findsOneWidget);
    });

    testWidgets('tap drawer item triggers onDestinationSelected', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      int? selected;
      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        onDestinationSelected: (i) => selected = i,
        body: const SizedBox(),
        title: 'Workbench',
      )));
      await tester.pump();

      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('RTL Workspace'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });
  });

  group('AdaptiveNavigation — tablet', () {
    testWidgets('NavigationRail present on tablet', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
        title: 'Workbench',
      )));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('Scaffold has no Drawer on tablet', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
        title: 'Workbench',
      )));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull);
    });

    testWidgets('rail is compact (extended=false) on tablet', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('body is rendered on tablet', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const Text('tablet-body'),
      )));
      await tester.pump();

      expect(find.text('tablet-body'), findsOneWidget);
    });

    testWidgets('tap rail item triggers callback on tablet', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      int? selected;
      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        onDestinationSelected: (i) => selected = i,
        body: const SizedBox(),
      )));
      await tester.pump();

      // Tap the RTL Workspace icon in the rail (index 1)
      await tester.tap(
        find.byIcon(NavigationDestinations.rtl.icon).first,
      );
      await tester.pump();

      expect(selected, 1);
    });

    testWidgets('selectedIndex is reflected in rail', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(selectedIndex: 2),
        body: const SizedBox(),
      )));
      await tester.pump();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
    });
  });

  group('AdaptiveNavigation — desktop', () {
    testWidgets('NavigationRail present on desktop', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('rail is extended on desktop', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('Scaffold has no Drawer on desktop', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull);
    });

    testWidgets('body is rendered on desktop', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const Text('desktop-body'),
      )));
      await tester.pump();

      expect(find.text('desktop-body'), findsOneWidget);
    });

    testWidgets('extended rail shows destination labels', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  group('AdaptiveNavigation — misc', () {
    testWidgets('no destinations → no Drawer and no Rail', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController(destinations: const []),
        body: const Text('empty'),
        title: 'Empty',
      )));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('no title and no actions → no AppBar on desktop', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(AdaptiveNavigation(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      expect(find.byType(AppBar), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WorkbenchShell — widget tests
  // ──────────────────────────────────────────────────────────────────────────

  group('WorkbenchShell —', () {
    testWidgets('title defaults to selected destination title', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
      )));
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('explicit title overrides selected destination', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
        title: 'Custom Title',
      )));
      await tester.pump();

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('body is rendered on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const Text('workspace'),
      )));
      await tester.pump();

      expect(find.text('workspace'), findsOneWidget);
    });

    testWidgets('body is rendered on tablet', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const Text('workspace'),
      )));
      await tester.pump();

      expect(find.text('workspace'), findsOneWidget);
    });

    testWidgets('body is rendered on desktop', (tester) async {
      _setSize(tester, 1280, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const Text('workspace'),
      )));
      await tester.pump();

      expect(find.text('workspace'), findsOneWidget);
    });

    testWidgets('onDestinationSelected fires on tablet tap', (tester) async {
      _setSize(tester, 768, 1024);
      addTearDown(() => _resetSize(tester));

      int? selected;
      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(),
        onDestinationSelected: (i) => selected = i,
        body: const SizedBox(),
      )));
      await tester.pump();

      await tester.tap(
        find.byIcon(NavigationDestinations.coverage.icon).first,
      );
      await tester.pump();

      expect(selected, 3); // coverage is index 3 in workspaces
    });

    testWidgets('actions appear in AppBar', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(),
        body: const SizedBox(),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: null),
        ],
      )));
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('verification title shown when index=2', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.workspaces(selectedIndex: 2),
        body: const SizedBox(),
      )));
      await tester.pump();

      expect(find.text('Verification'), findsOneWidget);
    });

    testWidgets('shell renders without error on large desktop', (tester) async {
      _setSize(tester, 1600, 900);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(_testApp(WorkbenchShell(
        controller: NavigationController.all(),
        body: const Text('ld-body'),
      )));
      await tester.pump();

      expect(find.text('ld-body'), findsOneWidget);
    });
  });
}
