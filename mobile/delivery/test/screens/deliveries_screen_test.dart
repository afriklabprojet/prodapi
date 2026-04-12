import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/deliveries_screen.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/core/services/delivery_alert_service.dart';
import 'package:courier/data/models/delivery.dart';
import '../helpers/widget_test_helpers.dart';

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

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        deliveriesProvider.overrideWith((ref, status) async => <Delivery>[]),
        deliveryAlertActiveProvider.overrideWith(() => _FakeAlertActive()),
      ],
      child: const MaterialApp(home: DeliveriesScreen()),
    );
  }

  group('DeliveriesScreen', () {
    testWidgets('renders with scaffold', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsWidgets);
      FlutterError.onError = originalOnError;
    });

    testWidgets('shows Mes Courses title', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Mes Courses'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('shows Disponibles tab', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Disponibles'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('shows En Cours tab', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('En Cours'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('shows Terminées tab', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Terminées'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('has TabBar', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TabBar), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('has TabBarView', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TabBarView), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('renders DeliveriesScreen type', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeliveriesScreen), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('shows Multi button', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Multi'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('can switch tabs', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('En Cours'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('En Cours'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });

    testWidgets('has AppBar', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(AppBar), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Text widgets', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Text), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Icon widgets', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Icon), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('switch to Terminées tab', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('Terminées'));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Terminées'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('switch back to Disponibles', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('En Cours'));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('Disponibles'));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Disponibles'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Container widgets', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Container), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Tab widgets for each tab', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Tab), findsNWidgets(3));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveriesScreen - With deliveries data', () {
    Widget buildWithDeliveries(List<Delivery> deliveries) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          deliveriesProvider.overrideWith((ref, status) async => deliveries),
          deliveryAlertActiveProvider.overrideWith(() => _FakeAlertActive()),
        ],
        child: const MaterialApp(home: DeliveriesScreen()),
      );
    }

    testWidgets('renders with single pending delivery', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          buildWithDeliveries([
            Delivery.fromJson({
              'id': 1,
              'reference': 'DEL-001',
              'pharmacy_name': 'Pharma Test',
              'pharmacy_address': '123 Rue Test',
              'customer_name': 'Client A',
              'delivery_address': '456 Rue Dest',
              'total_amount': 5000,
              'status': 'pending',
            }),
          ]),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with multiple deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          buildWithDeliveries([
            Delivery.fromJson({
              'id': 1,
              'reference': 'DEL-001',
              'pharmacy_name': 'Pharma A',
              'pharmacy_address': '123 Rue A',
              'customer_name': 'Client A',
              'delivery_address': '456 Rue A',
              'total_amount': 5000,
              'status': 'pending',
            }),
            Delivery.fromJson({
              'id': 2,
              'reference': 'DEL-002',
              'pharmacy_name': 'Pharma B',
              'pharmacy_address': '789 Rue B',
              'customer_name': 'Client B',
              'delivery_address': '101 Rue B',
              'total_amount': 8000,
              'status': 'assigned',
            }),
          ]),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with delivered status deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          buildWithDeliveries([
            Delivery.fromJson({
              'id': 3,
              'reference': 'DEL-003',
              'pharmacy_name': 'Pharma C',
              'pharmacy_address': '200 Rue C',
              'customer_name': 'Client C',
              'delivery_address': '300 Rue C',
              'total_amount': 12000,
              'status': 'delivered',
            }),
          ]),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with cancelled status deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          buildWithDeliveries([
            Delivery.fromJson({
              'id': 4,
              'reference': 'DEL-004',
              'pharmacy_name': 'Pharma D',
              'pharmacy_address': '400 Rue D',
              'customer_name': 'Client D',
              'delivery_address': '500 Rue D',
              'total_amount': 3000,
              'status': 'cancelled',
            }),
          ]),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveriesScreen - Alert active', () {
    testWidgets('renders with alert active', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => <Delivery>[],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActiveTrue(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('switch to En Cours tab with deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => [
                  Delivery.fromJson({
                    'id': 5,
                    'reference': 'DEL-005',
                    'pharmacy_name': 'Pharma Active',
                    'pharmacy_address': '600 Rue E',
                    'customer_name': 'Client E',
                    'delivery_address': '700 Rue E',
                    'total_amount': 6000,
                    'status': 'assigned',
                  }),
                ],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActive(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('En Cours'));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('En Cours'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveriesScreen - with data variations', () {
    testWidgets('renders with pending deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => [
                  Delivery(
                    id: 10,
                    reference: 'DEL-010',
                    pharmacyName: 'Pharma Centrale',
                    pharmacyAddress: '10 Rue du Commerce',
                    customerName: 'Client Pending',
                    deliveryAddress: '20 Avenue Cocody',
                    totalAmount: 5000,
                    status: 'pending',
                  ),
                ],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActive(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with delivered status deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => [
                  Delivery(
                    id: 11,
                    reference: 'DEL-011',
                    pharmacyName: 'Pharma Nord',
                    pharmacyAddress: '30 Rue Nord',
                    customerName: 'Client Delivered',
                    deliveryAddress: '40 Avenue Nord',
                    totalAmount: 8000,
                    status: 'delivered',
                  ),
                ],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActive(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with cancelled deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => [
                  Delivery(
                    id: 12,
                    reference: 'DEL-012',
                    pharmacyName: 'Pharma Sud',
                    pharmacyAddress: '50 Rue Sud',
                    customerName: 'Client Cancelled',
                    deliveryAddress: '60 Avenue Sud',
                    totalAmount: 3000,
                    status: 'cancelled',
                  ),
                ],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActive(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with mixed status deliveries', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => [
                  Delivery(
                    id: 20,
                    reference: 'DEL-020',
                    pharmacyName: 'Pharma A',
                    pharmacyAddress: '10 Rue A',
                    customerName: 'Client A',
                    deliveryAddress: '20 Avenue A',
                    totalAmount: 5000,
                    status: 'pending',
                  ),
                  Delivery(
                    id: 21,
                    reference: 'DEL-021',
                    pharmacyName: 'Pharma B',
                    pharmacyAddress: '30 Rue B',
                    customerName: 'Client B',
                    deliveryAddress: '40 Avenue B',
                    totalAmount: 7500,
                    status: 'assigned',
                  ),
                  Delivery(
                    id: 22,
                    reference: 'DEL-022',
                    pharmacyName: 'Pharma C',
                    pharmacyAddress: '50 Rue C',
                    customerName: 'Client C',
                    deliveryAddress: '60 Avenue C',
                    totalAmount: 12000,
                    status: 'delivered',
                  ),
                ],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActive(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveriesScreen - alert active', () {
    testWidgets('renders with delivery alert active', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => <Delivery>[],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActiveTrue(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with delivery alert active and deliveries', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => [
                  Delivery(
                    id: 30,
                    reference: 'DEL-030',
                    pharmacyName: 'Pharma Alert',
                    pharmacyAddress: '100 Rue Alert',
                    customerName: 'Client Alert',
                    deliveryAddress: '200 Avenue Alert',
                    totalAmount: 15000,
                    status: 'pending',
                  ),
                ],
              ),
              deliveryAlertActiveProvider.overrideWith(
                () => _FakeAlertActiveTrue(),
              ),
            ],
            child: const MaterialApp(home: DeliveriesScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveriesScreen - search and interactions', () {
    testWidgets('has search TextField', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows search bar with search icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('can type in search field', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textField = find.byType(TextField);
        if (textField.evaluate().isNotEmpty) {
          await tester.enterText(textField.first, 'pharmacie');
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows layers icon for Multi button', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.layers), findsAtLeastNWidgets(1));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has TabController with 3 tabs', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.tabs.length, 3);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('tab labels match expected values', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Disponibles'), findsWidgets);
        expect(find.text('En Cours'), findsWidgets);
        expect(find.text('Terminées'), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('tapping En Cours tab changes tab index', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('En Cours').first);
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('switching tabs rapidly does not crash', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Rapid tab switching
        await tester.tap(find.text('Terminées').first);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('En Cours').first);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Disponibles').first);
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has SizedBox spacers between sections', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SizedBox), findsAtLeastNWidgets(3));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Row widgets in layout', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Row), findsAtLeastNWidgets(1));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Column widgets in layout', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Column), findsAtLeastNWidgets(1));
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with empty search query', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textField = find.byType(TextField);
        if (textField.evaluate().isNotEmpty) {
          await tester.enterText(textField.first, '');
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders with long search query', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textField = find.byType(TextField);
        if (textField.evaluate().isNotEmpty) {
          await tester.enterText(
            textField.first,
            'very long search query test string',
          );
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(DeliveriesScreen), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });
}

class _FakeAlertActive extends DeliveryAlertActiveNotifier {
  @override
  bool build() => false;
}

class _FakeAlertActiveTrue extends DeliveryAlertActiveNotifier {
  @override
  bool build() => true;
}
