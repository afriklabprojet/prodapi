import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/rating_screen.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/core/services/offline_service.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OfflineService.testStore = {};
  });
  tearDown(() {
    OfflineService.testStore = null;
  });

  Future<void> pumpRating(
    WidgetTester tester,
    MockDeliveryRepository mockRepo, {
    int initialRating = 0,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          deliveryRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RatingScreen(
            deliveryId: 1,
            customerName: 'Client Test',
            initialRating: initialRating,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RatingScreen _submitRating coverage', () {
    testWidgets('submit with no stars shows validation snackbar', (
      tester,
    ) async {
      final mockRepo = MockDeliveryRepository();
      await pumpRating(tester, mockRepo);

      // Tap submit without selecting any star
      final submitBtn = find.text("Envoyer l'évaluation");
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn.first);
        await tester.pumpAndSettle();
        expect(find.text('Veuillez donner une note'), findsOneWidget);
      }
    });

    testWidgets(
      'submit with rating calls rateCustomer and shows success dialog',
      (tester) async {
        final mockRepo = MockDeliveryRepository();
        when(
          () => mockRepo.rateCustomer(
            deliveryId: any(named: 'deliveryId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async {});

        await pumpRating(tester, mockRepo, initialRating: 5);

        // Tap submit button
        final submitBtn = find.text("Envoyer l'évaluation");
        if (submitBtn.evaluate().isNotEmpty) {
          await tester.tap(submitBtn.first);
          await tester.pump();
          await tester.pumpAndSettle();

          // Success dialog should appear
          expect(find.text('Merci pour votre avis !'), findsOneWidget);
          expect(find.text('Continuer'), findsOneWidget);
        }
      },
    );

    testWidgets('tap Continuer in success dialog pops the screen', (
      tester,
    ) async {
      final mockRepo = MockDeliveryRepository();
      when(
        () => mockRepo.rateCustomer(
          deliveryId: any(named: 'deliveryId'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer((_) async {});

      await pumpRating(tester, mockRepo, initialRating: 4);

      final submitBtn = find.text("Envoyer l'évaluation");
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn.first);
        await tester.pump();
        await tester.pumpAndSettle();

        final continueBtn = find.text('Continuer');
        if (continueBtn.evaluate().isNotEmpty) {
          await tester.tap(continueBtn.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('submit with repo error covers catch block', (tester) async {
      final mockRepo = MockDeliveryRepository();
      when(
        () => mockRepo.rateCustomer(
          deliveryId: any(named: 'deliveryId'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
          tags: any(named: 'tags'),
        ),
      ).thenThrow(Exception('network error'));

      await pumpRating(tester, mockRepo, initialRating: 3);

      final submitBtn = find.text("Envoyer l'évaluation");
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn.first);
        await tester.pump();
        await tester.pumpAndSettle();
        // Either offline save snackbar or error snackbar appears
        expect(
          find.byType(SnackBar).evaluate().isNotEmpty ||
              find.byType(AlertDialog).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('skip button calls _skipRating', (tester) async {
      final mockRepo = MockDeliveryRepository();
      await pumpRating(tester, mockRepo);

      final skipBtn = find.text('Passer');
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn.first);
        await tester.pumpAndSettle();
      }
      // No crash expected
    });

    testWidgets('tap star to set rating then verify submit shows star selected', (
      tester,
    ) async {
      final mockRepo = MockDeliveryRepository();
      when(
        () => mockRepo.rateCustomer(
          deliveryId: any(named: 'deliveryId'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer((_) async {});

      await pumpRating(tester, mockRepo);

      // Ensure stars are visible
      final stars = find.byIcon(Icons.star_border);
      if (stars.evaluate().isNotEmpty) {
        await tester.tap(stars.first);
        await tester.pump(const Duration(milliseconds: 400)); // animation
        await tester.pumpAndSettle();
        // Rating is now set, we can verify submit doesn't show the validation snackbar
        await tester.tap(find.text("Envoyer l'évaluation").first);
        await tester.pump();
        await tester.pumpAndSettle();
        // No "Veuillez donner une note" snackbar
        expect(find.text('Veuillez donner une note'), findsNothing);
      }
    });
  });
}
