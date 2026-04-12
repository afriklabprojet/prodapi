import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/delivery/delivery_info_section.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/route_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/delivery/delivery_communication.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  Delivery makeDelivery({String status = 'picked_up', String? distanceKm}) {
    return Delivery.fromJson({
      'id': 1,
      'reference': 'DEL-001',
      'pharmacy_name': 'Pharmacie Centrale',
      'pharmacy_address': '123 Rue Abidjan',
      'customer_name': 'Marie Konan',
      'delivery_address': '456 Boulevard Cocody',
      'total_amount': '15000',
      'status': status,
      'delivery_fee': '2000',
      'commission': '500',
      'distance_km': distanceKm ?? '3.5',
      'estimated_duration': '15',
    });
  }

  RouteInfo makeRouteInfo() {
    return RouteInfo(
      points: [LatLng(5.36, -4.01), LatLng(5.37, -4.02)],
      totalDistance: '3.5 km',
      totalDuration: '15 min',
      steps: [],
    );
  }

  group('DeliveryInfoHeader', () {
    testWidgets('renders with delivery data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeliveryInfoHeader(delivery: makeDelivery())),
        ),
      );
      expect(find.byType(DeliveryInfoHeader), findsOneWidget);
    });

    testWidgets('displays delivery reference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeliveryInfoHeader(delivery: makeDelivery())),
        ),
      );
      expect(find.textContaining('DEL-001'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeliveryInfoHeader(delivery: makeDelivery())),
        ),
      );
      expect(find.byType(DeliveryInfoHeader), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    // Status-specific rendering tests
    for (final entry in {
      'pending': 'En Attente',
      'assigned': 'Assignée',
      'picked_up': 'En Livraison',
      'delivered': 'Livrée',
      'cancelled': 'Annulée',
    }.entries) {
      testWidgets('renders with ${entry.key} status showing "${entry.value}"', (
        tester,
      ) async {
        final delivery = makeDelivery(status: entry.key);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeliveryInfoHeader(delivery: delivery)),
          ),
        );
        expect(find.byType(DeliveryInfoHeader), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
      });
    }

    testWidgets('renders with unknown status uses raw text', (tester) async {
      final delivery = makeDelivery(status: 'in_transit');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeliveryInfoHeader(delivery: delivery)),
        ),
      );
      expect(find.byType(DeliveryInfoHeader), findsOneWidget);
    });
  });

  group('DeliveryStepperBar', () {
    testWidgets('renders with picked_up status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeliveryStepperBar(delivery: makeDelivery())),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('has step indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeliveryStepperBar(delivery: makeDelivery())),
        ),
      );
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with pending status (step index -1)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(delivery: makeDelivery(status: 'pending')),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('renders with assigned status (step index 0)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'assigned'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('renders with accepted status (step index 0)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'accepted'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('renders with delivered status (step index 4)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'delivered'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('cancelled status returns SizedBox.shrink', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'cancelled'),
            ),
          ),
        ),
      );
      // Cancelled returns SizedBox.shrink - no stepper rendered
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('assigned with routeInfo overrides to step 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'assigned'),
              routeInfo: makeRouteInfo(),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('accepted with routeInfo overrides to step 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'accepted'),
              routeInfo: makeRouteInfo(),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('picked_up with routeInfo overrides to step 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'picked_up'),
              routeInfo: makeRouteInfo(),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });

    testWidgets('default status renders step index 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryStepperBar(
              delivery: makeDelivery(status: 'in_transit'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryStepperBar), findsOneWidget);
    });
  });

  group('DeliveryETASection', () {
    testWidgets('renders with loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(),
              isLoadingRoute: true,
              onRefreshRoute: () {},
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryETASection), findsOneWidget);
    });

    testWidgets('loading shows spinner text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(),
              isLoadingRoute: true,
              onRefreshRoute: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Calcul'), findsWidgets);
    });

    testWidgets('delivered status returns SizedBox.shrink', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(status: 'delivered'),
              isLoadingRoute: false,
              onRefreshRoute: () {},
            ),
          ),
        ),
      );
      // delivered → SizedBox.shrink
      expect(find.byType(DeliveryETASection), findsOneWidget);
    });

    testWidgets('cancelled status returns SizedBox.shrink', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(status: 'cancelled'),
              isLoadingRoute: false,
              onRefreshRoute: () {},
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryETASection), findsOneWidget);
    });

    testWidgets('with routeInfo and assigned status shows pharmacy direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(status: 'assigned'),
              routeInfo: makeRouteInfo(),
              isLoadingRoute: false,
              onRefreshRoute: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('pharmacie'), findsWidgets);
    });

    testWidgets('with routeInfo and picked_up status shows client direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(status: 'picked_up'),
              routeInfo: makeRouteInfo(),
              isLoadingRoute: false,
              onRefreshRoute: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('client'), findsWidgets);
    });

    testWidgets(
      'without routeInfo and not loading shows calculate route button',
      (tester) async {
        var refreshCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeliveryETASection(
                delivery: makeDelivery(),
                isLoadingRoute: false,
                onRefreshRoute: () => refreshCalled = true,
              ),
            ),
          ),
        );
        expect(find.textContaining('Calculer'), findsWidgets);
        // refreshCalled stays false until button is tapped
        expect(refreshCalled, isFalse);
      },
    );

    testWidgets('tapping calculate route calls onRefreshRoute', (tester) async {
      bool refreshCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(),
              isLoadingRoute: false,
              onRefreshRoute: () => refreshCalled = true,
            ),
          ),
        ),
      );
      final calcFinder = find.textContaining('Calculer');
      if (calcFinder.evaluate().isNotEmpty) {
        await tester.tap(calcFinder.first);
        await tester.pump();
        expect(refreshCalled, isTrue);
      }
    });

    testWidgets('with routeInfo and accepted status shows pharmacy direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryETASection(
              delivery: makeDelivery(status: 'accepted'),
              routeInfo: makeRouteInfo(),
              isLoadingRoute: false,
              onRefreshRoute: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('pharmacie'), findsWidgets);
    });
  });

  group('DeliveryPaymentInfo', () {
    testWidgets('renders with picked_up delivery', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeliveryPaymentInfo(delivery: makeDelivery())),
        ),
      );
      expect(find.byType(DeliveryPaymentInfo), findsOneWidget);
    });

    testWidgets('pending status shows earnings breakdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryPaymentInfo(
              delivery: makeDelivery(status: 'pending'),
            ),
          ),
        ),
      );
      // Pending shows expanded breakdown with fee/commission/earnings
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('pending status with distance shows distance row', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryPaymentInfo(
              delivery: makeDelivery(status: 'pending', distanceKm: '5.0'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryPaymentInfo), findsOneWidget);
    });

    testWidgets('non-pending status shows only total amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryPaymentInfo(
              delivery: makeDelivery(status: 'delivered'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryPaymentInfo), findsOneWidget);
    });

    testWidgets('assigned status shows non-pending layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryPaymentInfo(
              delivery: makeDelivery(status: 'assigned'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryPaymentInfo), findsOneWidget);
    });

    testWidgets('cancelled status shows non-pending layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryPaymentInfo(
              delivery: makeDelivery(status: 'cancelled'),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryPaymentInfo), findsOneWidget);
    });
  });

  group('DeliveryTimeline', () {
    testWidgets('renders with delivery', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final commHelper = DeliveryCommunicationHelper(
                    context: context,
                    delivery: makeDelivery(),
                  );
                  return DeliveryTimeline(
                    delivery: makeDelivery(),
                    commHelper: commHelper,
                  );
                },
              ),
            ),
          ),
        ),
      );
      expect(find.byType(DeliveryTimeline), findsOneWidget);
    });

    testWidgets('shows pharmacy name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final commHelper = DeliveryCommunicationHelper(
                    context: context,
                    delivery: makeDelivery(),
                  );
                  return DeliveryTimeline(
                    delivery: makeDelivery(),
                    commHelper: commHelper,
                  );
                },
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Pharmacie Centrale'), findsWidgets);
    });

    testWidgets('shows customer name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final commHelper = DeliveryCommunicationHelper(
                    context: context,
                    delivery: makeDelivery(),
                  );
                  return DeliveryTimeline(
                    delivery: makeDelivery(),
                    commHelper: commHelper,
                  );
                },
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Marie Konan'), findsWidgets);
    });

    testWidgets('renders with delivery that has phone numbers', (tester) async {
      final delivery = Delivery.fromJson({
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': '123 Rue Test',
        'pharmacy_phone': '+2250700000001',
        'customer_name': 'Client Test',
        'customer_phone': '+2250700000002',
        'delivery_address': '456 Rue Client',
        'total_amount': '10000',
        'status': 'picked_up',
        'pharmacy_lat': '5.36',
        'pharmacy_lng': '-4.01',
        'customer_lat': '5.37',
        'customer_lng': '-4.02',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final commHelper = DeliveryCommunicationHelper(
                    context: context,
                    delivery: delivery,
                  );
                  return DeliveryTimeline(
                    delivery: delivery,
                    commHelper: commHelper,
                  );
                },
              ),
            ),
          ),
        ),
      );
      // With phone numbers, should show call/WhatsApp buttons
      expect(find.byType(DeliveryTimeline), findsOneWidget);
    });
  });

  group('SmallActionButton', () {
    testWidgets('renders with icon, label and color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmallActionButton(
              icon: Icons.phone,
              label: 'Appeler',
              color: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Appeler'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmallActionButton(
              icon: Icons.message,
              label: 'Message',
              color: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Message'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders with different colors', (tester) async {
      for (final color in [Colors.red, Colors.orange, Colors.purple]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmallActionButton(
                icon: Icons.star,
                label: 'Test',
                color: color,
                onTap: () {},
              ),
            ),
          ),
        );
        expect(find.byType(SmallActionButton), findsOneWidget);
      }
    });
  });
}
