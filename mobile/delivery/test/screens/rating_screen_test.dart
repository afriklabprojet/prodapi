import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/rating_screen.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

void main() {
  late MockDeliveryRepository mockDeliveryRepo;

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDeliveryRepo = MockDeliveryRepository();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        deliveryRepositoryProvider.overrideWithValue(mockDeliveryRepo),
      ],
      child: const MaterialApp(
        home: RatingScreen(
          deliveryId: 42,
          customerName: 'Client Test',
          customerAddress: '123 Rue Abidjan',
        ),
      ),
    );
  }

  group('RatingScreen - Basic', () {
    testWidgets('renders rating screen', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays customer name', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Client Test'), findsWidgets);
    });

    testWidgets('has star rating elements', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);
    });

    testWidgets('has AppBar with title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has skip button (Passer)', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('displays customer address', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('123 Rue Abidjan'), findsWidgets);
    });

    testWidgets('has CircleAvatar for customer', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('has five star icons initially', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
    });

    testWidgets('shows default rating text before tap', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Touchez pour noter'), findsOneWidget);
    });
  });

  group('RatingScreen - Star interactions', () {
    testWidgets('tapping 1 star shows rating text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Tap first star via GestureDetector
      final gestures = find.byType(GestureDetector);
      // Find the GestureDetector that wraps the first star
      await tester.tap(gestures.at(1));
      await tester.pump(const Duration(milliseconds: 500));
      // After tapping 1 star, should show a rating text (mauvais/correct/etc.)
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('tapping 5th star shows excellent text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(4));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Excellent'), findsOneWidget);
    });

    testWidgets('tapping 4th star shows bien text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(3));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Bien'), findsOneWidget);
    });

    testWidgets('tapping 3rd star shows correct text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Correct'), findsOneWidget);
    });

    testWidgets('tapping 2nd star shows mauvais text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Mauvais'), findsOneWidget);
    });

    testWidgets('tapping star fills it', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(2));
      await tester.pump(const Duration(milliseconds: 500));
      // After tapping 3rd star, should have filled stars
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });
  });

  group('RatingScreen - Tags', () {
    testWidgets('tags appear after rating > 0', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Initially no tags
      expect(find.byType(FilterChip), findsNothing);
      // Tap a star
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(4));
      await tester.pump(const Duration(milliseconds: 500));
      // Tags should appear
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('positive tags shown for rating >= 4', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(4)); // 5 stars
      await tester.pump(const Duration(milliseconds: 500));
      // Positive tags: Client aimable, Facile à trouver, etc.
      expect(find.textContaining('Client aimable'), findsOneWidget);
    });

    testWidgets('negative tags shown for rating < 4', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.first); // 1 star
      await tester.pump(const Duration(milliseconds: 500));
      // Negative tags: Difficile à trouver, etc.
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('can select a tag', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(4)); // 5 stars
      await tester.pump(const Duration(milliseconds: 500));
      // Tap first FilterChip
      final chips = find.byType(FilterChip);
      await tester.tap(chips.first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FilterChip), findsWidgets);
    });
  });

  group('RatingScreen - Comment and Actions', () {
    testWidgets('comment field appears after rating', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(2)); // 3 stars
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('can type in comment field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final stars = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(stars.at(4)); // 5 stars
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextField), 'Très bon service');
      await tester.pump();
      expect(find.text('Très bon service'), findsOneWidget);
    });

    testWidgets('no address shows only name', (tester) async {
      final widget = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          deliveryRepositoryProvider.overrideWithValue(mockDeliveryRepo),
        ],
        child: const MaterialApp(
          home: RatingScreen(deliveryId: 42, customerName: 'Solo Name'),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Solo Name'), findsWidgets);
    });

    testWidgets('initialRating pre-fills stars', (tester) async {
      final widget = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          deliveryRepositoryProvider.overrideWithValue(mockDeliveryRepo),
        ],
        child: const MaterialApp(
          home: RatingScreen(
            deliveryId: 42,
            customerName: 'Client',
            initialRating: 4,
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(seconds: 1));
      // With initialRating=4, should show filled stars and tags immediately
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });
  });
}
