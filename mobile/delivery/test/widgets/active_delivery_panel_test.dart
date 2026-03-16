import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/presentation/widgets/home/active_delivery_panel.dart';

void main() {
  final assignedDelivery = Delivery(
    id: 1,
    reference: 'DEL-001',
    pharmacyName: 'Pharma Abidjan',
    pharmacyAddress: '10 Rue du Commerce',
    pharmacyPhone: '+22501020304',
    customerName: 'Koné Ali',
    customerPhone: '+22505060708',
    deliveryAddress: '25 Avenue Houdaille',
    pharmacyLat: 5.316,
    pharmacyLng: -4.012,
    deliveryLat: 5.345,
    deliveryLng: -3.980,
    totalAmount: 3500,
    status: 'assigned',
  );

  final pickedUpDelivery = assignedDelivery.copyWith(status: 'picked_up');

  Widget buildWidget({
    required Delivery delivery,
    bool showItinerary = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ActiveDeliveryPanel(
                delivery: delivery,
                routeInfo: null,
                onShowItinerary: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('ActiveDeliveryPanel - assigned status', () {
    testWidgets('displays pharmacy status text', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.text('EN ROUTE VERS LA PHARMACIE'), findsOneWidget);
    });

    testWidgets('displays CONFIRMER RÉCUPÉRATION button', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMER RÉCUPÉRATION'), findsOneWidget);
    });

    testWidgets('displays pharmacy name', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.text('Pharma Abidjan'), findsOneWidget);
    });

    testWidgets('displays customer name', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.text('Koné Ali'), findsOneWidget);
    });

    testWidgets('displays phone icon when phone available', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('displays chat icon', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
    });

    testWidgets('displays navigation icon', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('displays route indicator icons', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.circle), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });
  });

  group('ActiveDeliveryPanel - picked_up status', () {
    testWidgets('displays client status text', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: pickedUpDelivery));
      await tester.pumpAndSettle();

      expect(find.text('EN ROUTE VERS LE CLIENT'), findsOneWidget);
    });

    testWidgets('displays CONFIRMER LIVRAISON button', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: pickedUpDelivery));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMER LIVRAISON'), findsOneWidget);
    });

    testWidgets('displays customer phone icon', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: pickedUpDelivery));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.phone), findsOneWidget);
    });
  });

  group('ActiveDeliveryPanel - no phone', () {
    testWidgets('hides phone icon when no phone available', (tester) async {
      final noPhoneDelivery = assignedDelivery.copyWith(
        pharmacyPhone: null,
      );
      await tester.pumpWidget(buildWidget(delivery: noPhoneDelivery));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.phone), findsNothing);
    });
  });

  group('ActiveDeliveryPanel - chat bottom sheet', () {
    testWidgets('opens chat options on chat icon tap', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chat_bubble));
      await tester.pumpAndSettle();

      expect(find.text('Discuter avec...'), findsOneWidget);
      expect(find.text('Pharmacie'), findsOneWidget);
      expect(find.text('Client'), findsOneWidget);
    });

    testWidgets('shows pharmacy name in chat options', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chat_bubble));
      await tester.pumpAndSettle();

      expect(find.text('Pharma Abidjan'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows customer name in chat options', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chat_bubble));
      await tester.pumpAndSettle();

      expect(find.text('Koné Ali'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows pharmacy icon for pharmacy', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chat_bubble));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_pharmacy), findsOneWidget);
    });

    testWidgets('shows person icon for client', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chat_bubble));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('ActiveDeliveryPanel - layout', () {
    testWidgets('renders Positioned widgets', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.byType(Positioned), findsAtLeastNWidgets(1));
    });

    testWidgets('renders ElevatedButton for action', (tester) async {
      await tester.pumpWidget(buildWidget(delivery: assignedDelivery));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
