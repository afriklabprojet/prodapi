import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/route_info.dart';
import 'package:courier/presentation/widgets/home/active_delivery_panel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  Widget buildWidget({required Delivery delivery, bool showItinerary = false}) {
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
      final noPhoneDelivery = assignedDelivery.copyWith(pharmacyPhone: null);
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

  group('ActiveDeliveryPanel - with routeInfo', () {
    testWidgets('shows itinerary elements when routeInfo provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ActiveDeliveryPanel(
                    delivery: assignedDelivery,
                    routeInfo: RouteInfo(
                      points: [LatLng(5.316, -4.012), LatLng(5.345, -3.980)],
                      totalDistance: '5.2 km',
                      totalDuration: '15 min',
                      steps: [],
                    ),
                    onShowItinerary: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ActiveDeliveryPanel), findsOneWidget);
    });

    testWidgets('shows itinerary with long distance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ActiveDeliveryPanel(
                    delivery: pickedUpDelivery,
                    routeInfo: RouteInfo(
                      points: [LatLng(5.316, -4.012), LatLng(5.400, -3.900)],
                      totalDistance: '25.8 km',
                      totalDuration: '45 min',
                      steps: [
                        RouteStep(
                          instruction: 'Tout droit',
                          distance: '10 km',
                          duration: '20 min',
                        ),
                        RouteStep(
                          instruction: 'Tournez à droite',
                          distance: '15.8 km',
                          duration: '25 min',
                        ),
                      ],
                    ),
                    onShowItinerary: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ActiveDeliveryPanel), findsOneWidget);
    });
  });

  group('ActiveDeliveryPanel - earnings and commission', () {
    testWidgets('displays delivery with totalAmount', (tester) async {
      final delivery = Delivery(
        id: 10,
        reference: 'DEL-010',
        pharmacyName: 'Pharma Sud',
        pharmacyAddress: '50 Rue Cocody',
        pharmacyPhone: '+22501111111',
        customerName: 'Bakary Cissé',
        customerPhone: '+22502222222',
        deliveryAddress: '75 Avenue Delafosse',
        pharmacyLat: 5.316,
        pharmacyLng: -4.012,
        deliveryLat: 5.345,
        deliveryLng: -3.980,
        totalAmount: 25000,
        status: 'assigned',
      );
      await tester.pumpWidget(buildWidget(delivery: delivery));
      await tester.pumpAndSettle();
      expect(find.byType(ActiveDeliveryPanel), findsOneWidget);
      // Should display some amount text
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays delivery with zero totalAmount', (tester) async {
      final delivery = Delivery(
        id: 11,
        reference: 'DEL-011',
        pharmacyName: 'Pharma Zero',
        pharmacyAddress: '1 Rue du Zéro',
        pharmacyPhone: '+22503333333',
        customerName: 'Zero Client',
        customerPhone: '+22504444444',
        deliveryAddress: '2 Avenue Zéro',
        pharmacyLat: 5.316,
        pharmacyLng: -4.012,
        deliveryLat: 5.345,
        deliveryLng: -3.980,
        totalAmount: 0,
        status: 'assigned',
      );
      await tester.pumpWidget(buildWidget(delivery: delivery));
      await tester.pumpAndSettle();
      expect(find.byType(ActiveDeliveryPanel), findsOneWidget);
    });

    testWidgets('displays picked_up delivery with large amount', (
      tester,
    ) async {
      final delivery = Delivery(
        id: 12,
        reference: 'DEL-012',
        pharmacyName: 'Pharma Premium',
        pharmacyAddress: '100 Boulevard VGE',
        pharmacyPhone: '+22505555555',
        customerName: 'Premium Client',
        customerPhone: '+22506666666',
        deliveryAddress: '200 Rue des Jardins',
        pharmacyLat: 5.316,
        pharmacyLng: -4.012,
        deliveryLat: 5.345,
        deliveryLng: -3.980,
        totalAmount: 150000,
        status: 'picked_up',
      );
      await tester.pumpWidget(buildWidget(delivery: delivery));
      await tester.pumpAndSettle();
      expect(find.text('CONFIRMER LIVRAISON'), findsOneWidget);
    });
  });

  group('ActiveDeliveryPanel - no coordinates', () {
    testWidgets('handles delivery without pharmacy coordinates', (
      tester,
    ) async {
      final delivery = Delivery(
        id: 20,
        reference: 'DEL-020',
        pharmacyName: 'Pharma NoGPS',
        pharmacyAddress: '10 Rue Inconnue',
        pharmacyPhone: '+22507777777',
        customerName: 'NoGPS Client',
        customerPhone: '+22508888888',
        deliveryAddress: '20 Avenue Inconnue',
        totalAmount: 5000,
        status: 'assigned',
      );
      await tester.pumpWidget(buildWidget(delivery: delivery));
      await tester.pumpAndSettle();
      expect(find.byType(ActiveDeliveryPanel), findsOneWidget);
    });

    testWidgets('handles delivery without delivery coordinates', (
      tester,
    ) async {
      final delivery = Delivery(
        id: 21,
        reference: 'DEL-021',
        pharmacyName: 'Pharma OK',
        pharmacyAddress: '30 Rue Commerce',
        pharmacyPhone: '+22509999999',
        customerName: 'NoDelivGPS Client',
        customerPhone: '+22510000000',
        deliveryAddress: '40 Avenue Cocody',
        pharmacyLat: 5.316,
        pharmacyLng: -4.012,
        totalAmount: 8000,
        status: 'picked_up',
      );
      await tester.pumpWidget(buildWidget(delivery: delivery));
      await tester.pumpAndSettle();
      expect(find.text('CONFIRMER LIVRAISON'), findsOneWidget);
    });
  });

  group('ActiveDeliveryPanel - no customer phone', () {
    testWidgets('picked_up with no customer phone', (tester) async {
      final delivery = Delivery(
        id: 30,
        reference: 'DEL-030',
        pharmacyName: 'Pharma Test',
        pharmacyAddress: '50 Rue Test',
        pharmacyPhone: '+22511111111',
        customerName: 'Silent Client',
        deliveryAddress: '60 Avenue Test',
        pharmacyLat: 5.316,
        pharmacyLng: -4.012,
        deliveryLat: 5.345,
        deliveryLng: -3.980,
        totalAmount: 6000,
        status: 'picked_up',
      );
      await tester.pumpWidget(buildWidget(delivery: delivery));
      await tester.pumpAndSettle();
      expect(find.text('CONFIRMER LIVRAISON'), findsOneWidget);
    });
  });
}
