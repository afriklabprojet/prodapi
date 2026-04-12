import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/page_transitions.dart';

void main() {
  group('PageTransitions', () {
    final testPage = const SizedBox(key: ValueKey('test'));

    test('slideFromRight returns a Route', () {
      final route = PageTransitions.slideFromRight(testPage);
      expect(route, isA<Route>());
    });

    test('slideFromBottom returns a Route', () {
      final route = PageTransitions.slideFromBottom(testPage);
      expect(route, isA<Route>());
    });

    test('fadeScale returns a Route', () {
      final route = PageTransitions.fadeScale(testPage);
      expect(route, isA<Route>());
    });

    test('sharedAxis horizontal returns a Route', () {
      final route = PageTransitions.sharedAxis(testPage, horizontal: true);
      expect(route, isA<Route>());
    });

    test('sharedAxis vertical returns a Route', () {
      final route = PageTransitions.sharedAxis(testPage, horizontal: false);
      expect(route, isA<Route>());
    });

    testWidgets('slideFromRight produces a SlideTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransitions.slideFromRight(
                      const Scaffold(body: Text('Page 2')),
                    ),
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('fadeScale produces FadeTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransitions.fadeScale(
                      const Scaffold(body: Text('Page 2')),
                    ),
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FadeTransition), findsWidgets);
    });

    test('heroFade returns a Route', () {
      final route = PageTransitions.heroFade(testPage);
      expect(route, isA<Route>());
    });

    testWidgets('slideFromBottom produces SlideTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransitions.slideFromBottom(
                      const Scaffold(body: Text('Page 2')),
                    ),
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('sharedAxis produces transitions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransitions.sharedAxis(
                      const Scaffold(body: Text('Page 2')),
                      horizontal: true,
                    ),
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('heroFade produces FadeTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransitions.heroFade(
                      const Scaffold(body: Text('Page 2')),
                    ),
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FadeTransition), findsWidgets);
    });

    // ── AnimatedNavigation extension ─────────────
    testWidgets('pushSlide navigates to new page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    context.pushSlide(const Scaffold(body: Text('Slide Page'))),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Slide Page'), findsOneWidget);
    });

    testWidgets('pushFadeScale navigates to new page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => context.pushFadeScale(
                  const Scaffold(body: Text('Fade Page')),
                ),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Fade Page'), findsOneWidget);
    });

    testWidgets('pushSharedAxis navigates to new page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => context.pushSharedAxis(
                  const Scaffold(body: Text('Axis Page')),
                ),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Axis Page'), findsOneWidget);
    });

    testWidgets('pushHeroFade navigates to new page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => context.pushHeroFade(
                  const Scaffold(body: Text('Hero Page')),
                ),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Hero Page'), findsOneWidget);
    });

    testWidgets('pushReplacementSlide replaces current route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => context.pushReplacementSlide(
                  const Scaffold(body: Text('Replaced Page')),
                ),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Replaced Page'), findsOneWidget);
      expect(find.text('Go'), findsNothing);
    });
  });

  // ── DeliveryHeroTags ────────────────────────────
  group('DeliveryHeroTags', () {
    test('card returns correct tag', () {
      expect(DeliveryHeroTags.card(42), 'delivery_card_42');
      expect(DeliveryHeroTags.card(0), 'delivery_card_0');
    });

    test('icon returns correct tag', () {
      expect(DeliveryHeroTags.icon(42), 'delivery_icon_42');
    });

    test('id returns correct tag', () {
      expect(DeliveryHeroTags.id(42), 'delivery_id_42');
    });

    test('pharmacy returns correct tag', () {
      expect(DeliveryHeroTags.pharmacy(42), 'delivery_pharmacy_42');
    });

    test('status returns correct tag', () {
      expect(DeliveryHeroTags.status(42), 'delivery_status_42');
    });

    test('all tags are unique for same deliveryId', () {
      const id = 123;
      final tags = {
        DeliveryHeroTags.card(id),
        DeliveryHeroTags.icon(id),
        DeliveryHeroTags.id(id),
        DeliveryHeroTags.pharmacy(id),
        DeliveryHeroTags.status(id),
      };
      expect(tags.length, 5);
    });
  });
}
