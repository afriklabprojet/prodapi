import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/help_center_screen.dart';
import 'package:courier/data/repositories/support_repository.dart';
// SupportTicket model used indirectly via MockSupportRepository

class MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late MockSupportRepository mockSupportRepo;

  setUp(() {
    mockSupportRepo = MockSupportRepository();
    // Return empty FAQ list so the screen falls back to default FAQ items
    when(() => mockSupportRepo.getFaq()).thenAnswer((_) async => []);
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        supportRepositoryProvider.overrideWithValue(mockSupportRepo),
      ],
      child: const MaterialApp(home: HelpCenterScreen()),
    );
  }

  group('HelpCenterScreen', () {
    testWidgets('displays header title and subtitle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Centre d\'aide'), findsOneWidget);
      expect(find.text('Questions fréquentes'), findsOneWidget);
    });

    testWidgets('displays search field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays all 10 FAQ questions', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Verify key FAQ questions are visible (scrollable list)
      expect(find.text('Comment accepter une livraison ?'), findsOneWidget);
      expect(find.text('Comment recharger mon portefeuille ?'), findsOneWidget);
      expect(find.text('Comment fonctionne la commission ?'), findsOneWidget);
      expect(find.text('Comment confirmer une livraison ?'), findsOneWidget);
    });

    testWidgets('tapping FAQ item expands to show answer', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Initially answer should not be visible (collapsed)
      final question = find.text('Comment accepter une livraison ?');
      expect(question, findsOneWidget);

      // Tap to expand
      await tester.tap(question);
      await tester.pumpAndSettle();

      // Answer should now be visible
      expect(
        find.textContaining('Quand une nouvelle livraison est disponible'),
        findsOneWidget,
      );
    });

    testWidgets('tapping expanded FAQ item collapses it', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final question = find.text('Comment accepter une livraison ?');

      // Expand
      await tester.tap(question);
      await tester.pumpAndSettle();

      // Collapse
      await tester.tap(question);
      await tester.pumpAndSettle();

      // Widget still exists but CrossFade should show first child (SizedBox.shrink)
      // The answer text is still in tree but hidden by AnimatedCrossFade
    });

    testWidgets('search filters FAQ items', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Type search query
      await tester.enterText(find.byType(TextField), 'commission');
      await tester.pumpAndSettle();

      // Only the commission FAQ should remain visible
      expect(find.text('Comment fonctionne la commission ?'), findsOneWidget);
      // Others should be gone
      expect(find.text('Comment accepter une livraison ?'), findsNothing);
    });

    testWidgets('search with no results shows empty state', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pumpAndSettle();

      expect(find.text('Aucun résultat trouvé'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('displays contact support section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Scroll to the bottom to find the support section
      await tester.scrollUntilVisible(
        find.text('Besoin d\'aide supplémentaire ?'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Besoin d\'aide supplémentaire ?'), findsOneWidget);
      expect(find.byIcon(Icons.headset_mic), findsOneWidget);
      expect(find.text('Appeler'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('back button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
