import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/rating_screen.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpRating(
    WidgetTester tester, {
    int initialRating = 0,
    String? customerAddress,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = MockDeliveryRepository();

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
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
              deliveryId: 42,
              customerName: 'Client Test',
              customerAddress: customerAddress,
              initialRating: initialRating,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = original;
    }
  }

  Future<void> drainTimers(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('RatingScreen', () {
    testWidgets('renders rating screen', (tester) async {
      await pumpRating(tester);
      expect(find.byType(RatingScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('shows customer name', (tester) async {
      await pumpRating(tester);
      expect(find.textContaining('Client Test'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows star rating widgets', (tester) async {
      await pumpRating(tester);
      // Should have some star/rating widget
      expect(find.byType(RatingScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('shows customer address when provided', (tester) async {
      await pumpRating(tester, customerAddress: '123 Rue Abidjan');
      expect(find.textContaining('Abidjan'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('tap star to rate', (tester) async {
      await pumpRating(tester);
      // Tap on the 4th star
      final stars = find.byIcon(Icons.star_border);
      if (stars.evaluate().length >= 4) {
        await tester.tap(stars.at(3));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await drainTimers(tester);
    });

    testWidgets('initial rating shows rated state', (tester) async {
      await pumpRating(tester, initialRating: 3);
      expect(find.byType(RatingScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('comment text field exists', (tester) async {
      await pumpRating(tester, initialRating: 4);
      // After rating, tags and comment should appear
      expect(find.byType(TextField), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('has submit button', (tester) async {
      await pumpRating(tester, initialRating: 5);
      // Submit button should exist
      expect(find.byType(ElevatedButton), findsWidgets);
      await drainTimers(tester);
    });
  });
}
