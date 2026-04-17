import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_item_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/features/orders/domain/repositories/orders_repository.dart';
import 'package:drpharma_client/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:drpharma_client/features/orders/domain/usecases/get_order_details_usecase.dart';
import 'package:drpharma_client/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:drpharma_client/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_state.dart';

import 'orders_notifier_test.mocks.dart';

@GenerateMocks([OrdersRepository])
void main() {
  late MockOrdersRepository mockRepository;
  late GetOrdersUseCase getOrdersUseCase;
  late GetOrderDetailsUseCase getOrderDetailsUseCase;
  late CreateOrderUseCase createOrderUseCase;
  late CancelOrderUseCase cancelOrderUseCase;
  late OrdersNotifier notifier;

  // Test data
  final testDeliveryAddress = DeliveryAddressEntity(
    address: '123 Rue Test, Cotonou',
    city: 'Cotonou',
    latitude: 6.3702,
    longitude: 2.3912,
    phone: '+22990000000',
  );

  final testOrderItem = OrderItemEntity(
    productId: 1,
    name: 'Doliprane 500mg',
    quantity: 2,
    unitPrice: 1500.0,
    totalPrice: 3000.0,
  );

  final testOrder = OrderEntity(
    id: 1,
    reference: 'ORD-001',
    status: OrderStatus.pending,
    paymentMode: PaymentMode.onDelivery,
    paymentStatus: 'pending',
    pharmacyId: 1,
    pharmacyName: 'Pharmacie du Centre',
    items: [testOrderItem],
    subtotal: 3000.0,
    deliveryFee: 500.0,
    totalAmount: 3500.0,
    deliveryAddress: testDeliveryAddress,
    createdAt: DateTime.now(),
  );

  final testOrders = [testOrder];

  setUp(() {
    mockRepository = MockOrdersRepository();
    getOrdersUseCase = GetOrdersUseCase(mockRepository);
    getOrderDetailsUseCase = GetOrderDetailsUseCase(mockRepository);
    createOrderUseCase = CreateOrderUseCase(mockRepository);
    cancelOrderUseCase = CancelOrderUseCase(mockRepository);

    notifier = OrdersNotifier(
      getOrdersUseCase: getOrdersUseCase,
      getOrderDetailsUseCase: getOrderDetailsUseCase,
      createOrderUseCase: createOrderUseCase,
      cancelOrderUseCase: cancelOrderUseCase,
    );
  });

  group('OrdersNotifier', () {
    group('initialization', () {
      test('should start with initial state', () {
        expect(notifier.state.status, equals(OrdersStatus.initial));
        expect(notifier.state.orders, isEmpty);
        expect(notifier.state.selectedOrder, isNull);
        expect(notifier.state.createdOrder, isNull);
        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('loadOrders', () {
      test('should emit loading then loaded with orders on success', () async {
        // Arrange
        when(
          mockRepository.getOrders(
            status: anyNamed('status'),
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          ),
        ).thenAnswer((_) async => Right(testOrders));

        final states = <OrdersState>[];
        notifier.addListener((state) => states.add(state));

        // Act
        await notifier.loadOrders();

        // Assert - first state is initial (from addListener), then loading, then loaded
        expect(states.length, greaterThanOrEqualTo(2));
        // Find loading state in the list
        expect(states.any((s) => s.status == OrdersStatus.loading), isTrue);
        expect(states.last.status, equals(OrdersStatus.loaded));
        expect(states.last.orders, equals(testOrders));
        expect(states.last.errorMessage, isNull);
      });

      test('should emit loading then error on failure', () async {
        // Arrange
        when(
          mockRepository.getOrders(
            status: anyNamed('status'),
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          ),
        ).thenAnswer(
          (_) async => Left(ServerFailure(message: 'Erreur serveur')),
        );

        final states = <OrdersState>[];
        notifier.addListener((state) => states.add(state));

        // Act
        await notifier.loadOrders();

        // Assert
        expect(states.last.status, equals(OrdersStatus.error));
        expect(states.last.errorMessage, equals('Erreur serveur'));
      });

      test('should filter by status when provided', () async {
        // Arrange
        when(
          mockRepository.getOrders(
            status: 'pending',
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          ),
        ).thenAnswer((_) async => Right(testOrders));

        // Act
        await notifier.loadOrders(status: 'pending');

        // Assert
        verify(
          mockRepository.getOrders(
            status: 'pending',
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          ),
        ).called(1);
      });
    });

    group('loadOrderDetails', () {
      test(
        'should emit loading then loaded with order details on success',
        () async {
          // Arrange
          when(
            mockRepository.getOrderDetails(1),
          ).thenAnswer((_) async => Right(testOrder));

          final states = <OrdersState>[];
          notifier.addListener((state) => states.add(state));

          // Act
          await notifier.loadOrderDetails(1);

          // Assert
          expect(states.last.status, equals(OrdersStatus.loaded));
          expect(states.last.selectedOrder, equals(testOrder));
        },
      );

      test('should emit error on failure', () async {
        // Arrange
        when(mockRepository.getOrderDetails(999)).thenAnswer(
          (_) async => Left(ServerFailure(message: 'Commande introuvable')),
        );

        // Act
        await notifier.loadOrderDetails(999);

        // Assert
        expect(notifier.state.status, equals(OrdersStatus.error));
        expect(notifier.state.errorMessage, equals('Commande introuvable'));
      });
    });

    group('createOrder', () {
      test(
        'should emit loading then loaded with new order on success',
        () async {
          // Arrange
          when(
            mockRepository.createOrder(
              pharmacyId: anyNamed('pharmacyId'),
              items: anyNamed('items'),
              deliveryAddress: anyNamed('deliveryAddress'),
              paymentMode: anyNamed('paymentMode'),
              prescriptionImage: anyNamed('prescriptionImage'),
              customerNotes: anyNamed('customerNotes'),
            ),
          ).thenAnswer((_) async => Right(testOrder));

          final states = <OrdersState>[];
          notifier.addListener((state) => states.add(state));

          // Act
          await notifier.createOrder(
            pharmacyId: 1,
            items: [testOrderItem],
            deliveryAddress: testDeliveryAddress,
            paymentMode: 'on_delivery',
          );

          // Assert
          expect(states.last.status, equals(OrdersStatus.loaded));
          expect(states.last.createdOrder, equals(testOrder));
          expect(states.last.orders.contains(testOrder), isTrue);
        },
      );

      test('should add created order to beginning of orders list', () async {
        // Arrange - first load existing orders
        when(
          mockRepository.getOrders(
            status: anyNamed('status'),
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          ),
        ).thenAnswer((_) async => Right(testOrders));
        await notifier.loadOrders();

        final newOrder = OrderEntity(
          id: 2,
          reference: 'ORD-002',
          status: OrderStatus.pending,
          paymentMode: PaymentMode.platform,
          pharmacyId: 1,
          pharmacyName: 'Pharmacie du Centre',
          paymentStatus: 'pending',
          items: [testOrderItem],
          subtotal: 5000.0,
          deliveryFee: 500.0,
          totalAmount: 5500.0,
          deliveryAddress: testDeliveryAddress,
          createdAt: DateTime.now(),
        );

        when(
          mockRepository.createOrder(
            pharmacyId: anyNamed('pharmacyId'),
            items: anyNamed('items'),
            deliveryAddress: anyNamed('deliveryAddress'),
            paymentMode: anyNamed('paymentMode'),
            prescriptionImage: anyNamed('prescriptionImage'),
            customerNotes: anyNamed('customerNotes'),
          ),
        ).thenAnswer((_) async => Right(newOrder));

        // Act
        await notifier.createOrder(
          pharmacyId: 1,
          items: [testOrderItem],
          deliveryAddress: testDeliveryAddress,
          paymentMode: 'platform',
        );

        // Assert
        expect(notifier.state.orders.first, equals(newOrder));
        expect(notifier.state.orders.length, equals(2));
      });

      test('should emit error on creation failure', () async {
        // Arrange
        when(
          mockRepository.createOrder(
            pharmacyId: anyNamed('pharmacyId'),
            items: anyNamed('items'),
            deliveryAddress: anyNamed('deliveryAddress'),
            paymentMode: anyNamed('paymentMode'),
            prescriptionImage: anyNamed('prescriptionImage'),
            customerNotes: anyNamed('customerNotes'),
          ),
        ).thenAnswer(
          (_) async => Left(ServerFailure(message: 'Stock insuffisant')),
        );

        // Act
        await notifier.createOrder(
          pharmacyId: 1,
          items: [testOrderItem],
          deliveryAddress: testDeliveryAddress,
          paymentMode: 'on_delivery',
        );

        // Assert
        expect(notifier.state.status, equals(OrdersStatus.error));
        expect(notifier.state.errorMessage, equals('Stock insuffisant'));
      });
    });

    group('cancelOrder', () {
      test('should refresh orders list on successful cancellation', () async {
        // Arrange
        when(
          mockRepository.cancelOrder(1, 'Changed my mind'),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockRepository.getOrders(
            status: anyNamed('status'),
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          ),
        ).thenAnswer((_) async => Right([]));

        // Act
        await notifier.cancelOrder(1, 'Changed my mind');

        // Assert
        verify(mockRepository.cancelOrder(1, 'Changed my mind')).called(1);
        verify(
          mockRepository.getOrders(
            status: anyNamed('status'),
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          ),
        ).called(1);
      });

      test('should emit error on cancellation failure', () async {
        // Arrange
        when(mockRepository.cancelOrder(1, 'Test')).thenAnswer(
          (_) async => Left(ServerFailure(message: 'Commande déjà expédiée')),
        );

        // Act
        final errorMessage = await notifier.cancelOrder(1, 'Test');

        // Assert: cancelOrder returns the error message without changing state
        expect(errorMessage, equals('Commande déjà expédiée'));
      });
    });
  });
}
