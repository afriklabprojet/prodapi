import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/batch_deliveries_screen.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/repositories/delivery_repository.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

Delivery _delivery({
  int id = 1,
  String pharmacyName = 'Pharmacie Test',
  String deliveryAddress = '123 Rue Test, Abidjan',
  String customerName = 'Client Test',
  double totalAmount = 5000,
  double? deliveryFee = 1500,
  double? commission = 300,
  double? estimatedEarnings,
  double? distanceKm = 3.5,
}) {
  return Delivery(
    id: id,
    reference: 'REF-$id',
    pharmacyName: pharmacyName,
    pharmacyAddress: 'Adresse pharmacie',
    customerName: customerName,
    deliveryAddress: deliveryAddress,
    totalAmount: totalAmount,
    deliveryFee: deliveryFee,
    commission: commission,
    estimatedEarnings: estimatedEarnings,
    distanceKm: distanceKm,
    status: 'pending',
  );
}

Widget buildTestWidget({
  required List<Delivery> deliveries,
  MockDeliveryRepository? mockRepo,
}) {
  return ProviderScope(
    overrides: [
      deliveriesProvider('pending').overrideWith((ref) => Future.value(deliveries)),
      if (mockRepo != null) deliveryRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: const MaterialApp(home: BatchDeliveriesScreen()),
  );
}

void main() {
  late MockDeliveryRepository mockRepo;

  setUp(() {
    mockRepo = MockDeliveryRepository();
  });

  group('BatchDeliveriesScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: []));
      await tester.pumpAndSettle();
      expect(find.text('Courses Disponibles'), findsOneWidget);
    });

    testWidgets('shows empty state when no deliveries', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: []));
      await tester.pumpAndSettle();
      expect(find.text('Aucune course disponible'), findsOneWidget);
      expect(find.text('Revenez plus tard ou activez-vous en ligne'), findsOneWidget);
    });

    testWidgets('shows delivery cards', (tester) async {
      final deliveries = [
        _delivery(id: 1, pharmacyName: 'Pharma Alpha'),
        _delivery(id: 2, pharmacyName: 'Pharma Beta'),
      ];
      await tester.pumpWidget(buildTestWidget(deliveries: deliveries));
      await tester.pumpAndSettle();
      expect(find.text('Pharma Alpha'), findsOneWidget);
      expect(find.text('Pharma Beta'), findsOneWidget);
    });

    testWidgets('shows delivery address and customer', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(
          customerName: 'Jean Dupont',
          deliveryAddress: 'Cocody, Abidjan',
        ),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.text('Cocody, Abidjan'), findsOneWidget);
    });

    testWidgets('tapping delivery toggles selection', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(id: 1, pharmacyName: 'Pharma Test'),
      ]));
      await tester.pumpAndSettle();

      // Tap the delivery card
      await tester.tap(find.text('Pharma Test'));
      await tester.pumpAndSettle();

      // Selection info should appear
      expect(find.textContaining('sélectionnée'), findsOneWidget);
      expect(find.text('Maximum 5 courses à la fois'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows accept button when items selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(id: 1, pharmacyName: 'Pharma Test'),
      ]));
      await tester.pumpAndSettle();

      // Select the delivery
      await tester.tap(find.text('Pharma Test'));
      await tester.pumpAndSettle();

      // Accept button and earnings should appear
      expect(find.textContaining('Accepter'), findsOneWidget);
      expect(find.textContaining('Gains estimés'), findsOneWidget);
    });

    testWidgets('shows clear button when items selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(id: 1, pharmacyName: 'Pharma Test'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma Test'));
      await tester.pumpAndSettle();

      expect(find.text('Effacer'), findsOneWidget);
    });

    testWidgets('clear button deselects all', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(id: 1, pharmacyName: 'Pharma Test'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma Test'));
      await tester.pumpAndSettle();
      expect(find.textContaining('sélectionnée'), findsOneWidget);

      await tester.tap(find.text('Effacer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('sélectionnée'), findsNothing);
    });

    testWidgets('shows distance on card', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(distanceKm: 4.2),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('4.2 km'), findsOneWidget);
    });

    testWidgets('loading state shows indicator', (tester) async {
      late Future<List<Delivery>> completer;
      completer = Future(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return <Delivery>[];
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveriesProvider('pending').overrideWith((ref) => completer),
          ],
          child: const MaterialApp(home: BatchDeliveriesScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      await tester.pumpAndSettle();
    });

    // --- Multi-selection tests ---

    testWidgets('can select multiple deliveries', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(id: 1, pharmacyName: 'Pharma A'),
        _delivery(id: 2, pharmacyName: 'Pharma B'),
        _delivery(id: 3, pharmacyName: 'Pharma C'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pharma B'));
      await tester.pumpAndSettle();

      expect(find.textContaining('2'), findsAtLeastNWidgets(1));
      expect(find.textContaining('sélectionnée'), findsOneWidget);
    });

    testWidgets('deselecting reduces count', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: [
        _delivery(id: 1, pharmacyName: 'Pharma A'),
        _delivery(id: 2, pharmacyName: 'Pharma B'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pharma B'));
      await tester.pumpAndSettle();

      // Deselect first
      await tester.tap(find.text('Pharma A'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1'), findsAtLeastNWidgets(1));
    });

    // --- Accept flow tests ---

    testWidgets('accept shows success dialog', (tester) async {
      when(() => mockRepo.batchAcceptDeliveries(any()))
          .thenAnswer((_) async => {
                'accepted_count': 1,
                'total_estimated_earnings': 1500,
              });

      await tester.pumpWidget(buildTestWidget(
        deliveries: [_delivery(id: 1, pharmacyName: 'Pharma Accept')],
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      // Select delivery
      await tester.tap(find.text('Pharma Accept'));
      await tester.pumpAndSettle();

      // Tap accept button
      await tester.tap(find.textContaining('Accepter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Acceptée'), findsOneWidget);
      expect(find.text('Voir mes courses'), findsOneWidget);
    });

    testWidgets('accept failure shows error snackbar', (tester) async {
      when(() => mockRepo.batchAcceptDeliveries(any()))
          .thenThrow(Exception('Erreur serveur'));

      await tester.pumpWidget(buildTestWidget(
        deliveries: [_delivery(id: 1, pharmacyName: 'Pharma Fail')],
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma Fail'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Accepter'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('réessayer'), findsOneWidget);
    });

    testWidgets('accept shows loading state', (tester) async {
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockRepo.batchAcceptDeliveries(any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget(
        deliveries: [_delivery(id: 1, pharmacyName: 'Pharma Loading')],
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma Loading'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Accepter'));
      await tester.pump();

      expect(find.text('Acceptation...'), findsOneWidget);

      completer.complete({'accepted_count': 1, 'total_estimated_earnings': 1000});
      await tester.pumpAndSettle();
    });

    testWidgets('accept sends correct delivery IDs', (tester) async {
      when(() => mockRepo.batchAcceptDeliveries(any()))
          .thenAnswer((_) async => {'accepted_count': 2, 'total_estimated_earnings': 3000});

      await tester.pumpWidget(buildTestWidget(
        deliveries: [
          _delivery(id: 10, pharmacyName: 'Pharma X'),
          _delivery(id: 20, pharmacyName: 'Pharma Y'),
        ],
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma X'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pharma Y'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Accepter'));
      await tester.pumpAndSettle();

      final captured = verify(() => mockRepo.batchAcceptDeliveries(captureAny())).captured;
      final ids = captured.first as List<int>;
      expect(ids, containsAll([10, 20]));
    });

    testWidgets('accept dialog shows earnings formatted', (tester) async {
      when(() => mockRepo.batchAcceptDeliveries(any()))
          .thenAnswer((_) async => {
                'accepted_count': 3,
                'total_estimated_earnings': 15000,
              });

      await tester.pumpWidget(buildTestWidget(
        deliveries: [_delivery(id: 1, pharmacyName: 'Pharma Earn')],
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pharma Earn'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Accepter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gains'), findsAtLeastNWidgets(1));
      expect(find.textContaining('15'), findsAtLeastNWidgets(1));
    });
  });
}
