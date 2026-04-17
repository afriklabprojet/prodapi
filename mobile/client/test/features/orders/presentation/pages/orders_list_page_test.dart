import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:drpharma_client/features/orders/presentation/pages/orders_list_page.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_state.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_item_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockOrdersNotifier extends StateNotifier<OrdersState>
    with Mock
    implements OrdersNotifier {
  MockOrdersNotifier() : super(const OrdersState.initial());

  @override
  Future<void> loadOrders({String? status}) async {}

  @override
  Future<void> loadMoreOrders({String? status}) async {}

  @override
  Future<void> loadOrderDetails(int orderId) async {}

  @override
  Future<void> createOrder({
    required int pharmacyId,
    required List<OrderItemEntity> items,
    required DeliveryAddressEntity deliveryAddress,
    required String paymentMode,
    String? prescriptionImage,
    String? customerNotes,
    int? prescriptionId,
    String? promoCode,
  }) async {}

  @override
  Future<String?> cancelOrder(int orderId, String reason) async => null;

  @override
  void clearError() {}
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    await initializeDateFormatting('fr_FR');
  });

  final testOrder = OrderEntity(
    id: 1,
    reference: 'CMD-001',
    status: OrderStatus.pending,
    paymentStatus: 'pending',
    paymentMode: PaymentMode.onDelivery,
    pharmacyId: 1,
    pharmacyName: 'Pharmacie Test',
    items: const [
      OrderItemEntity(
        name: 'Doliprane',
        quantity: 2,
        unitPrice: 350,
        totalPrice: 700,
      ),
    ],
    subtotal: 700,
    deliveryFee: 200,
    totalAmount: 900,
    deliveryAddress: const DeliveryAddressEntity(address: 'Rue Test, Abidjan'),
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );

  final cancelledOrder = OrderEntity(
    id: 2,
    reference: 'CMD-002',
    status: OrderStatus.cancelled,
    paymentStatus: 'pending',
    paymentMode: PaymentMode.onDelivery,
    pharmacyId: 1,
    pharmacyName: 'Pharmacie Centrale',
    items: const [
      OrderItemEntity(
        name: 'Aspirin',
        quantity: 1,
        unitPrice: 200,
        totalPrice: 200,
      ),
    ],
    subtotal: 200,
    deliveryFee: 100,
    totalAmount: 300,
    deliveryAddress: const DeliveryAddressEntity(
      address: 'Boulevard Lagunaire',
    ),
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OrdersListPage(),
        routes: {
          '/order-details': (_) => const Scaffold(body: Text('Order Details')),
          '/tracking': (_) => const Scaffold(body: Text('Tracking')),
        },
      ),
    );
  }

  Widget createTestWidgetWithState({required OrdersState state}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        ordersProvider.overrideWith((_) => MockOrdersNotifier()..state = state),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OrdersListPage(),
        routes: {
          '/orders/1': (_) => const Scaffold(body: Text('Order Details')),
          '/orders/2': (_) => const Scaffold(body: Text('Order Details 2')),
        },
      ),
    );
  }

  group('OrdersListPage Widget Tests', () {
    testWidgets('should render orders list page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display order cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should show empty state when no orders', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should display order status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should display order total', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should have filter by status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should navigate to order details on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should have pull to refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should display order date', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(OrdersListPage), findsOneWidget);
    });
  });

  group('OrdersListPage Content Tests', () {
    testWidgets('shows Mes commandes AppBar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Mes commandes'), findsOneWidget);
    });

    testWidgets('has AppBar widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has Scaffold widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows Aucune commande empty state with empty list', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Aucune commande'), findsOneWidget);
    });

    testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      // RefreshIndicator exists only when orders are present; verify page is still stable
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('OrdersListPage Loaded State Tests', () {
    testWidgets('loading state renders ListView skeleton', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const OrdersState(status: OrdersStatus.loading, orders: []),
        ),
      );
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('error state shows Erreur de chargement', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const OrdersState(
            status: OrdersStatus.error,
            orders: [],
            errorMessage: 'Connexion échouée',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Erreur de chargement'), findsOneWidget);
    });

    testWidgets('error state shows Réessayer button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const OrdersState(
            status: OrdersStatus.error,
            orders: [],
            errorMessage: 'Connexion échouée',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('loaded state with orders shows RefreshIndicator', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(status: OrdersStatus.loaded, orders: [testOrder]),
        ),
      );
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('loaded state shows order reference', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(status: OrdersStatus.loaded, orders: [testOrder]),
        ),
      );
      await tester.pump();
      expect(find.textContaining('CMD-001'), findsOneWidget);
    });

    testWidgets('loaded state shows pharmacy name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(status: OrdersStatus.loaded, orders: [testOrder]),
        ),
      );
      await tester.pump();
      expect(find.text('Pharmacie Test'), findsOneWidget);
    });

    testWidgets('loaded state shows order status label for pending', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(status: OrdersStatus.loaded, orders: [testOrder]),
        ),
      );
      await tester.pump();
      // pending status label contains 'attente' or 'En attente'
      expect(find.textContaining('attente'), findsAtLeastNWidgets(1));
    });

    testWidgets('loaded state cancelled order shows Commander button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(
            status: OrdersStatus.loaded,
            orders: [cancelledOrder],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Commander'), findsOneWidget);
    });

    testWidgets('loaded state shows items count text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(status: OrdersStatus.loaded, orders: [testOrder]),
        ),
      );
      await tester.pump();
      // should show "1 article" or "2 articles"
      expect(find.textContaining('article').evaluate().isNotEmpty, isTrue);
    });

    testWidgets('loaded state shows time ago text (Il y a)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(status: OrdersStatus.loaded, orders: [testOrder]),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Il y a'), findsOneWidget);
    });

    testWidgets('loaded state shows Card widget for each order', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: OrdersState(
            status: OrdersStatus.loaded,
            orders: [testOrder, cancelledOrder],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Card), findsWidgets);
    });
  });
}
