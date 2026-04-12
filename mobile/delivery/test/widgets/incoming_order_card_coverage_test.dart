import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/presentation/widgets/home/incoming_order_card.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

Delivery _makeDelivery({double? distanceKm, double? estimatedEarnings}) {
  return Delivery(
    id: 1,
    reference: 'REF-001',
    pharmacyName: 'Pharmacie de la Paix',
    pharmacyAddress: '12 Rue de la Paix, Abidjan',
    customerName: 'Jean Dupont',
    deliveryAddress: '45 Avenue de la Liberté',
    totalAmount: 5000,
    status: 'pending',
    distanceKm: distanceKm,
    estimatedEarnings: estimatedEarnings,
    createdAt: '2024-01-15T10:30:00Z',
  );
}

void main() {
  late MockDeliveryRepository mockRepo;

  setUp(() {
    mockRepo = MockDeliveryRepository();
  });

  Widget buildWidget({List<Delivery> deliveries = const []}) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        deliveriesProvider('pending').overrideWith((_) async => deliveries),
        courierProfileProvider.overrideWith(
          (_) async => throw Exception('no profile'),
        ),
        deliveryRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Stack(children: [IncomingOrderCard()])),
      ),
    );
  }

  group('IncomingOrderCard', () {
    testWidgets('shows nothing when no pending deliveries', (tester) async {
      await tester.pumpWidget(buildWidget(deliveries: []));
      await tester.pumpAndSettle();

      expect(find.text('NOUVELLE COURSE'), findsNothing);
    });

    testWidgets('shows card when there is a pending delivery', (tester) async {
      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      expect(find.text('NOUVELLE COURSE'), findsOneWidget);
      expect(find.text('Commande prête !'), findsOneWidget);
    });

    testWidgets('shows pharmacy name', (tester) async {
      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      expect(find.text('Pharmacie de la Paix'), findsOneWidget);
    });

    testWidgets('shows delivery address', (tester) async {
      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      expect(find.text('45 Avenue de la Liberté'), findsOneWidget);
    });

    testWidgets('shows distance and duration when distanceKm > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(deliveries: [_makeDelivery(distanceKm: 4.5)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('4.5 km'), findsOneWidget);
      expect(find.textContaining('min'), findsOneWidget);
    });

    testWidgets('shows IGNORER and ACCEPTER buttons', (tester) async {
      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      expect(find.text('IGNORER'), findsOneWidget);
      expect(find.text('ACCEPTER'), findsOneWidget);
    });

    testWidgets('shows estimatedEarnings when provided', (tester) async {
      await tester.pumpWidget(
        buildWidget(deliveries: [_makeDelivery(estimatedEarnings: 1500)]),
      );
      await tester.pumpAndSettle();

      // fr_FR uses thin non-breaking space as thousands separator
      expect(find.textContaining('1'), findsAtLeastNWidgets(1));
      expect(find.text('pour vous'), findsOneWidget);
    });

    testWidgets('shows totalAmount when no estimatedEarnings', (tester) async {
      await tester.pumpWidget(
        buildWidget(deliveries: [_makeDelivery(estimatedEarnings: null)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('5000 F'), findsOneWidget);
    });

    testWidgets('IGNORER calls rejectDelivery', (tester) async {
      when(() => mockRepo.rejectDelivery(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('IGNORER'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.rejectDelivery(1)).called(1);
    });

    testWidgets('IGNORER shows snackbar on success', (tester) async {
      when(() => mockRepo.rejectDelivery(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('IGNORER'));
      await tester.pumpAndSettle();

      expect(find.text('Course ignorée'), findsOneWidget);
    });

    testWidgets('IGNORER shows error snackbar on failure', (tester) async {
      when(
        () => mockRepo.rejectDelivery(any()),
      ).thenThrow(Exception('Erreur réseau'));

      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('IGNORER'));
      await tester.pumpAndSettle();

      // Error snackbar should appear
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('LinearProgressIndicator is present (countdown bar)', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(deliveries: [_makeDelivery()]));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
