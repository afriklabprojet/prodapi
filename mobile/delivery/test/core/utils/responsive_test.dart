import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/responsive.dart';

/// Helper to pump a widget with a specific screen size
Widget _buildWithSize(
  Size size,
  void Function(Responsive r) callback, {
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, padding: padding, viewInsets: viewInsets),
    child: MaterialApp(
      home: Builder(
        builder: (context) {
          callback(Responsive.of(context));
          return const SizedBox();
        },
      ),
    ),
  );
}

void main() {
  group('Responsive', () {
    testWidgets('of(context) captures screen dimensions', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              r = Responsive.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(r.screenWidth, greaterThan(0));
      expect(r.screenHeight, greaterThan(0));
      expect(r.aspectRatio, greaterThan(0));
    });

    testWidgets('w(50) returns half screen width', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              r = Responsive.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(r.w(50), closeTo(r.screenWidth / 2, 0.1));
    });

    testWidgets('h(50) returns half screen height', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              r = Responsive.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(r.h(50), closeTo(r.screenHeight / 2, 0.1));
    });

    testWidgets('scale factors are positive', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              r = Responsive.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(r.scaleX, greaterThan(0));
      expect(r.scaleY, greaterThan(0));
      expect(r.scale, greaterThanOrEqualTo(0.8));
      expect(r.scale, lessThanOrEqualTo(1.6));
    });

    testWidgets('wp, hp, dp return positive for positive input', (
      tester,
    ) async {
      late Responsive r;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              r = Responsive.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(r.wp(16), greaterThan(0));
      expect(r.hp(16), greaterThan(0));
      expect(r.dp(16), greaterThan(0));
    });

    // ── sp (font scaling) ─────────────────────────
    testWidgets('sp returns positive scaled font size', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      expect(r.sp(16), greaterThan(0));
    });

    // ── Padding helpers ───────────────────────────
    testWidgets('pad returns EdgeInsets.all', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      final p = r.pad(10);
      expect(p.left, p.right);
      expect(p.top, p.bottom);
      expect(p.left, p.top);
      expect(p.left, greaterThan(0));
    });

    testWidgets('padH returns symmetric horizontal', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      final p = r.padH(10);
      expect(p.left, p.right);
      expect(p.left, greaterThan(0));
      expect(p.top, 0);
      expect(p.bottom, 0);
    });

    testWidgets('padV returns symmetric vertical', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      final p = r.padV(10);
      expect(p.top, p.bottom);
      expect(p.top, greaterThan(0));
      expect(p.left, 0);
      expect(p.right, 0);
    });

    testWidgets('padOnly sets individual edges', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      final p = r.padOnly(left: 10, top: 20, right: 30, bottom: 40);
      expect(p.left, greaterThan(0));
      expect(p.top, greaterThan(0));
      expect(p.right, greaterThan(0));
      expect(p.bottom, greaterThan(0));
      // values should differ since inputs differ
      expect(p.top, greaterThan(p.left));
      expect(p.right, greaterThan(p.top));
      expect(p.bottom, greaterThan(p.right));
    });

    // ── Device detection ──────────────────────────
    testWidgets('smallPhone detected for width < 360', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(320, 568), (resp) => r = resp),
      );
      expect(r.deviceType, DeviceType.smallPhone);
      expect(r.isSmallPhone, true);
      expect(r.isPhone, true); // includes smallPhone
      expect(r.isTablet, false);
      expect(r.isDesktop, false);
    });

    testWidgets('phone detected for 360 <= width < 414', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      expect(r.deviceType, DeviceType.phone);
      expect(r.isSmallPhone, false);
      expect(r.isPhone, true);
    });

    testWidgets('largePhone detected for 600 <= width < 840', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(700, 1000), (resp) => r = resp),
      );
      expect(r.deviceType, DeviceType.largePhone);
      expect(r.isLargePhone, true);
      expect(r.isTablet, false);
      expect(r.isTabletOrLarger, false);
    });

    testWidgets('tablet detected for 840 <= width < 1200', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(900, 1200), (resp) => r = resp),
      );
      expect(r.deviceType, DeviceType.tablet);
      expect(r.isTablet, true);
      expect(r.isTabletOrLarger, true);
      expect(r.isDesktop, false);
    });

    testWidgets('desktop detected for width >= 1200', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(1440, 900), (resp) => r = resp),
      );
      expect(r.deviceType, DeviceType.desktop);
      expect(r.isDesktop, true);
      expect(r.isTabletOrLarger, true);
    });

    // ── Orientation ───────────────────────────────
    testWidgets('isLandscape and isPortrait', (tester) async {
      late Responsive rPortrait;
      late Responsive rLandscape;

      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => rPortrait = resp),
      );
      expect(rPortrait.isPortrait, true);
      expect(rPortrait.isLandscape, false);

      await tester.pumpWidget(
        _buildWithSize(const Size(812, 375), (resp) => rLandscape = resp),
      );
      expect(rLandscape.isLandscape, true);
      expect(rLandscape.isPortrait, false);
    });

    // ── Safe area & keyboard ──────────────────────
    testWidgets('safeArea reads MediaQuery padding', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(
          const Size(375, 812),
          (resp) => r = resp,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
      );
      expect(r.safeArea.top, 44);
      expect(r.safeArea.bottom, 34);
    });

    testWidgets('keyboardHeight and isKeyboardVisible', (tester) async {
      late Responsive rNoKb;
      late Responsive rWithKb;

      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => rNoKb = resp),
      );
      expect(rNoKb.keyboardHeight, 0);
      expect(rNoKb.isKeyboardVisible, false);

      await tester.pumpWidget(
        _buildWithSize(
          const Size(375, 812),
          (resp) => rWithKb = resp,
          viewInsets: const EdgeInsets.only(bottom: 300),
        ),
      );
      expect(rWithKb.keyboardHeight, 300);
      expect(rWithKb.isKeyboardVisible, true);
    });

    // ── adaptive() ────────────────────────────────
    testWidgets('adaptive returns correct value per device', (tester) async {
      late Responsive rPhone;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => rPhone = resp),
      );
      expect(rPhone.adaptive(phone: 'P', tablet: 'T', desktop: 'D'), 'P');

      late Responsive rTablet;
      await tester.pumpWidget(
        _buildWithSize(const Size(900, 1200), (resp) => rTablet = resp),
      );
      expect(rTablet.adaptive(phone: 'P', tablet: 'T', desktop: 'D'), 'T');

      late Responsive rDesktop;
      await tester.pumpWidget(
        _buildWithSize(const Size(1400, 900), (resp) => rDesktop = resp),
      );
      expect(rDesktop.adaptive(phone: 'P', tablet: 'T', desktop: 'D'), 'D');
    });

    testWidgets('adaptive falls back to phone if specific not given', (
      tester,
    ) async {
      late Responsive rTablet;
      await tester.pumpWidget(
        _buildWithSize(const Size(900, 1200), (resp) => rTablet = resp),
      );
      // When tablet is null, should fall back to phone
      expect(rTablet.adaptive(phone: 'fallback'), 'fallback');
    });

    testWidgets('adaptive smallPhone returns smallPhone value', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(320, 568), (resp) => r = resp),
      );
      expect(r.adaptive(phone: 'P', smallPhone: 'SP'), 'SP');
    });

    testWidgets('adaptive smallPhone falls back to phone', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(320, 568), (resp) => r = resp),
      );
      expect(r.adaptive(phone: 'P'), 'P');
    });

    testWidgets('adaptive largePhone returns largePhone value', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(700, 1000), (resp) => r = resp),
      );
      expect(r.adaptive(phone: 'P', largePhone: 'LP'), 'LP');
    });

    testWidgets('adaptive largePhone falls back to phone', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(700, 1000), (resp) => r = resp),
      );
      expect(r.adaptive(phone: 'P'), 'P');
    });

    testWidgets('adaptive tablet uses largePhone if tablet is null', (
      tester,
    ) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(900, 1200), (resp) => r = resp),
      );
      expect(r.adaptive(phone: 'P', largePhone: 'LP'), 'LP');
    });

    testWidgets(
      'adaptive desktop falls back to tablet then largePhone then phone',
      (tester) async {
        late Responsive r;
        await tester.pumpWidget(
          _buildWithSize(const Size(1440, 900), (resp) => r = resp),
        );
        // desktop=null → tablet
        expect(r.adaptive(phone: 'P', tablet: 'T'), 'T');
        // desktop=null, tablet=null → largePhone
        expect(r.adaptive(phone: 'P', largePhone: 'LP'), 'LP');
        // desktop=null, tablet=null, largePhone=null → phone
        expect(r.adaptive(phone: 'P'), 'P');
      },
    );

    // ── gridColumns ───────────────────────────────
    testWidgets('gridColumns returns phone value for phone', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      expect(r.gridColumns, greaterThan(0));
    });

    testWidgets('gridColumns returns more for tablet', (tester) async {
      late Responsive rPhone;
      late Responsive rTablet;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => rPhone = resp),
      );
      await tester.pumpWidget(
        _buildWithSize(const Size(900, 1200), (resp) => rTablet = resp),
      );
      expect(rTablet.gridColumns, greaterThanOrEqualTo(rPhone.gridColumns));
    });

    // ── maxContentWidth ───────────────────────────
    testWidgets('maxContentWidth returns value > 0', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        _buildWithSize(const Size(375, 812), (resp) => r = resp),
      );
      expect(r.maxContentWidth, greaterThan(0));
    });

    // ── Extension ─────────────────────────────────
    testWidgets('context.r provides Responsive instance', (tester) async {
      late Responsive r;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              r = context.r;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(r.screenWidth, greaterThan(0));
    });
  });

  group('AdaptiveLayout', () {
    testWidgets('builder receives Responsive instance', (tester) async {
      late Responsive capturedR;
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            builder: (context, r) {
              capturedR = r;
              return const Text('adaptive');
            },
          ),
        ),
      );
      expect(capturedR.screenWidth, greaterThan(0));
      expect(find.text('adaptive'), findsOneWidget);
    });
  });

  group('ResponsiveScaffold', () {
    testWidgets('renders body with SafeArea by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ResponsiveScaffold(body: const Text('content'))),
      );
      expect(find.text('content'), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('disables SafeArea when useSafeArea=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            body: const Text('no safe'),
            useSafeArea: false,
          ),
        ),
      );
      expect(find.text('no safe'), findsOneWidget);
      expect(find.byType(SafeArea), findsNothing);
    });

    testWidgets('renders with appBar and bottomNav', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            appBar: AppBar(title: const Text('Title')),
            body: const Text('body'),
            bottomNavigationBar: const BottomAppBar(
              child: SizedBox(height: 56),
            ),
            floatingActionButton: FloatingActionButton(onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('centers content on tablet-sized screen', (tester) async {
      tester.view.physicalSize = const Size(2400, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            body: const Text('centered'),
            centerOnTablet: true,
          ),
        ),
      );
      expect(find.text('centered'), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('does not center on tablet when centerOnTablet=false', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            body: const Text('not centered'),
            centerOnTablet: false,
          ),
        ),
      );
      expect(find.text('not centered'), findsOneWidget);
    });
  });

  group('ResponsiveGrid', () {
    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGrid(
              shrinkWrap: true,
              children: const [Text('A'), Text('B'), Text('C'), Text('D')],
            ),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('respects minColumns and maxColumns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGrid(
              shrinkWrap: true,
              minColumns: 3,
              maxColumns: 5,
              children: const [
                Text('1'),
                Text('2'),
                Text('3'),
                Text('4'),
                Text('5'),
                Text('6'),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('renders with custom spacing and padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGrid(
              shrinkWrap: true,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              padding: const EdgeInsets.all(8),
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: const [Text('item')],
            ),
          ),
        ),
      );
      expect(find.text('item'), findsOneWidget);
    });
  });

  group('RText', () {
    testWidgets('renders text with auto-scaled font size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RText('Hello responsive'))),
      );
      expect(find.text('Hello responsive'), findsOneWidget);
    });

    testWidgets('applies custom style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RText(
              'Styled',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ),
      );
      expect(find.text('Styled'), findsOneWidget);
    });

    testWidgets('uses default style when no style provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RText('Default'))),
      );
      final textWidget = tester.widget<Text>(find.text('Default'));
      expect(textWidget.style?.fontSize, isNotNull);
    });
  });
}
