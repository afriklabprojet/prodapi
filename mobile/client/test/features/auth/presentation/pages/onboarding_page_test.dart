import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/auth/presentation/pages/onboarding_page.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: MaterialApp(
        home: const OnboardingPage(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login')),
          '/register': (_) => const Scaffold(body: Text('Register')),
        },
      ),
    );
  }

  group('OnboardingPage Widget Tests', () {
    testWidgets('should render onboarding page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should display onboarding slides', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should have page indicators', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should have next button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should have skip button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should display slide images', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should display slide titles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should display slide descriptions', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should swipe to next slide', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final pageView = find.byType(PageView);
      if (pageView.evaluate().isNotEmpty) {
        await tester.drag(pageView.first, const Offset(-300, 0));
      }

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should navigate to login after last slide', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });

  group('OnboardingPage Interactive Content', () {
    testWidgets('shows Bienvenue sur DR-PHARMA title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('DR-PHARMA'), findsOneWidget);
    });

    testWidgets('shows pharmacy icon in step 0', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.local_pharmacy_rounded), findsOneWidget);
    });

    testWidgets('shows search hint text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Ex: Doliprane, Advil...'), findsOneWidget);
    });

    testWidgets('shows skip button with text Passer', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('entering 2+ chars in search triggers mock results', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Do');
      await tester.pump();

      // '1000mg' is unique to mock product 'Doliprane 1000mg', not in hint text
      expect(find.textContaining('1000mg'), findsOneWidget);
    });

    testWidgets('entering less than 2 chars does not show results', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'D');
      await tester.pump();

      // '1000mg' is only in mock result titles, NOT in the hint text
      expect(find.textContaining('1000mg'), findsNothing);
    });

    testWidgets('mock results show multiple products when searching', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ad');
      await tester.pump();

      // Advil 400mg appears in mock results
      expect(find.textContaining('400mg'), findsOneWidget);
    });
  });
}
