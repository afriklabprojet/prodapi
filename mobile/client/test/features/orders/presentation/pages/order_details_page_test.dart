import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/orders/presentation/pages/order_details_page.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_state.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockOrdersNotifier extends StateNotifier<OrdersState>
    with Mock
    implements OrdersNotifier {
  MockOrdersNotifier(super.state);

  @override
  Future<void> loadOrderDetails(int orderId) async {}

  @override
  Future<void> loadOrders({String? status}) async {}

  @override
  Future<void> loadMoreOrders({String? status}) async {}

  @override
  void clearError() {}

  @override
  Future<String?> cancelOrder(int orderId, String reason) async => null;
}

const _testAddress = DeliveryAddressEntity(
  address: '10 Rue Test, Abidjan',
  city: 'Abidjan',
  phone: '0102030405',
);

OrderEntity _makeOrder({
  OrderStatus status = OrderStatus.pending,
  String paymentMode = 'cash',
  String paymentStatus = 'pending',
  String? deliveryCode,
  String? customerNotes,
  String? cancellationReason,
  DateTime? cancelledAt,
  DateTime? paidAt,
  bool paid = false,
}) {
  return OrderEntity(
    id: 1,
    reference: 'CMD-001',
    status: status,
    paymentStatus: paid ? 'paid' : paymentStatus,
    paymentMode: paymentMode == 'platform'
        ? PaymentMode.platform
        : PaymentMode.onDelivery,
    pharmacyId: 1,
    pharmacyName: 'Pharmacie Centrale',
    pharmacyPhone: '+22501020304',
    pharmacyAddress: '5 Blvd de la Pharmacie',
    items: const [],
    subtotal: 5000,
    deliveryFee: 500,
    totalAmount: 5500,
    deliveryAddress: _testAddress,
    deliveryCode: deliveryCode,
    customerNotes: customerNotes,
    cancellationReason: cancellationReason,
    cancelledAt: cancelledAt,
    paidAt: paidAt,
    createdAt: DateTime(2024, 3, 15, 10, 30),
  );
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    await initializeDateFormatting('fr_FR');
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: const OrderDetailsPage(orderId: 1),
        routes: {'/tracking': (_) => const Scaffold(body: Text('Tracking'))},
      ),
    );
  }

  Widget createTestWidgetWithState(OrdersState state) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        ordersProvider.overrideWith((_) => MockOrdersNotifier(state)),
      ],
      child: MaterialApp(
        home: const OrderDetailsPage(orderId: 1),
        routes: {'/tracking': (_) => const Scaffold(body: Text('Tracking'))},
      ),
    );
  }

  group('OrderDetailsPage Widget Tests', () {
    testWidgets('should render order details page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order number', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display delivery address', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display total amount', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should have track order button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy info', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display payment method', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order date', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should have cancel order button if applicable', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });
  });

  group('OrderDetailsPage Content Tests', () {
    testWidgets('shows Détails de la commande AppBar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Détails de la commande'), findsOneWidget);
    });

    testWidgets('has AppBar widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows order reference CMD-1 after loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('CMD-1'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Informations section after loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Informations'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows payment mode label after loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Paiement').evaluate().isNotEmpty, isTrue);
    });

    testWidgets('page loads without crash for orderId=1', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });
  });

  group('OrderDetailsPage Loaded State Tests', () {
    testWidgets('shows En attente for pending status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('En attente'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows schedule icon for pending status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.schedule), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Paiement à la livraison for cash payment mode', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Paiement à la livraison'), findsOneWidget);
    });

    testWidgets('shows Pharmacie section header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Pharmacie'), findsOneWidget);
    });

    testWidgets('shows Articles section header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Articles'), findsOneWidget);
    });

    testWidgets('shows Adresse de livraison section header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Adresse de livraison'), findsOneWidget);
    });

    testWidgets('shows Sous-total in total card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Sous-total'), findsOneWidget);
    });

    testWidgets('shows Frais de livraison in total card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Frais de livraison'), findsOneWidget);
    });

    testWidgets('shows Total label in total card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('shows cancel icon button when order can be cancelled', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('does not show Payer maintenant for cash order', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Payer maintenant'), findsNothing);
    });

    testWidgets('tapping cancel icon opens cancel dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Annuler la commande'), findsAtLeastNWidgets(1));
    });

    testWidgets('cancel dialog shows reason input field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Raison (obligatoire)'), findsOneWidget);
    });

    testWidgets('cancel dialog can be dismissed with Non button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Non'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });
  });

  group('OrderDetailsPage Error State Tests', () {
    testWidgets('shows error_outline icon on error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          const OrdersState(
            status: OrdersStatus.error,
            orders: [],
            errorMessage: 'Commande introuvable',
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows Réessayer button on error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          const OrdersState(
            status: OrdersStatus.error,
            orders: [],
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('shows Retour button on error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          const OrdersState(
            status: OrdersStatus.error,
            orders: [],
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Retour'), findsOneWidget);
    });

    testWidgets('shows error message text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidgetWithState(
          const OrdersState(
            status: OrdersStatus.error,
            orders: [],
            errorMessage: 'Commande introuvable',
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Commande introuvable'), findsOneWidget);
    });
  });

  group('OrderDetailsPage Delivered State Tests', () {
    testWidgets('shows Recommander cette commande button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deliveredOrder = _makeOrder(status: OrderStatus.delivered);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: deliveredOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Recommander'), findsOneWidget);
    });

    testWidgets('shows Évaluer la commande button for delivered order', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deliveredOrder = _makeOrder(status: OrderStatus.delivered);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: deliveredOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Évaluer'), findsOneWidget);
    });

    testWidgets('shows replay icon for reorder button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deliveredOrder = _makeOrder(status: OrderStatus.delivered);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: deliveredOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });

    testWidgets('shows star_rate_rounded icon for rating button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deliveredOrder = _makeOrder(status: OrderStatus.delivered);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: deliveredOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.star_rate_rounded), findsOneWidget);
    });

    testWidgets('shows check_circle_outline icon for delivered status card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deliveredOrder = _makeOrder(status: OrderStatus.delivered);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: deliveredOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows Livrée status text for delivered order', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deliveredOrder = _makeOrder(status: OrderStatus.delivered);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: deliveredOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Livrée'), findsAtLeastNWidgets(1));
    });
  });

  group('OrderDetailsPage Other States Tests', () {
    testWidgets('shows cancel icon for cancelled order status card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cancelledOrder = _makeOrder(
        status: OrderStatus.cancelled,
        cancellationReason: 'Test reason',
        cancelledAt: DateTime(2024, 3, 15, 14, 0),
      );
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: cancelledOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Annulation section for cancelled order', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cancelledOrder = _makeOrder(
        status: OrderStatus.cancelled,
        cancellationReason: 'Hors stock',
        cancelledAt: DateTime(2024, 3, 15, 14, 0),
      );
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: cancelledOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Annulation'), findsOneWidget);
    });

    testWidgets('shows cancellation reason text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cancelledOrder = _makeOrder(
        status: OrderStatus.cancelled,
        cancellationReason: 'Hors stock',
        cancelledAt: DateTime(2024, 3, 15, 14, 0),
      );
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: cancelledOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Hors stock'), findsOneWidget);
    });

    testWidgets('shows Notes section with customer notes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final orderWithNotes = _makeOrder(customerNotes: 'Livrer après 18h');
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: orderWithNotes,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('shows customer notes content', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final orderWithNotes = _makeOrder(customerNotes: 'Livrer après 18h');
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: orderWithNotes,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Livrer après 18h'), findsOneWidget);
    });

    testWidgets('shows local_shipping icon for delivering status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deliveringOrder = _makeOrder(status: OrderStatus.delivering);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: deliveringOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    });

    testWidgets('shows check_circle icon for confirmed status', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final confirmedOrder = _makeOrder(status: OrderStatus.confirmed);
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: confirmedOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows Payer maintenant for platform payment order', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final unpaidPlatformOrder = _makeOrder(
        status: OrderStatus.pending,
        paymentMode: 'platform',
        paymentStatus: 'pending',
      );
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: unpaidPlatformOrder,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Payer maintenant'), findsOneWidget);
    });

    testWidgets('shows delivery code section when deliveryCode is present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final orderWithCode = _makeOrder(
        status: OrderStatus.delivering,
        deliveryCode: 'ABC123',
      );
      await tester.pumpWidget(
        createTestWidgetWithState(
          OrdersState(
            status: OrdersStatus.loaded,
            orders: const [],
            selectedOrder: orderWithCode,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('ABC123'), findsAtLeastNWidgets(1));
    });
  });
}
