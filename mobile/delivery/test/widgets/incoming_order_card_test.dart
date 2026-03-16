import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/home/incoming_order_card.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/delivery.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testDelivery = Delivery(
    id: 1,
    reference: '#DEL-001',
    pharmacyName: 'Pharmacie Centrale',
    pharmacyAddress: '123 Rue de la Paix',
    customerName: 'Jean Dupont',
    deliveryAddress: '456 Avenue de la Liberté, Abidjan',
    totalAmount: 2500,
    status: 'pending',
  );

  Widget buildCard({List<Delivery>? deliveries}) {
    final dels = deliveries ?? [testDelivery];
    return ProviderScope(
      overrides: [
        deliveriesProvider.overrideWith(
          (ref, status) => Future.value(dels),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: const [
              IncomingOrderCard(),
            ],
          ),
        ),
      ),
    );
  }

  group('IncomingOrderCard', () {
    testWidgets('displays NOUVELLE COURSE header', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('NOUVELLE COURSE'), findsOneWidget);
    });

    testWidgets('displays Commande prête text', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Commande prête !'), findsOneWidget);
    });

    testWidgets('displays delivery amount', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('2500.0 F'), findsOneWidget);
    });

    testWidgets('displays pharmacy name', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Pharmacie Centrale'), findsOneWidget);
    });

    testWidgets('displays delivery address', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('456 Avenue de la Liberté, Abidjan'), findsOneWidget);
    });

    testWidgets('displays ACCEPTER button', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('ACCEPTER'), findsOneWidget);
    });

    testWidgets('displays IGNORER button', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('IGNORER'), findsOneWidget);
    });

    testWidgets('displays notification icon', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('displays check circle icon', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays store and location icons', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('shows nothing when no pending deliveries', (tester) async {
      await tester.pumpWidget(buildCard(deliveries: []));
      await tester.pumpAndSettle();

      expect(find.text('NOUVELLE COURSE'), findsNothing);
      expect(find.text('ACCEPTER'), findsNothing);
    });
  });
}
