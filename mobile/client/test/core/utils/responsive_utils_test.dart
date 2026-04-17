import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/utils/responsive_utils.dart';

/// Build a widget that captures a [ResponsiveUtils] instance.
Widget _buildWithSize({
  required Size size,
  required void Function(ResponsiveUtils ru) onCapture,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Builder(
        builder: (context) {
          onCapture(ResponsiveUtils(context));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  group('Breakpoints constants', () {
    test('mobile = 480', () => expect(Breakpoints.mobile, 480));
    test('tablet = 768', () => expect(Breakpoints.tablet, 768));
    test('desktop = 1024', () => expect(Breakpoints.desktop, 1024));
    test('desktopLarge = 1440', () => expect(Breakpoints.desktopLarge, 1440));
  });

  group('ScreenType enum', () {
    test('values include mobile, tablet, desktop, desktopLarge', () {
      expect(
        ScreenType.values,
        containsAll([
          ScreenType.mobile,
          ScreenType.tablet,
          ScreenType.desktop,
          ScreenType.desktopLarge,
        ]),
      );
    });
  });

  group('ScreenOrientation enum', () {
    test('values include portrait and landscape', () {
      expect(
        ScreenOrientation.values,
        containsAll([ScreenOrientation.portrait, ScreenOrientation.landscape]),
      );
    });
  });

  group('ResponsiveUtils — mobile (375×812)', () {
    setUp(() async {});

    testWidgets('width and height match MediaQuery size', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.width, 375.0);
      expect(captured.height, 812.0);
    });

    testWidgets('screenType is mobile for width < 480', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.screenType, ScreenType.mobile);
    });

    testWidgets('isMobile true, isTablet false, isDesktop false', (
      tester,
    ) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.isMobile, isTrue);
      expect(captured.isTablet, isFalse);
      expect(captured.isDesktop, isFalse);
    });

    testWidgets('isPortrait true for 375×812', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.isPortrait, isTrue);
      expect(captured.isLandscape, isFalse);
    });

    testWidgets('orientation is landscape for 812×375', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(812, 375),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.isLandscape, isTrue);
      expect(captured.isPortrait, isFalse);
    });

    testWidgets('wp() returns percentage of width', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(400, 800),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.wp(50), closeTo(200.0, 0.01));
      expect(captured.wp(100), closeTo(400.0, 0.01));
    });

    testWidgets('hp() returns percentage of height', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(400, 800),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.hp(25), closeTo(200.0, 0.01));
    });

    testWidgets('sw() scales relative to base 375 width', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      // base 375 → factor 1.0 → sw(100) = 100
      expect(captured.sw(100), closeTo(100.0, 0.01));
    });

    testWidgets('sh() scales relative to base 812 height', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      // base 812 → factor 1.0 → sh(50) = 50
      expect(captured.sh(50), closeTo(50.0, 0.01));
    });

    testWidgets('sp() clamps font scale between 0.8 and 1.3', (tester) async {
      // Very narrow screen → factor clamped to 0.8
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(200, 812),
          onCapture: (r) => captured = r,
        ),
      );
      // factor = 200/375 ≈ 0.533, clamped to 0.8 → sp(16) ≈ 12.8
      final sp = captured.sp(16);
      expect(sp, closeTo(12.8, 0.1));
    });

    testWidgets('sp() clamps at 1.3 for very wide screen', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(700, 812),
          onCapture: (r) => captured = r,
        ),
      );
      // factor = 700/375 ≈ 1.867, clamped to 1.3 → sp(16) ≈ 20.8
      final sp = captured.sp(16);
      expect(sp, closeTo(20.8, 0.1));
    });

    testWidgets('horizontalPadding is 16 on mobile', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.horizontalPadding, 16.0);
    });

    testWidgets('verticalPadding is 16 on mobile', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.verticalPadding, 16.0);
    });

    testWidgets('maxContentWidth equals full width on mobile', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.maxContentWidth, 375.0);
    });

    testWidgets('gridColumns is 2 (portrait) on mobile', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.gridColumns, 2);
    });

    testWidgets('gridColumns is 3 (landscape) on mobile', (tester) async {
      late ResponsiveUtils captured;
      // 667 < 768 (tablet breakpoint) = mobile; 667 > 375 = landscape
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(667, 375),
          onCapture: (r) => captured = r,
        ),
      );
      // landscape on mobile → 3 columns
      expect(captured.gridColumns, 3);
    });

    testWidgets('gridSpacing is 12 on mobile', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.gridSpacing, 12.0);
    });

    testWidgets('iconSize() returns base size on mobile', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.iconSize(24), 24.0);
      expect(captured.iconSize(), 24.0); // default
    });

    testWidgets('borderRadius() returns base on mobile', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.borderRadius(12), 12.0);
      expect(captured.borderRadius(), 12.0); // default
    });

    testWidgets('value() returns mobile value', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      final v = captured.value<String>(
        mobile: 'mobile',
        tablet: 'tablet',
        desktop: 'desktop',
      );
      expect(v, 'mobile');
    });

    testWidgets('aspectRatio is width/height', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.aspectRatio, closeTo(375.0 / 812.0, 0.001));
    });
  });

  group('ResponsiveUtils — tablet (800×1024)', () {
    testWidgets('screenType is tablet', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.screenType, ScreenType.tablet);
    });

    testWidgets('isTablet true', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.isTablet, isTrue);
      expect(captured.isMobile, isFalse);
    });

    testWidgets('horizontalPadding is 24 on tablet', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.horizontalPadding, 24.0);
    });

    testWidgets('maxContentWidth is 600 on tablet', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.maxContentWidth, 600.0);
    });

    testWidgets('gridColumns is 3 (portrait) on tablet', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.gridColumns, 3);
    });

    testWidgets('gridColumns is 4 (landscape) on tablet', (tester) async {
      late ResponsiveUtils captured;
      // 900 >= 768 AND < 1024 = tablet; 900 > 600 = landscape
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(900, 600),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.gridColumns, 4);
    });

    testWidgets('iconSize() is 1.2x on tablet', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.iconSize(20), closeTo(24.0, 0.001));
    });

    testWidgets('value() returns tablet value', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      final v = captured.value<String>(
        mobile: 'mobile',
        tablet: 'tablet',
        desktop: 'desktop',
      );
      expect(v, 'tablet');
    });

    testWidgets('value() falls back to mobile if tablet not specified', (
      tester,
    ) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(800, 1024),
          onCapture: (r) => captured = r,
        ),
      );
      final v = captured.value<int>(mobile: 1);
      expect(v, 1);
    });
  });

  group('ResponsiveUtils — desktop (1200×900)', () {
    testWidgets('screenType is desktop', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1200, 900),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.screenType, ScreenType.desktop);
    });

    testWidgets('isDesktop true', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1200, 900),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.isDesktop, isTrue);
    });

    testWidgets('horizontalPadding is 32 on desktop', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1200, 900),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.horizontalPadding, 32.0);
    });

    testWidgets('maxContentWidth is 800 on desktop', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1200, 900),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.maxContentWidth, 800.0);
    });

    testWidgets('gridColumns is 4 (portrait) on desktop', (tester) async {
      late ResponsiveUtils captured;
      // 1200 >= 1024 AND < 1440 = desktop; 1200 < 1500 = portrait
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1200, 1500),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.gridColumns, 4);
    });

    testWidgets('gridColumns is 6 (landscape) on desktop', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1440, 900),
          onCapture: (r) => captured = r,
        ),
      );
      // 1440 >= desktopLarge, so it's desktopLarge but isDesktop is still true
      expect(captured.gridColumns, 6);
    });

    testWidgets('value() returns desktop value', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1200, 900),
          onCapture: (r) => captured = r,
        ),
      );
      final v = captured.value<String>(
        mobile: 'mobile',
        tablet: 'tablet',
        desktop: 'desktop',
      );
      expect(v, 'desktop');
    });

    testWidgets('screenType desktopLarge for width >= 1440', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(1920, 1080),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.screenType, ScreenType.desktopLarge);
      expect(captured.isDesktop, isTrue);
    });
  });

  group('ResponsiveExtension', () {
    testWidgets('context.isMobile works via extension', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedContext.isMobile, isTrue);
      expect(capturedContext.isTablet, isFalse);
      expect(capturedContext.isDesktop, isFalse);
    });

    testWidgets('context.wp() and context.hp() work', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedContext.wp(50), closeTo(200.0, 0.01));
      expect(capturedContext.hp(25), closeTo(200.0, 0.01));
    });

    testWidgets('context.isPortrait and context.isLandscape work', (
      tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedContext.isPortrait, isTrue);
      expect(capturedContext.isLandscape, isFalse);
    });

    testWidgets('context.sw() and context.sh() work', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedContext.sw(375), closeTo(375.0, 0.01));
      expect(capturedContext.sh(812), closeTo(812.0, 0.01));
    });

    testWidgets('context.sp() works', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedContext.sp(16), closeTo(16.0, 0.5));
    });
  });

  group('ResponsiveBuilder widget', () {
    testWidgets('renders via builder function', (tester) async {
      bool builderCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: ResponsiveBuilder(
              builder: (context, responsive) {
                builderCalled = true;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(builderCalled, isTrue);
    });

    testWidgets('passes correct ResponsiveUtils to builder', (tester) async {
      ResponsiveUtils? capturedRu;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(600, 800)),
            child: ResponsiveBuilder(
              builder: (context, responsive) {
                capturedRu = responsive;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedRu, isNotNull);
      expect(capturedRu!.width, 600.0);
    });
  });

  group('ResponsiveWidget widget', () {
    testWidgets('shows mobile widget on small screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: const ResponsiveWidget(
              mobile: Text('mobile'),
              tablet: Text('tablet'),
              desktop: Text('desktop'),
            ),
          ),
        ),
      );
      expect(find.text('mobile'), findsOneWidget);
      expect(find.text('tablet'), findsNothing);
    });

    testWidgets('shows tablet widget on tablet screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1024)),
            child: const ResponsiveWidget(
              mobile: Text('mobile'),
              tablet: Text('tablet'),
              desktop: Text('desktop'),
            ),
          ),
        ),
      );
      expect(find.text('tablet'), findsOneWidget);
    });

    testWidgets('falls back to mobile if tablet not set on tablet screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1024)),
            child: const ResponsiveWidget(mobile: Text('mobile-only')),
          ),
        ),
      );
      expect(find.text('mobile-only'), findsOneWidget);
    });

    testWidgets('shows desktop widget on desktop screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 900)),
            child: const ResponsiveWidget(
              mobile: Text('mobile'),
              tablet: Text('tablet'),
              desktop: Text('desktop'),
            ),
          ),
        ),
      );
      expect(find.text('desktop'), findsOneWidget);
    });
  });

  group('ResponsiveUtils — simple getters', () {
    testWidgets('pixelRatio returns device pixel ratio', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.pixelRatio, isA<double>());
    });

    testWidgets('textScale returns a double', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.textScale, isA<double>());
    });

    testWidgets('safePadding returns EdgeInsets', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.safePadding, isA<EdgeInsets>());
    });

    testWidgets('viewInsets returns EdgeInsets', (tester) async {
      late ResponsiveUtils captured;
      await tester.pumpWidget(
        _buildWithSize(
          size: const Size(375, 812),
          onCapture: (r) => captured = r,
        ),
      );
      expect(captured.viewInsets, isA<EdgeInsets>());
    });
  });

  group('ResponsiveContainer widget', () {
    testWidgets('renders child in centered container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveContainer(child: Text('test child')),
          ),
        ),
      );
      expect(find.text('test child'), findsOneWidget);
    });

    testWidgets('uses provided maxWidth', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: Scaffold(
              body: ResponsiveContainer(maxWidth: 300, child: Text('bounded')),
            ),
          ),
        ),
      );
      expect(find.text('bounded'), findsOneWidget);
      final box = tester.renderObject<RenderBox>(
        find
            .ancestor(
              of: find.byType(ConstrainedBox),
              matching: find.byType(Center),
            )
            .first,
      );
      expect(box, isNotNull);
    });

    testWidgets('uses backgroundColor when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveContainer(
              backgroundColor: Color(0xFFFF0000),
              child: Text('colored'),
            ),
          ),
        ),
      );
      expect(find.text('colored'), findsOneWidget);
    });

    testWidgets('uses custom padding when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveContainer(
              padding: EdgeInsets.all(8),
              child: Text('padded'),
            ),
          ),
        ),
      );
      expect(find.text('padded'), findsOneWidget);
    });
  });

  group('ResponsiveScaffold widget', () {
    testWidgets('renders body with SafeArea and ConstrainedBox', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveScaffold(body: Text('scaffold body')),
          ),
        ),
      );
      expect(find.text('scaffold body'), findsOneWidget);
    });

    testWidgets('renders appBar when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: ResponsiveScaffold(
              appBar: AppBar(title: const Text('App Title')),
              body: const Text('body'),
            ),
          ),
        ),
      );
      expect(find.text('App Title'), findsOneWidget);
    });

    testWidgets('renders floatingActionButton when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveScaffold(
              body: SizedBox.shrink(),
              floatingActionButton: FloatingActionButton(
                onPressed: null,
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('uses custom maxContentWidth', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveScaffold(
              maxContentWidth: 320,
              body: Text('constrained'),
            ),
          ),
        ),
      );
      expect(find.text('constrained'), findsOneWidget);
    });
  });

  group('ResponsiveGrid widget', () {
    testWidgets('renders list of children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(375, 812)),
              child: ResponsiveGrid(
                children: const [
                  Text('item 1'),
                  Text('item 2'),
                  Text('item 3'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('item 1'), findsOneWidget);
      expect(find.text('item 2'), findsOneWidget);
      expect(find.text('item 3'), findsOneWidget);
    });

    testWidgets('uses provided columns instead of responsive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(375, 812)),
              child: ResponsiveGrid(
                columns: 3,
                children: const [Text('a'), Text('b')],
              ),
            ),
          ),
        ),
      );
      expect(find.text('a'), findsOneWidget);
    });

    testWidgets('uses provided spacing and runSpacing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(375, 812)),
              child: ResponsiveGrid(
                spacing: 8,
                runSpacing: 4,
                children: const [Text('x')],
              ),
            ),
          ),
        ),
      );
      expect(find.text('x'), findsOneWidget);
    });
  });

  group('ResponsiveRowColumn widget', () {
    testWidgets('renders column on portrait mobile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveRowColumn(
              children: [Text('first'), Text('second')],
            ),
          ),
        ),
      );
      expect(find.byType(Column), findsWidgets);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('renders row on landscape', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(812, 375)),
            child: ResponsiveRowColumn(children: [Text('a'), Text('b')]),
          ),
        ),
      );
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders row when forceRow is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveRowColumn(
              forceRow: true,
              children: [Text('x'), Text('y')],
            ),
          ),
        ),
      );
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders column when forceRow is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(812, 375)),
            child: ResponsiveRowColumn(
              forceRow: false,
              children: [Text('p'), Text('q')],
            ),
          ),
        ),
      );
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders row on tablet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(800, 1024)),
            child: ResponsiveRowColumn(children: [Text('tab1'), Text('tab2')]),
          ),
        ),
      );
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('ResponsivePadding widget', () {
    testWidgets('applies responsive horizontal padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsivePadding(child: Text('padded content')),
          ),
        ),
      );
      expect(find.text('padded content'), findsOneWidget);
    });

    testWidgets('uses custom padding when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsivePadding(
              padding: EdgeInsets.all(32),
              child: Text('custom padded'),
            ),
          ),
        ),
      );
      expect(find.text('custom padded'), findsOneWidget);
    });

    testWidgets('uses provided horizontal and vertical values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsivePadding(
              horizontal: 20,
              vertical: 10,
              child: Text('h+v padded'),
            ),
          ),
        ),
      );
      expect(find.text('h+v padded'), findsOneWidget);
    });
  });

  group('ResponsiveSizedBox widget', () {
    testWidgets('renders with responsive width', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveSizedBox(width: 100, height: 50),
          ),
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('horizontal named constructor works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: Row(
              children: [
                ResponsiveSizedBox.horizontal(16),
                Text('after space'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('after space'), findsOneWidget);
    });

    testWidgets('vertical named constructor works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: Column(
              children: [ResponsiveSizedBox.vertical(24), Text('below space')],
            ),
          ),
        ),
      );
      expect(find.text('below space'), findsOneWidget);
    });

    testWidgets('renders child when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(375, 812)),
            child: ResponsiveSizedBox(
              width: 100,
              height: 100,
              child: Text('inside'),
            ),
          ),
        ),
      );
      expect(find.text('inside'), findsOneWidget);
    });
  });
}
