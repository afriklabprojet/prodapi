import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/help_center_screen.dart';
import 'package:courier/data/repositories/support_repository.dart';
import 'package:courier/data/models/support_ticket.dart';
import '../helpers/widget_test_helpers.dart';

class MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());

  late MockSupportRepository mockSupportRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSupportRepo = MockSupportRepository();
  });

  Widget buildScreen({required List<FAQItem> faqItems}) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        supportRepositoryProvider.overrideWithValue(mockSupportRepo),
      ],
      child: const MaterialApp(home: HelpCenterScreen()),
    );
  }

  group('HelpCenterScreen supplemental coverage', () {
    testWidgets('displays API-returned FAQ items when non-empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Return non-empty list from API so _iconFromString is called
      when(() => mockSupportRepo.getFaq()).thenAnswer(
        (_) async => [
          const FAQItem(
            question: 'Comment utiliser l\'app ?',
            answer: 'Réponse de l\'API',
            icon: 'delivery_dining',
          ),
          const FAQItem(
            question: 'Paiement Mobile Money',
            answer: 'Réponse paiement',
            icon: 'payment',
          ),
          const FAQItem(
            question: 'Sécurité du compte',
            answer: 'Réponse sécurité',
            icon: 'security',
          ),
        ],
      );

      await tester.pumpWidget(buildScreen(faqItems: []));
      await tester.pumpAndSettle();

      expect(find.text('Comment utiliser l\'app ?'), findsOneWidget);
      expect(find.text('Paiement Mobile Money'), findsOneWidget);
    });

    testWidgets('uses _iconFromString with unknown icon → Help default', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockSupportRepo.getFaq()).thenAnswer(
        (_) async => [
          const FAQItem(
            question: 'Question inconnue',
            answer: 'Réponse',
            icon: 'unknown_icon_name',
          ),
          const FAQItem(
            question: 'Question star',
            answer: 'Réponse star',
            icon: 'star',
          ),
        ],
      );

      await tester.pumpWidget(buildScreen(faqItems: []));
      await tester.pumpAndSettle();

      expect(find.text('Question inconnue'), findsOneWidget);
      expect(find.text('Question star'), findsOneWidget);
    });

    testWidgets('filters API items by search query', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockSupportRepo.getFaq()).thenAnswer(
        (_) async => [
          const FAQItem(
            question: 'Comment livrer ?',
            answer: 'Vous livrez comme ceci',
            icon: 'delivery_dining',
          ),
          const FAQItem(
            question: 'Problème de paiement',
            answer: 'Pour le paiement',
            icon: 'payment',
          ),
        ],
      );

      await tester.pumpWidget(buildScreen(faqItems: []));
      await tester.pumpAndSettle();

      // Enter search query that matches only one item
      await tester.enterText(find.byType(TextField), 'livrer');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Comment livrer ?'), findsOneWidget);
    });

    testWidgets('shows empty state when API items filtered out', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockSupportRepo.getFaq()).thenAnswer(
        (_) async => [
          const FAQItem(
            question: 'Comment livrer ?',
            answer: 'Réponse livraison',
            icon: 'delivery_dining',
          ),
        ],
      );

      await tester.pumpWidget(buildScreen(faqItems: []));
      await tester.pumpAndSettle();

      // Search term that matches nothing in API items
      await tester.enterText(find.byType(TextField), 'xyzintrouvable');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Aucun résultat trouvé'), findsOneWidget);
    });

    testWidgets('shows loading state while FAQ loads', (tester) async {
      final completer = Completer<List<FAQItem>>();
      when(() => mockSupportRepo.getFaq()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildScreen(faqItems: []));
      await tester.pump(const Duration(milliseconds: 100));

      // Loading widget should appear
      expect(find.text('Chargement des FAQ...'), findsOneWidget);

      // Complete the future to avoid pending timers
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows contact section with phone WhatsApp and email buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockSupportRepo.getFaq()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen(faqItems: []));
      await tester.pumpAndSettle();

      expect(find.text('Appeler'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });
  });
}
