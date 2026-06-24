import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiplens_lite/ui/responsive/responsive.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Sets the test window to [width] × [height] logical pixels (pixelRatio = 1).
void _setSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
}

void _resetSize(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. ResponsiveBreakpoints — getDeviceType ───────────────────────────────
  group('ResponsiveBreakpoints — getDeviceType', () {
    test('width 0 is mobile', () {
      expect(ResponsiveBreakpoints.getDeviceType(0), DeviceType.mobile);
    });

    test('width 300 is mobile', () {
      expect(ResponsiveBreakpoints.getDeviceType(300), DeviceType.mobile);
    });

    test('width 599 is mobile (upper boundary)', () {
      expect(ResponsiveBreakpoints.getDeviceType(599), DeviceType.mobile);
    });

    test('width 600 is tablet (lower boundary)', () {
      expect(ResponsiveBreakpoints.getDeviceType(600), DeviceType.tablet);
    });

    test('width 800 is tablet (mid)', () {
      expect(ResponsiveBreakpoints.getDeviceType(800), DeviceType.tablet);
    });

    test('width 1023 is tablet (upper boundary)', () {
      expect(ResponsiveBreakpoints.getDeviceType(1023), DeviceType.tablet);
    });

    test('width 1024 is desktop (lower boundary)', () {
      expect(ResponsiveBreakpoints.getDeviceType(1024), DeviceType.desktop);
    });

    test('width 1200 is desktop (mid)', () {
      expect(ResponsiveBreakpoints.getDeviceType(1200), DeviceType.desktop);
    });

    test('width 1439 is desktop (upper boundary)', () {
      expect(ResponsiveBreakpoints.getDeviceType(1439), DeviceType.desktop);
    });

    test('width 1440 is largeDesktop (lower boundary)', () {
      expect(ResponsiveBreakpoints.getDeviceType(1440), DeviceType.largeDesktop);
    });

    test('width 2560 is largeDesktop', () {
      expect(ResponsiveBreakpoints.getDeviceType(2560), DeviceType.largeDesktop);
    });
  });

  // ── 2. ResponsiveBreakpoints — boolean helpers ─────────────────────────────
  group('ResponsiveBreakpoints — boolean helpers', () {
    test('isMobile true for 400', () {
      expect(ResponsiveBreakpoints.isMobile(400), isTrue);
    });

    test('isMobile false for 800', () {
      expect(ResponsiveBreakpoints.isMobile(800), isFalse);
    });

    test('isTablet true for 800', () {
      expect(ResponsiveBreakpoints.isTablet(800), isTrue);
    });

    test('isTablet false for 400', () {
      expect(ResponsiveBreakpoints.isTablet(400), isFalse);
    });

    test('isDesktop true for 1200', () {
      expect(ResponsiveBreakpoints.isDesktop(1200), isTrue);
    });

    test('isDesktop false for 2000', () {
      expect(ResponsiveBreakpoints.isDesktop(2000), isFalse);
    });

    test('isLargeDesktop true for 1440', () {
      expect(ResponsiveBreakpoints.isLargeDesktop(1440), isTrue);
    });

    test('isLargeDesktop false for 1000', () {
      expect(ResponsiveBreakpoints.isLargeDesktop(1000), isFalse);
    });
  });

  // ── 3. AdaptiveSpacing — base constants ────────────────────────────────────
  group('AdaptiveSpacing — base constants', () {
    test('xs == 4', () => expect(AdaptiveSpacing.xs, 4.0));
    test('sm == 8', () => expect(AdaptiveSpacing.sm, 8.0));
    test('md == 16', () => expect(AdaptiveSpacing.md, 16.0));
    test('lg == 24', () => expect(AdaptiveSpacing.lg, 24.0));
    test('xl == 32', () => expect(AdaptiveSpacing.xl, 32.0));
    test('xxl == 48', () => expect(AdaptiveSpacing.xxl, 48.0));
  });

  // ── 4. ResponsiveLayout.of — device type mapping ──────────────────────────
  group('ResponsiveLayout.of — device type mapping', () {
    testWidgets('returns mobile for 400 dp', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late DeviceType dt;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          dt = ResponsiveLayout.of(ctx).deviceType;
          return const SizedBox.shrink();
        }),
      ));
      expect(dt, DeviceType.mobile);
    });

    testWidgets('returns tablet for 800 dp', (tester) async {
      _setSize(tester, 800, 600);
      addTearDown(() => _resetSize(tester));

      late DeviceType dt;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          dt = ResponsiveLayout.of(ctx).deviceType;
          return const SizedBox.shrink();
        }),
      ));
      expect(dt, DeviceType.tablet);
    });

    testWidgets('returns desktop for 1200 dp', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));

      late DeviceType dt;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          dt = ResponsiveLayout.of(ctx).deviceType;
          return const SizedBox.shrink();
        }),
      ));
      expect(dt, DeviceType.desktop);
    });

    testWidgets('returns largeDesktop for 1600 dp', (tester) async {
      _setSize(tester, 1600, 900);
      addTearDown(() => _resetSize(tester));

      late DeviceType dt;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          dt = ResponsiveLayout.of(ctx).deviceType;
          return const SizedBox.shrink();
        }),
      ));
      expect(dt, DeviceType.largeDesktop);
    });
  });

  // ── 5. ResponsiveLayout — boolean getters ─────────────────────────────────
  group('ResponsiveLayout — boolean getters', () {
    testWidgets('isMobile true on 400 dp', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = ResponsiveLayout.of(ctx).isMobile;
          return const SizedBox.shrink();
        }),
      ));
      expect(result, isTrue);
    });

    testWidgets('isTablet true on 800 dp', (tester) async {
      _setSize(tester, 800, 600);
      addTearDown(() => _resetSize(tester));

      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = ResponsiveLayout.of(ctx).isTablet;
          return const SizedBox.shrink();
        }),
      ));
      expect(result, isTrue);
    });

    testWidgets('isDesktop true on 1200 dp', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));

      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = ResponsiveLayout.of(ctx).isDesktop;
          return const SizedBox.shrink();
        }),
      ));
      expect(result, isTrue);
    });

    testWidgets('isLargeDesktop true on 1600 dp', (tester) async {
      _setSize(tester, 1600, 900);
      addTearDown(() => _resetSize(tester));

      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = ResponsiveLayout.of(ctx).isLargeDesktop;
          return const SizedBox.shrink();
        }),
      ));
      expect(result, isTrue);
    });
  });

  // ── 6. ResponsiveLayout.value<T> selection ────────────────────────────────
  group('ResponsiveLayout.value<T> selection', () {
    Future<String> pump(WidgetTester tester) async {
      late String picked;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          picked = ResponsiveLayout.of(ctx).value<String>(
            mobile:       'mobile',
            tablet:       'tablet',
            desktop:      'desktop',
            largeDesktop: 'largeDesktop',
          );
          return const SizedBox.shrink();
        }),
      ));
      return picked;
    }

    testWidgets('selects mobile value on 400 dp', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));
      expect(await pump(tester), 'mobile');
    });

    testWidgets('selects tablet value on 800 dp', (tester) async {
      _setSize(tester, 800, 600);
      addTearDown(() => _resetSize(tester));
      expect(await pump(tester), 'tablet');
    });

    testWidgets('selects desktop value on 1200 dp', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));
      expect(await pump(tester), 'desktop');
    });

    testWidgets('selects largeDesktop value on 1600 dp', (tester) async {
      _setSize(tester, 1600, 900);
      addTearDown(() => _resetSize(tester));
      expect(await pump(tester), 'largeDesktop');
    });

    testWidgets('largeDesktop falls back to desktop when omitted', (tester) async {
      _setSize(tester, 1600, 900);
      addTearDown(() => _resetSize(tester));

      late String picked;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          picked = ResponsiveLayout.of(ctx).value<String>(
            mobile:  'mobile',
            tablet:  'tablet',
            desktop: 'desktop',
          );
          return const SizedBox.shrink();
        }),
      ));
      expect(picked, 'desktop');
    });
  });

  // ── 7. ResponsiveLayout — percentage helpers ───────────────────────────────
  group('ResponsiveLayout — percentage helpers', () {
    testWidgets('widthPercent(50) returns half screen width', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late double result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = ResponsiveLayout.of(ctx).widthPercent(50);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, closeTo(200.0, 0.5));
    });

    testWidgets('heightPercent(25) returns quarter screen height', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late double result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = ResponsiveLayout.of(ctx).heightPercent(25);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, closeTo(200.0, 0.5));
    });
  });

  // ── 8. ResponsiveBuilder — layout selection ────────────────────────────────
  group('ResponsiveBuilder — layout selection', () {
    Widget buildResponsive({WidgetBuilder? largeDesktop}) => MaterialApp(
          home: ResponsiveBuilder(
            mobile:       (_) => const Text('mobile-layout'),
            tablet:       (_) => const Text('tablet-layout'),
            desktop:      (_) => const Text('desktop-layout'),
            largeDesktop: largeDesktop,
          ),
        );

    testWidgets('shows mobile layout on 400 dp', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));
      await tester.pumpWidget(buildResponsive());
      expect(find.text('mobile-layout'),  findsOneWidget);
      expect(find.text('tablet-layout'),  findsNothing);
      expect(find.text('desktop-layout'), findsNothing);
    });

    testWidgets('shows tablet layout on 800 dp', (tester) async {
      _setSize(tester, 800, 600);
      addTearDown(() => _resetSize(tester));
      await tester.pumpWidget(buildResponsive());
      expect(find.text('tablet-layout'),  findsOneWidget);
      expect(find.text('mobile-layout'),  findsNothing);
      expect(find.text('desktop-layout'), findsNothing);
    });

    testWidgets('shows desktop layout on 1200 dp', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));
      await tester.pumpWidget(buildResponsive());
      expect(find.text('desktop-layout'), findsOneWidget);
      expect(find.text('mobile-layout'),  findsNothing);
      expect(find.text('tablet-layout'),  findsNothing);
    });

    testWidgets('shows largeDesktop layout on 1600 dp', (tester) async {
      _setSize(tester, 1600, 900);
      addTearDown(() => _resetSize(tester));
      await tester.pumpWidget(
        buildResponsive(largeDesktop: (_) => const Text('large-layout')),
      );
      expect(find.text('large-layout'),   findsOneWidget);
      expect(find.text('desktop-layout'), findsNothing);
    });

    testWidgets('falls back to desktop when largeDesktop not provided', (tester) async {
      _setSize(tester, 1600, 900);
      addTearDown(() => _resetSize(tester));
      await tester.pumpWidget(buildResponsive());
      expect(find.text('desktop-layout'), findsOneWidget);
    });
  });

  // ── 9. AdaptiveSpacing — adaptive helpers ─────────────────────────────────
  group('AdaptiveSpacing — adaptive helpers', () {
    testWidgets('pagePadding is all(16) on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late EdgeInsets result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.pagePadding(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, const EdgeInsets.all(AdaptiveSpacing.md));
    });

    testWidgets('pagePadding is all(24) on tablet', (tester) async {
      _setSize(tester, 800, 600);
      addTearDown(() => _resetSize(tester));

      late EdgeInsets result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.pagePadding(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, const EdgeInsets.all(AdaptiveSpacing.lg));
    });

    testWidgets('pagePadding is all(32) on desktop', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));

      late EdgeInsets result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.pagePadding(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, const EdgeInsets.all(AdaptiveSpacing.xl));
    });

    testWidgets('sectionSpacing is lg (24) on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late double result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.sectionSpacing(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, AdaptiveSpacing.lg);
    });

    testWidgets('sectionSpacing is xxl (48) on desktop', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));

      late double result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.sectionSpacing(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, AdaptiveSpacing.xxl);
    });

    testWidgets('cardPadding is all(16) on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late EdgeInsets result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.cardPadding(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, const EdgeInsets.all(AdaptiveSpacing.md));
    });

    testWidgets('buttonHeight is 44 on mobile', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      late double result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.buttonHeight(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, 44.0);
    });

    testWidgets('buttonHeight is 52 on desktop', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));

      late double result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          result = AdaptiveSpacing.buttonHeight(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(result, 52.0);
    });
  });

  // ── 10. AdaptiveScaffold — rendering ──────────────────────────────────────
  group('AdaptiveScaffold — rendering', () {
    const destinations = [
      AdaptiveDestination(icon: Icon(Icons.home),     label: 'Home'),
      AdaptiveDestination(icon: Icon(Icons.settings), label: 'Settings'),
    ];

    testWidgets('renders body without destinations', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(const MaterialApp(
        home: AdaptiveScaffold(body: Text('body-content')),
      ));
      expect(find.text('body-content'),   findsOneWidget);
      expect(find.byType(Drawer),         findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('renders title in AppBar', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(const MaterialApp(
        home: AdaptiveScaffold(title: 'My App', body: SizedBox.shrink()),
      ));
      expect(find.text('My App'),       findsOneWidget);
      expect(find.byType(AppBar),       findsOneWidget);
    });

    testWidgets('no AppBar when title and actions are both null', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(const MaterialApp(
        home: AdaptiveScaffold(body: SizedBox.shrink()),
      ));
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('floatingActionButton is rendered', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(MaterialApp(
        home: AdaptiveScaffold(
          body: const SizedBox.shrink(),
          floatingActionButton:
              FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
        ),
      ));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows Drawer on mobile when destinations provided', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(MaterialApp(
        home: AdaptiveScaffold(
          title:        'Nav Test',
          body:         const SizedBox.shrink(),
          destinations: destinations,
        ),
      ));
      // On mobile the Scaffold is configured with a drawer and no NavigationRail.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<Drawer>(), reason: 'Mobile should use Drawer');
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('shows NavigationRail on tablet when destinations provided',
        (tester) async {
      _setSize(tester, 800, 600);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(MaterialApp(
        home: AdaptiveScaffold(
          title:        'Nav Test',
          body:         const SizedBox.shrink(),
          destinations: destinations,
        ),
      ));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(Drawer),         findsNothing);
    });

    testWidgets('shows extended NavigationRail on desktop', (tester) async {
      _setSize(tester, 1200, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(MaterialApp(
        home: AdaptiveScaffold(
          title:        'Nav Test',
          body:         const SizedBox.shrink(),
          destinations: destinations,
        ),
      ));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(Drawer),         findsNothing);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('does not crash with empty destinations list', (tester) async {
      _setSize(tester, 400, 800);
      addTearDown(() => _resetSize(tester));

      await tester.pumpWidget(const MaterialApp(
        home: AdaptiveScaffold(
          body:         SizedBox.shrink(),
          destinations: [],
        ),
      ));
      expect(find.byType(Drawer),         findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });
  });
}
