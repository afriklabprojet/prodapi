import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/deliveries_screen.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/delivery.dart';
import '../helpers/widget_test_helpers.dart';

Delivery _delivery({
  int id = 1,
  String pharmacyName = 'Pharmacie Test',
  String deliveryAddress = 'Cocody, Abidjan',
  String customerName = 'Client Test',
  double totalAmount = 5000,
  String status = 'pending',
  String? createdAt,
}) {
  return Delivery(
    id: id,
    reference: 'REF-$id',
    pharmacyName: pharmacyName,
    pharmacyAddress: 'Adresse pharmacie',
    customerName: customerName,
    deliveryAddress: deliveryAddress,
    totalAmount: totalAmount,
    status: status,
    createdAt: createdAt ?? '2024-01-15T10:30:00Z',
  );
}

Widget buildTestWidget({
  List<Delivery> pending = const [],
  List<Delivery> active = const [],
  List<Delivery> history = const [],
}) {
  return ProviderScope(
    overrides: [
      deliveriesProvider('pending').overrideWith((ref) => Future.value(pending)),
      deliveriesProvider('active').overrideWith((ref) => Future.value(active)),
      deliveriesProvider('history').overrideWith((ref) => Future.value(history)),
      ...commonWidgetTestOverrides(),
    ],
    child: MaterialApp(
      home: HeroControllerScope.none(child: const DeliveriesScreen()),
    ),
  );
}

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

  group('DeliveriesScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Mes Courses'), findsOneWidget);
    });

    testWidgets('shows three tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Disponibles'), findsOneWidget);
      expect(find.text('En Cours'), findsOneWidget);
      expect(find.text('Terminées'), findsOneWidget);
    });

    testWidgets('shows Multi batch button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Multi'), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Rechercher #REF, Pharmacie...'), findsOneWidget);
    });

    testWidgets('shows empty state on no deliveries', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Aucune course trouvée'), findsOneWidget);
    });

    testWidgets('shows delivery cards on pending tab', (tester) async {
      final pending = [
        _delivery(id: 1, pharmacyName: 'Pharma Alpha', totalAmount: 8000),
        _delivery(id: 2, pharmacyName: 'Pharma Beta', totalAmount: 3500),
      ];
      await tester.pumpWidget(buildTestWidget(pending: pending));
      await tester.pumpAndSettle();
      expect(find.text('Pharma Alpha'), findsOneWidget);
      expect(find.text('Pharma Beta'), findsOneWidget);
    });

    testWidgets('shows delivery address', (tester) async {
      await tester.pumpWidget(buildTestWidget(pending: [
        _delivery(deliveryAddress: 'Plateau, Abidjan'),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Plateau, Abidjan'), findsOneWidget);
    });

    testWidgets('shows delivery amount', (tester) async {
      await tester.pumpWidget(buildTestWidget(pending: [
        _delivery(totalAmount: 7500),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('7500.0 FCFA'), findsOneWidget);
    });

    testWidgets('shows delivery id badge', (tester) async {
      await tester.pumpWidget(buildTestWidget(pending: [
        _delivery(id: 42),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('tab switching works', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        active: [_delivery(id: 1, pharmacyName: 'Active Pharma', status: 'active')],
      ));
      await tester.pumpAndSettle();

      // Tap "En Cours" tab
      await tester.tap(find.text('En Cours'));
      await tester.pumpAndSettle();

      expect(find.text('Active Pharma'), findsOneWidget);
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
            deliveriesProvider('active').overrideWith((ref) => Future.value(<Delivery>[])),
            deliveriesProvider('history').overrideWith((ref) => Future.value(<Delivery>[])),
            ...commonWidgetTestOverrides(),
          ],
          child: MaterialApp(
            home: HeroControllerScope.none(child: const DeliveriesScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      await tester.pumpAndSettle();
    });
  });
}
