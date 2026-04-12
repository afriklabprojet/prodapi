import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/onboarding_screen.dart';
import 'package:courier/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen() {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const OnboardingScreen(),
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

      expect(
        find.textContaining('Rejoignez l\'équipe DR-PHARMA'),
        findsOneWidget,
      );
    });

    testWidgets('displays navigation dots', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // 3 pages = 3 dots (AnimatedContainer)
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

      expect(find.text('Gagnez plus'), findsOneWidget);
    });

    testWidgets('tapping Suivant navigates to next page', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(find.text('Gagnez plus'), findsOneWidget);
    });

    testWidgets('displays all page icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_shipping_rounded), findsOneWidget);
    });

    testWidgets('last page shows Commencer button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Navigate to last page (3 pages, 2 taps)
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('Commencer saves onboarding preference', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to last page (3 pages, 2 taps)
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Commencer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify preference was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('courier_onboarding_completed'), isTrue);
    });
  });
}
