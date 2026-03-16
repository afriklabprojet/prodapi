import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen() {
    return const MaterialApp(
      home: OnboardingScreen(),
    );
  }

  group('OnboardingScreen', () {
    testWidgets('displays first page title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue Livreur'), findsOneWidget);
    });

    testWidgets('displays first page description', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Rejoignez l\'équipe DR-PHARMA'), findsOneWidget);
    });

    testWidgets('displays navigation dots', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // 5 pages = 5 dots (AnimatedContainer)
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('displays Suivant button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Suivant'), findsOneWidget);
    });

    testWidgets('displays Passer button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('swiping shows second page', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Swipe left
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Recevez des commandes'), findsOneWidget);
    });

    testWidgets('tapping Suivant navigates to next page', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(find.text('Recevez des commandes'), findsOneWidget);
    });

    testWidgets('displays all page icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_shipping_rounded), findsOneWidget);
    });

    testWidgets('last page shows Commencer button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Navigate to last page (5 pages, 4 swipes)
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('Commencer saves onboarding preference', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );
      await tester.pumpAndSettle();

      // Navigate to last page
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Commencer'));
      // Use pump() instead of pumpAndSettle() because navigation target may have animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify preference was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('courier_onboarding_completed'), isTrue);
    });
  });
}
