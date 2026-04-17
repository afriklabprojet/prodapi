import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:drpharma_client/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:drpharma_client/features/orders/data/models/order_model.dart';
import 'package:drpharma_client/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_item_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';

import 'orders_repository_impl_test.mocks.dart';

@GenerateMocks([OrdersRemoteDataSource, OrdersLocalDataSource])
void main() {
  late MockOrdersRemoteDataSource mockRemoteDataSource;
  late MockOrdersLocalDataSource mockLocalDataSource;
  late OrdersRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockOrdersRemoteDataSource();
    mockLocalDataSource = MockOrdersLocalDataSource();
    repository = OrdersRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  // Test data
  const testPharmacy = PharmacyBasicModel(
    id: 1,
    name: 'Pharmacie Test',
    phone: '+24107123456',
    address: 'Libreville, Gabon',
  );

  final testOrderModel = OrderModel(
    id: 1,
    reference: 'ORD-001',
    status: 'pending',
    paymentStatus: 'pending',
    paymentMode: 'on_delivery',
    pharmacyId: 1,
    pharmacy: testPharmacy,
    items: const [],
    subtotal: 3000.0,
    deliveryFee: 500.0,
    totalAmount: 3500.0,
    currency: 'XOF',
    deliveryAddress: 'Test Address',
    deliveryCity: 'Libreville',
    customerPhone: '+24107123456',
    createdAt: '2026-02-01T10:00:00Z',
  );

  const testDeliveryAddress = DeliveryAddressEntity(
    address: '123 Test Street',
    city: 'Libreville',
    phone: '+24107123456',
    latitude: 0.4162,
    longitude: 9.4673,
  );

  const testOrderItems = <OrderItemEntity>[
    OrderItemEntity(
      id: 1,
      productId: 1,
      name: 'Paracétamol',
      quantity: 2,
      unitPrice: 1500.0,
      totalPrice: 3000.0,
    ),
  ];

  group('getOrders', () {
    test('should return list of orders on success', () async {
      // Arrange
      when(mockRemoteDataSource.getOrders(
        status: anyNamed('status'),
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => [testOrderModel]);
      when(mockLocalDataSource.cacheOrders(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.getOrders();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have returned orders'),
        (orders) {
          expect(orders.length, 1);
          expect(orders.first.id, 1);
        },
      );
    });

    test('should cache orders on first page without status filter', () async {
      // Arrange
      when(mockRemoteDataSource.getOrders(
        status: anyNamed('status'),
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => [testOrderModel]);
      when(mockLocalDataSource.cacheOrders(any)).thenAnswer((_) async {});

      // Act
      await repository.getOrders(page: 1, status: null);

      // Assert
      verify(mockLocalDataSource.cacheOrders([testOrderModel])).called(1);
    });

    test('should NOT cache orders when status filter is applied', () async {
      // Arrange
      when(mockRemoteDataSource.getOrders(
        status: anyNamed('status'),
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => [testOrderModel]);

      // Act
      await repository.getOrders(page: 1, status: 'pending');

      // Assert
      verifyNever(mockLocalDataSource.cacheOrders(any));
    });

    test('should return cached data on network error for first page', () async {
      // Arrange
      when(mockRemoteDataSource.getOrders(
        status: anyNamed('status'),
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenThrow(NetworkException(message: 'No connection'));
      when(mockLocalDataSource.getCachedOrders()).thenReturn([testOrderModel]);

      // Act
      final result = await repository.getOrders(page: 1);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have returned cached orders'),
        (orders) => expect(orders.length, 1),
      );
    });

    test('should return NetworkFailure when no cache available', () async {
      // Arrange
      when(mockRemoteDataSource.getOrders(
        status: anyNamed('status'),
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenThrow(NetworkException(message: 'No connection'));
      when(mockLocalDataSource.getCachedOrders()).thenReturn(null);

      // Act
      final result = await repository.getOrders();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should have returned failure'),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(mockRemoteDataSource.getOrders(
        status: anyNamed('status'),
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenThrow(ServerException(message: 'Server error', statusCode: 500));

      // Act
      final result = await repository.getOrders();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 500);
        },
        (_) => fail('Should have returned failure'),
      );
    });

    test('should return UnauthorizedFailure on unauthorized error', () async {
      // Arrange
      when(mockRemoteDataSource.getOrders(
        status: anyNamed('status'),
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenThrow(UnauthorizedException(message: 'Token expired'));

      // Act
      final result = await repository.getOrders();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('Should have returned failure'),
      );
    });
  });

  group('getOrderDetails', () {
    test('should return order details on success', () async {
      // Arrange
      when(mockRemoteDataSource.getOrderDetails(any))
          .thenAnswer((_) async => testOrderModel);
      when(mockLocalDataSource.cacheOrder(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.getOrderDetails(1);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have returned order'),
        (order) => expect(order.id, 1),
      );
    });

    test('should cache order on success', () async {
      // Arrange
      when(mockRemoteDataSource.getOrderDetails(any))
          .thenAnswer((_) async => testOrderModel);
      when(mockLocalDataSource.cacheOrder(any)).thenAnswer((_) async {});

      // Act
      await repository.getOrderDetails(1);

      // Assert
      verify(mockLocalDataSource.cacheOrder(testOrderModel)).called(1);
    });

    test('should return cached order on network error', () async {
      // Arrange
      when(mockRemoteDataSource.getOrderDetails(any))
          .thenThrow(NetworkException(message: 'No connection'));
      when(mockLocalDataSource.getCachedOrder(1)).thenReturn(testOrderModel);

      // Act
      final result = await repository.getOrderDetails(1);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have returned cached order'),
        (order) => expect(order.id, 1),
      );
    });

    test('should return NetworkFailure when no cached order', () async {
      // Arrange
      when(mockRemoteDataSource.getOrderDetails(any))
          .thenThrow(NetworkException(message: 'No connection'));
      when(mockLocalDataSource.getCachedOrder(1)).thenReturn(null);

      // Act
      final result = await repository.getOrderDetails(1);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should have returned failure'),
      );
    });

    test('should return ServerFailure with status code on 404', () async {
      // Arrange
      when(mockRemoteDataSource.getOrderDetails(any))
          .thenThrow(ServerException(message: 'Not found', statusCode: 404));

      // Act
      final result = await repository.getOrderDetails(999);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 404);
        },
        (_) => fail('Should have returned failure'),
      );
    });
  });

  group('createOrder', () {
    test('should return created order on success', () async {
      // Arrange
      when(mockRemoteDataSource.createOrder(
        pharmacyId: anyNamed('pharmacyId'),
        items: anyNamed('items'),
        deliveryAddress: anyNamed('deliveryAddress'),
        paymentMode: anyNamed('paymentMode'),
        prescriptionImage: anyNamed('prescriptionImage'),
        customerNotes: anyNamed('customerNotes'),
        prescriptionId: anyNamed('prescriptionId'),
      )).thenAnswer((_) async => testOrderModel);
      when(mockLocalDataSource.cacheOrder(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.createOrder(
        pharmacyId: 1,
        items: testOrderItems,
        deliveryAddress: testDeliveryAddress,
        paymentMode: 'on_delivery',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have returned order'),
        (order) => expect(order.id, 1),
      );
    });

    test('should cache created order', () async {
      // Arrange
      when(mockRemoteDataSource.createOrder(
        pharmacyId: anyNamed('pharmacyId'),
        items: anyNamed('items'),
        deliveryAddress: anyNamed('deliveryAddress'),
        paymentMode: anyNamed('paymentMode'),
        prescriptionImage: anyNamed('prescriptionImage'),
        customerNotes: anyNamed('customerNotes'),
        prescriptionId: anyNamed('prescriptionId'),
      )).thenAnswer((_) async => testOrderModel);
      when(mockLocalDataSource.cacheOrder(any)).thenAnswer((_) async {});

      // Act
      await repository.createOrder(
        pharmacyId: 1,
        items: testOrderItems,
        deliveryAddress: testDeliveryAddress,
        paymentMode: 'on_delivery',
      );

      // Assert
      verify(mockLocalDataSource.cacheOrder(testOrderModel)).called(1);
    });

    test('should return ValidationFailure on validation error', () async {
      // Arrange
      when(mockRemoteDataSource.createOrder(
        pharmacyId: anyNamed('pharmacyId'),
        items: anyNamed('items'),
        deliveryAddress: anyNamed('deliveryAddress'),
        paymentMode: anyNamed('paymentMode'),
        prescriptionImage: anyNamed('prescriptionImage'),
        customerNotes: anyNamed('customerNotes'),
        prescriptionId: anyNamed('prescriptionId'),
      )).thenThrow(ValidationException(
        errors: {'items': ['Au moins un produit requis']},
      ));

      // Act
      final result = await repository.createOrder(
        pharmacyId: 1,
        items: testOrderItems,
        deliveryAddress: testDeliveryAddress,
        paymentMode: 'on_delivery',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have returned failure'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      when(mockRemoteDataSource.createOrder(
        pharmacyId: anyNamed('pharmacyId'),
        items: anyNamed('items'),
        deliveryAddress: anyNamed('deliveryAddress'),
        paymentMode: anyNamed('paymentMode'),
        prescriptionImage: anyNamed('prescriptionImage'),
        customerNotes: anyNamed('customerNotes'),
        prescriptionId: anyNamed('prescriptionId'),
      )).thenThrow(NetworkException(message: 'No connection'));

      // Act
      final result = await repository.createOrder(
        pharmacyId: 1,
        items: testOrderItems,
        deliveryAddress: testDeliveryAddress,
        paymentMode: 'on_delivery',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should have returned failure'),
      );
    });
  });

  group('cancelOrder', () {
    test('should return success on cancellation', () async {
      // Arrange
      when(mockRemoteDataSource.cancelOrder(any, any))
          .thenAnswer((_) async {});
      when(mockLocalDataSource.clearCache()).thenAnswer((_) async {});

      // Act
      final result = await repository.cancelOrder(1, 'Changed my mind');

      // Assert
      expect(result.isRight(), true);
    });

    test('should clear cache after cancellation', () async {
      // Arrange
      when(mockRemoteDataSource.cancelOrder(any, any))
          .thenAnswer((_) async {});
      when(mockLocalDataSource.clearCache()).thenAnswer((_) async {});

      // Act
      await repository.cancelOrder(1, 'Changed my mind');

      // Assert
      verify(mockLocalDataSource.clearCache()).called(1);
    });

    test('should return ServerFailure when order cannot be cancelled', () async {
      // Arrange
      when(mockRemoteDataSource.cancelOrder(any, any))
          .thenThrow(ServerException(
            message: 'Cannot cancel delivered order',
            statusCode: 422,
          ));

      // Act
      final result = await repository.cancelOrder(1, 'Test reason');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 422);
        },
        (_) => fail('Should have returned failure'),
      );
    });

    test('should return UnauthorizedFailure on auth error', () async {
      // Arrange
      when(mockRemoteDataSource.cancelOrder(any, any))
          .thenThrow(UnauthorizedException(message: 'Token expired'));

      // Act
      final result = await repository.cancelOrder(1, 'Test');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('Should have returned failure'),
      );
    });
  });

  group('initiatePayment', () {
    test('should return payment data on success', () async {
      // Arrange
      final paymentResponse = {
        'payment_url': 'https://payment.example.com/pay',
        'transaction_id': 'TXN-123',
      };
      when(mockRemoteDataSource.initiatePayment(
        orderId: anyNamed('orderId'),
        provider: anyNamed('provider'),
      )).thenAnswer((_) async => paymentResponse);

      // Act
      final result = await repository.initiatePayment(
        orderId: 1,
        provider: 'airtel_money',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have returned payment data'),
        (data) {
          expect(data['payment_url'], isNotNull);
          expect(data['transaction_id'], 'TXN-123');
        },
      );
    });

    test('should return ServerFailure on payment error', () async {
      // Arrange
      when(mockRemoteDataSource.initiatePayment(
        orderId: anyNamed('orderId'),
        provider: anyNamed('provider'),
      )).thenThrow(ServerException(
        message: 'Payment provider unavailable',
        statusCode: 503,
      ));

      // Act
      final result = await repository.initiatePayment(
        orderId: 1,
        provider: 'airtel_money',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 503);
        },
        (_) => fail('Should have returned failure'),
      );
    });
  });

  group('getTrackingInfo', () {
    test('should return tracking info on success', () async {
      // Arrange
      final trackingData = {
        'status': 'in_transit',
        'courier_name': 'Jean Coursier',
        'courier_phone': '+24107000000',
        'estimated_arrival': '15:30',
      };
      when(mockRemoteDataSource.getTrackingInfo(any))
          .thenAnswer((_) async => trackingData);

      // Act
      final result = await repository.getTrackingInfo(1);

      // Assert
      expect(result, isNotNull);
      expect(result!['status'], 'in_transit');
      expect(result['courier_name'], 'Jean Coursier');
    });

    test('should return null on error', () async {
      // Arrange
      when(mockRemoteDataSource.getTrackingInfo(any))
          .thenThrow(ServerException(message: 'Error', statusCode: 500));

      // Act
      final result = await repository.getTrackingInfo(1);

      // Assert
      expect(result, isNull);
    });
  });
}
